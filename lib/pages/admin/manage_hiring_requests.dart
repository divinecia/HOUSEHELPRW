import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../auth_service.dart';
import '../../models/user_role.dart';
import '../../models/hire_request.dart';
import '../../services/hire_request_services.dart';
import './manage_users.dart';
import './manage_house_helpers.dart';
import './my_profile.dart';
import '../login.dart';
import './dashboard.dart';

class AdminManageHiringRequests extends StatefulWidget {
  const AdminManageHiringRequests({super.key});

  @override
  State<AdminManageHiringRequests> createState() =>
      _AdminManageHiringRequestsState();
}

class _AdminManageHiringRequestsState extends State<AdminManageHiringRequests> {
  final HireRequestService _hireRequestService = HireRequestService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 2; // Jobs is selected
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  final List<String> _statusOptions = [
    'All',
    'Pending',
    'On-going',
    'Finished',
    'Canceled',
  ];

  @override
  void initState() {
    super.initState();
    _verifyAdminRole();
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
            index: 1,
            destination: const AdminManageHouseHelpers(),
          ),
          _buildDrawerItem(
            icon: Icons.work,
            title: 'Jobs',
            index: 2,
            destination: const AdminManageHiringRequests(),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Profile',
            index: 5,
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
          hintText: 'Search by helper name, employer...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedStatus,
        items: _statusOptions.map((String status) {
          return DropdownMenuItem<String>(value: status, child: Text(status));
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedStatus = newValue!;
          });
        },
        decoration: InputDecoration(
          labelText: 'Filter by status',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildHireRequestList() {
    return FutureBuilder<List<HireRequest>>(
      future: _hireRequestService.getAllRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hiring requests found'));
        }

        // Filter and map the data
        final requests = snapshot.data!.where((request) {
          // Apply search filter
          if (_searchQuery.isNotEmpty) {
            final matchesSearch =
                request.helperName.toLowerCase().contains(_searchQuery) ||
                    request.employerUid.toLowerCase().contains(_searchQuery);
            if (!matchesSearch) return false;
          }

          // Apply status filter
          if (_selectedStatus != 'All') {
            return request.statusDisplayText == _selectedStatus;
          }
          return true;
        }).toList();

        return ListView.builder(
          // Remove shrinkWrap and NeverScrollableScrollPhysics to enable scrolling
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildHireRequestCard(request);
          },
        );
      },
    );
  }

  Widget _buildHireRequestCard(HireRequest request) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Job #${request.id.substring(0, 6)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  label: Text(request.statusDisplayText),
                  backgroundColor: _getStatusColor(
                    request.status,
                  ).withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: _getStatusColor(request.status)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Helper: ${request.helperName}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Employer ID: ${request.employerUid}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${DateFormat('MMM d').format(request.startDate)} - ${request.endDate != null ? DateFormat('MMM d, y').format(request.endDate!) : 'Ongoing'}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'RWF ${request.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (request.notes != null && request.notes!.isNotEmpty)
              Text(
                'Notes: ${request.notes}',
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (request.status != HireStatus.finished &&
                    request.status != HireStatus.canceled)
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () =>
                        _updateRequestStatus(request, HireStatus.finished),
                    tooltip: 'Mark as finished',
                  ),
                if (request.status != HireStatus.canceled)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () =>
                        _updateRequestStatus(request, HireStatus.canceled),
                    tooltip: 'Cancel request',
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => _deleteRequest(request.id),
                  tooltip: 'Delete request',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(HireStatus status) {
    switch (status) {
      case HireStatus.pending:
        return Colors.orange;
      case HireStatus.accepted:
        return Colors.lightBlue;
      case HireStatus.ongoing:
        return Colors.blue;
      case HireStatus.completed:
      case HireStatus.finished:
        return Colors.green;
      case HireStatus.cancelled:
      case HireStatus.canceled:
        return Colors.red;
      case HireStatus.rejected:
        return Colors.redAccent;
    }
  }

  Future<void> _updateRequestStatus(
    HireRequest request,
    HireStatus newStatus,
  ) async {
    try {
      setState(() => _isLoading = true);
      await _hireRequestService.updateHireRequestStatus(request.id, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request status updated to ${newStatus.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this hiring request?',
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
        await _hireRequestService.deleteHireRequest(requestId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete request: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Manage Hiring Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                _buildStatusFilter(),
                const SizedBox(height: 8),
                Expanded(child: _buildHireRequestList()),
              ],
            ),
    );
  }
}
