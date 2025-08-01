import 'package:flutter/material.dart';
import '../services/emergency_service.dart';
import '../services/supabase_auth_service.dart';
import '../services/notification_service.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  _EmergencyContactsPageState createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  List<EmergencyContact> _allContacts = [];
  List<EmergencyContact> _filteredContacts = [];
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _showReportModal = false;
  String _emergencyType = 'Other';
  final TextEditingController _reportController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyContacts() async {
    setState(() => _isLoading = true);

    try {
      final contacts = await EmergencyService.getAllEmergencyContacts();

      // If no contacts in database, use defaults
      if (contacts.isEmpty) {
        final defaultContacts = EmergencyService.getDefaultEmergencyContacts();
        setState(() {
          _allContacts = defaultContacts;
          _filteredContacts = defaultContacts;
        });
      } else {
        setState(() {
          _allContacts = contacts;
          _filteredContacts = contacts;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading emergency contacts: $e')),
      );

      // Fallback to default contacts
      final defaultContacts = EmergencyService.getDefaultEmergencyContacts();
      setState(() {
        _allContacts = defaultContacts;
        _filteredContacts = defaultContacts;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    final categoryFilter = _selectedCategory;

    setState(() {
      _filteredContacts = _allContacts.where((contact) {
        final matchesSearch = query.isEmpty ||
            contact.name.toLowerCase().contains(query) ||
            contact.description.toLowerCase().contains(query) ||
            contact.number.contains(query);

        final matchesCategory =
            categoryFilter == 'All' || contact.category == categoryFilter;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onCategoryChanged(String? newCategory) {
    setState(() {
      _selectedCategory = newCategory ?? 'All';
    });
    _filterContacts();
  }

  Future<void> _makeEmergencyCall(EmergencyContact contact) async {
    try {
      // Show confirmation dialog for emergency calls
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Emergency Call'),
          content: Text(
            'Are you sure you want to call ${contact.name} (${contact.number})?\n\n'
            'This action will be logged for safety purposes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Call Now'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success =
            await EmergencyService.makeEmergencyCall(contact.number);

        if (success) {
          // Log the emergency call
          final user = SupabaseAuthService.getCurrentUser();
          if (user != null) {
            await EmergencyService.logEmergencyCall(
              contactId: contact.id,
              userId: user.id,
              userRole: user.appMetadata['role'] ?? 'unknown',
            );
          }

          // Send notification to admin
          await NotificationService.sendNotification(
            userId: 'admin',
            title: 'Emergency Call Made',
            body: 'User called ${contact.name} emergency number',
            data: {
              'type': 'emergency_call',
              'contact_id': contact.id,
              'contact_name': contact.name,
              'contact_number': contact.number,
            },
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Emergency call initiated to ${contact.name}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Unable to make call. Please dial ${contact.number} manually.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error making emergency call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitEmergencyReport() async {
    if (_reportController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please describe the emergency situation')),
      );
      return;
    }

    try {
      final user = SupabaseAuthService.getCurrentUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final success = await EmergencyService.submitEmergencyReport(
        userId: user.id,
        userRole: user.appMetadata['role'] ?? 'unknown',
        emergencyType: _emergencyType,
        description: _reportController.text.trim(),
      );

      if (success) {
        // Send notification to admin
        await NotificationService.sendNotification(
          userId: 'admin',
          title: 'Emergency Report Submitted',
          body: 'New $_emergencyType emergency report received',
          data: {
            'type': 'emergency_report',
            'emergency_type': _emergencyType,
            'user_id': user.id,
          },
        );

        setState(() {
          _showReportModal = false;
          _reportController.clear();
          _emergencyType = 'Other';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency report submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to submit report');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.report),
            onPressed: () {
              setState(() => _showReportModal = true);
            },
            tooltip: 'Submit Emergency Report',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildSearchAndFilter(),
                Expanded(
                  child: _buildContactsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _makeEmergencyCall(
          EmergencyContact(
            id: 'emergency_112',
            name: 'General Emergency',
            number: '112',
            category: 'General',
            description: 'Universal access for life-threatening emergencies',
            createdAt: DateTime.now(),
          ),
        ),
        backgroundColor: Colors.red,
        tooltip: 'Quick Call 112',
        child: Icon(Icons.emergency, color: Colors.white),
      ),
      bottomSheet: _showReportModal ? _buildReportModal() : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade50,
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Support',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                Text(
                  'Quick access to Rwanda emergency services',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    final categories = ['All', ...EmergencyService.getEmergencyCategories()];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search emergency contacts...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) _onCategoryChanged(category);
                    },
                    selectedColor: Colors.red.shade100,
                    checkmarkColor: Colors.red,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    if (_filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No emergency contacts found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Try adjusting your search or category filter',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return _buildContactCard(contact);
      },
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
    Color categoryColor = _getCategoryColor(contact.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _makeEmergencyCall(contact),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(contact.category),
                  color: categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          contact.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            contact.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: categoryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.number,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.phone,
                color: Colors.red,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportModal() {
    final emergencyTypes = [
      'Physical Abuse',
      'Sexual Harassment',
      'Workplace Violence',
      'Theft/Crime',
      'Safety Hazard',
      'Discrimination',
      'Threat/Intimidation',
      'Other'
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Submit Emergency Report',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() => _showReportModal = false);
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Emergency Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _emergencyType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            items: emergencyTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _emergencyType = value ?? 'Other');
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Describe the Emergency',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _reportController,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText:
                    'Please provide detailed information about the emergency situation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitEmergencyReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Submit Report',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'General':
        return Colors.red;
      case 'Crime':
        return Colors.orange;
      case 'Violence':
        return Colors.purple;
      case 'Traffic':
        return Colors.blue;
      case 'Support':
        return Colors.green;
      case 'Utility':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'General':
        return Icons.emergency;
      case 'Crime':
        return Icons.security;
      case 'Violence':
        return Icons.warning;
      case 'Traffic':
        return Icons.traffic;
      case 'Support':
        return Icons.support;
      case 'Utility':
        return Icons.build;
      default:
        return Icons.phone;
    }
  }
}
