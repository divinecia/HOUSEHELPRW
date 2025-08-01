import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/house_helper_service.dart';
import '../../models/house_helper_profile.dart';
import '../auth_service.dart';
import '../../models/user_role.dart';
import './manage_users.dart';
import './manage_hiring_requests.dart';
import './my_profile.dart';
import '../login.dart';
import './dashboard.dart';

class AdminManageHouseHelpers extends StatefulWidget {
  const AdminManageHouseHelpers({super.key});

  @override
  State<AdminManageHouseHelpers> createState() =>
      _AdminManageHouseHelpersState();
}

class _AdminManageHouseHelpersState extends State<AdminManageHouseHelpers> {
  final HouseHelperService _houseHelperService = HouseHelperService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final int _selectedIndex = 1; // House Helpers is selected
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCity = 'All Cities';
  List<String> _cityOptions = ['All Cities'];
  final List<String> _selectedServices = [];
  final List<String> _serviceOptions = [
    'cleaning',
    'cooking',
    'childcare',
    'gardening',
    'laundry',
    'eldercare',
  ];

  @override
  void initState() {
    super.initState();
    _verifyAdminRole();
    _loadCities();
  }

  Future<void> _verifyAdminRole() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final role = await authService.getCurrentUserRole();

    if (role != UserRole.admin) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  Future<void> _loadCities() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('house_helpers')
          .where('isProfileComplete', isEqualTo: true)
          .get();

      // Get non-null cities and convert to Set to remove duplicates
      final cities = snapshot.docs
          .map(
            (doc) => doc.data()['city'] as String?,
          ) // Get city as nullable String
          .where((city) => city != null) // Filter out null values
          .map((city) => city!) // Cast to non-nullable String
          .toSet() // Remove duplicates
          .toList();

      setState(() {
        _cityOptions = ['All Cities', ...cities];
      });
    } catch (e) {
      debugPrint('Error loading cities: $e');
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            accountName: const Text(
              'Admin Panel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text(
              'Administrator',
              style: TextStyle(fontSize: 14),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings, size: 48),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            index: 0,
            destination: const AdminDashboard(),
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Users',
            index: 1,
            destination: const AdminManageUsers(),
          ),
          _buildDrawerItem(
            icon: Icons.people_outline,
            title: 'House Helpers',
            index: 2,
            destination: const AdminManageHouseHelpers(),
          ),
          _buildDrawerItem(
            icon: Icons.work,
            title: 'Jobs',
            index: 3,
            destination: const AdminManageHiringRequests(),
          ),

          // _buildDrawerItem(
          //   icon: Icons.payments,
          //   title: 'Payments',
          //   index: 4,
          //   destination: const AdminManagePayments(),
          // ),
          // _buildDrawerItem(
          //   icon: Icons.chat,
          //   title: 'Chats',
          //   index: 5,
          //   destination: const AdminManageChats(),
          // ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Profile',
            index: 6,
            destination: const ProfilePage(),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              await authService.signout();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    required Widget destination,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by name, city...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedCity,
            items: _cityOptions.map((String city) {
              return DropdownMenuItem<String>(value: city, child: Text(city));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCity = newValue!;
              });
            },
            decoration: InputDecoration(
              labelText: 'Filter by city',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _serviceOptions.map((service) {
              return FilterChip(
                label: Text(service),
                selected: _selectedServices.contains(service),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _selectedServices.add(service);
                    } else {
                      _selectedServices.remove(service);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseHelperList() {
    return FutureBuilder<List<HouseHelperProfile>>(
      future: _houseHelperService.getAllProfiles(
        city: _selectedCity == 'All Cities' ? null : _selectedCity,
        services: _selectedServices.isEmpty ? null : _selectedServices,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No house helpers found'));
        }

        // Apply search filter
        final helpers = snapshot.data!.where((helper) {
          if (_searchQuery.isEmpty) return true;
          return helper.fullName.toLowerCase().contains(_searchQuery) ||
              helper.city.toLowerCase().contains(_searchQuery) ||
              helper.district.toLowerCase().contains(_searchQuery);
        }).toList();

        return ListView.builder(
          // Remove shrinkWrap and NeverScrollableScrollPhysics to enable scrolling
          itemCount: helpers.length,
          itemBuilder: (context, index) {
            final helper = helpers[index];
            return _buildHouseHelperCard(helper);
          },
        );
      },
    );
  }

  Widget _buildHouseHelperCard(HouseHelperProfile helper) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showHelperDetails(helper),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          helper.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${helper.city}, ${helper.district}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteHelper(helper),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: helper.services
                    .map(
                      (service) => Chip(
                        label: Text(service),
                        backgroundColor: Colors.blue[50],
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RWF ${helper.hourlyRate.toStringAsFixed(2)}/hr',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${helper.experienceYears} yrs exp',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelperDetails(HouseHelperProfile helper) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  helper.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${helper.city}, ${helper.district}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
              const Divider(height: 32),
              _buildDetailRow(Icons.phone, helper.phoneNumber),
              _buildDetailRow(
                Icons.cake,
                DateFormat('MMMM d, y')
                    .format(helper.dateOfBirth ?? DateTime.now()),
              ),
              _buildDetailRow(Icons.location_on, helper.address),
              _buildDetailRow(Icons.work, helper.availability),
              _buildDetailRow(
                Icons.money,
                'RWF ${helper.hourlyRate.toStringAsFixed(2)} per hour',
              ),
              _buildDetailRow(
                Icons.star,
                '${helper.experienceYears} years experience',
              ),
              const SizedBox(height: 16),
              const Text(
                'Services Offered',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: helper.services
                    .map(
                      (service) => Chip(
                        label: Text(service),
                        backgroundColor: Colors.blue[50],
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Languages',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: helper.languages
                    .map(
                      (language) => Chip(
                        label: Text(language),
                        backgroundColor: Colors.green[50],
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'About',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(helper.description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _confirmDeleteHelper(helper),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors
                          .white, // Fixed: use foregroundColor for text color
                    ),
                    child: const Text('Delete Profile'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 80, 157, 219),
                      foregroundColor: Colors
                          .white, // Fixed: use foregroundColor for text color
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteHelper(HouseHelperProfile helper) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete ${helper.fullName}\'s profile? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await _houseHelperService.deleteProfile(helper.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${helper.fullName}\'s profile deleted successfully',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete profile: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Manage House Helpers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadCities();
              });
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                _buildFilters(),
                const SizedBox(height: 8),
                Expanded(child: _buildHouseHelperList()),
              ],
            ),
    );
  }
}
