import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../models/user_role.dart';
import '../../middleware/route_guard.dart';

class AdminManageUsers extends StatefulWidget {
  const AdminManageUsers({super.key});

  @override
  State<AdminManageUsers> createState() => _AdminManageUsersState();
}

class _AdminManageUsersState extends State<AdminManageUsers> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  UserRole? _selectedRole;
  String? _selectedDistrict;
  String? _selectedStatus;
  DateTime? _registrationDateFrom;
  DateTime? _registrationDateTo;

  final List<String> _rwandanDistricts = [
    'Gasabo',
    'Kicukiro',
    'Nyarugenge',
    'Bugesera',
    'Gatsibo',
    'Kayonza',
    'Kirehe',
    'Ngoma',
    'Nyagatare',
    'Rwamagana',
    'Gicumbi',
    'Musanze',
    'Rulindo',
    'Gakenke',
    'Burera',
    'Huye',
    'Muhanga',
    'Kamonyi',
    'Nyanza',
    'Gisagara',
    'Nyamagabe',
    'Nyaruguru',
    'Ruhango',
    'Karongi',
    'Rutsiro',
    'Rubavu',
    'Nyabihu',
    'Ngororero',
    'Rusizi',
    'Nyamasheke'
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);

      final data = await SupabaseService.read(
        table: 'profiles',
        orderBy: 'created_at',
        ascending: false,
      );

      setState(() {
        _users = data;
        _filteredUsers = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to load users. Please try again later.')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = _searchQuery.isEmpty ||
            user['full_name']
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true ||
            user['email']?.toLowerCase().contains(_searchQuery.toLowerCase()) ==
                true;

        final matchesRole = _selectedRole == null ||
            user['role'] == _selectedRole.toString().split('.').last;

        final matchesDistrict =
            _selectedDistrict == null || user['district'] == _selectedDistrict;

        final matchesStatus = _selectedStatus == null ||
            _getStatusFromUser(user) == _selectedStatus;

        final registrationDate = user['created_at'] != null
            ? DateTime.parse(user['created_at'])
            : null;

        final matchesDateFrom = _registrationDateFrom == null ||
            (registrationDate != null &&
                registrationDate.isAfter(_registrationDateFrom!));

        final matchesDateTo = _registrationDateTo == null ||
            (registrationDate != null &&
                registrationDate.isBefore(
                    _registrationDateTo!.add(const Duration(days: 1))));

        return matchesSearch &&
            matchesRole &&
            matchesDistrict &&
            matchesStatus &&
            matchesDateFrom &&
            matchesDateTo;
      }).toList();
    });
  }

  String _getStatusFromUser(Map<String, dynamic> user) {
    if (user['is_suspended'] == true) return 'Suspended';
    if (user['is_verified'] == true) return 'Verified';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    return AdminRouteGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUsers,
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildSearchAndFilters(),
                  _buildUserStatistics(),
                  Expanded(child: _buildUsersList()),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _applyFilters();
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_selectedRole != null)
                FilterChip(
                  label:
                      Text('Role: ${_selectedRole.toString().split('.').last}'),
                  onSelected: (value) {
                    setState(() => _selectedRole = null);
                    _applyFilters();
                  },
                  onDeleted: () {
                    setState(() => _selectedRole = null);
                    _applyFilters();
                  },
                ),
              if (_selectedDistrict != null)
                FilterChip(
                  label: Text('District: $_selectedDistrict'),
                  onSelected: (value) {
                    setState(() => _selectedDistrict = null);
                    _applyFilters();
                  },
                  onDeleted: () {
                    setState(() => _selectedDistrict = null);
                    _applyFilters();
                  },
                ),
              if (_selectedStatus != null)
                FilterChip(
                  label: Text('Status: $_selectedStatus'),
                  onSelected: (value) {
                    setState(() => _selectedStatus = null);
                    _applyFilters();
                  },
                  onDeleted: () {
                    setState(() => _selectedStatus = null);
                    _applyFilters();
                  },
                ),
              if (_registrationDateFrom != null || _registrationDateTo != null)
                FilterChip(
                  label: const Text('Date Range'),
                  onSelected: (value) {
                    setState(() {
                      _registrationDateFrom = null;
                      _registrationDateTo = null;
                    });
                    _applyFilters();
                  },
                  onDeleted: () {
                    setState(() {
                      _registrationDateFrom = null;
                      _registrationDateTo = null;
                    });
                    _applyFilters();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatistics() {
    final totalUsers = _filteredUsers.length;
    final verifiedUsers =
        _filteredUsers.where((u) => u['is_verified'] == true).length;
    final suspendedUsers =
        _filteredUsers.where((u) => u['is_suspended'] == true).length;
    final helpers =
        _filteredUsers.where((u) => u['role'] == 'house_helper').length;
    final holders =
        _filteredUsers.where((u) => u['role'] == 'house_holder').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Total', totalUsers, Colors.blue),
          _buildStatCard('Verified', verifiedUsers, Colors.green),
          _buildStatCard('Suspended', suspendedUsers, Colors.red),
          _buildStatCard('Helpers', helpers, Colors.orange),
          _buildStatCard('Holders', holders, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildUsersList() {
    if (_filteredUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No users found',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isVerified = user['is_verified'] == true;
    final isSuspended = user['is_suspended'] == true;
    final role = user['role'] ?? 'unknown';
    final createdAt =
        user['created_at'] != null ? DateTime.parse(user['created_at']) : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(role),
          child: Icon(
            _getRoleIcon(role),
            color: Colors.white,
          ),
        ),
        title: Text(
          user['full_name'] ?? 'No Name',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? ''),
            Text(
                '${role.replaceAll('_', ' ').toUpperCase()} • ${user['district'] ?? 'Unknown District'}'),
            if (createdAt != null)
              Text('Joined: ${DateFormat('MMM dd, yyyy').format(createdAt)}'),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusChip(isVerified, isSuspended),
            const SizedBox(height: 4),
            PopupMenuButton<String>(
              onSelected: (action) => _handleUserAction(action, user),
              itemBuilder: (context) => [
                if (!isVerified)
                  const PopupMenuItem(
                    value: 'verify',
                    child: Text('Verify User'),
                  ),
                PopupMenuItem(
                  value: isSuspended ? 'unsuspend' : 'suspend',
                  child: Text(isSuspended ? 'Unsuspend' : 'Suspend'),
                ),
                const PopupMenuItem(
                  value: 'view',
                  child: Text('View Profile'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete User'),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildStatusChip(bool isVerified, bool isSuspended) {
    if (isSuspended) {
      return Chip(
        label: const Text('Suspended', style: TextStyle(fontSize: 10)),
        backgroundColor: Colors.red[100],
        labelStyle: const TextStyle(color: Colors.red),
      );
    } else if (isVerified) {
      return Chip(
        label: const Text('Verified', style: TextStyle(fontSize: 10)),
        backgroundColor: Colors.green[100],
        labelStyle: const TextStyle(color: Colors.green),
      );
    } else {
      return Chip(
        label: const Text('Pending', style: TextStyle(fontSize: 10)),
        backgroundColor: Colors.orange[100],
        labelStyle: const TextStyle(color: Colors.orange),
      );
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'house_helper':
        return Colors.blue;
      case 'house_holder':
        return Colors.green;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'house_helper':
        return Icons.work;
      case 'house_holder':
        return Icons.home;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Users'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<UserRole?>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Roles')),
                    ...UserRole.values.map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role
                              .toString()
                              .split('.')
                              .last
                              .replaceAll('_', ' ')
                              .toUpperCase()),
                        )),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => _selectedRole = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: _selectedDistrict,
                  decoration: const InputDecoration(labelText: 'District'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Districts')),
                    ..._rwandanDistricts.map((district) => DropdownMenuItem(
                          value: district,
                          child: Text(district),
                        )),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => _selectedDistrict = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Statuses')),
                    DropdownMenuItem(
                        value: 'Verified', child: Text('Verified')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(
                        value: 'Suspended', child: Text('Suspended')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => _selectedStatus = value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'From Date'),
                        readOnly: true,
                        controller: TextEditingController(
                          text: _registrationDateFrom != null
                              ? DateFormat('MMM dd, yyyy')
                                  .format(_registrationDateFrom!)
                              : '',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                _registrationDateFrom ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() => _registrationDateFrom = date);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'To Date'),
                        readOnly: true,
                        controller: TextEditingController(
                          text: _registrationDateTo != null
                              ? DateFormat('MMM dd, yyyy')
                                  .format(_registrationDateTo!)
                              : '',
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _registrationDateTo ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() => _registrationDateTo = date);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedRole = null;
                  _selectedDistrict = null;
                  _selectedStatus = null;
                  _registrationDateFrom = null;
                  _registrationDateTo = null;
                });
                _applyFilters();
                Navigator.pop(context);
              },
              child: const Text('Clear All'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _applyFilters();
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUserAction(String action, Map<String, dynamic> user) async {
    switch (action) {
      case 'verify':
        await _verifyUser(user['id']);
        break;
      case 'suspend':
        await _suspendUser(user['id'], true);
        break;
      case 'unsuspend':
        await _suspendUser(user['id'], false);
        break;
      case 'view':
        _viewUserProfile(user);
        break;
      case 'delete':
        _confirmDeleteUser(user);
        break;
    }
  }

  Future<void> _verifyUser(String userId) async {
    try {
      await SupabaseService.update(
        table: 'profiles',
        id: userId,
        data: {'is_verified': true},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User verified successfully')),
      );

      _loadUsers();
    } catch (e) {
      debugPrint('Error verifying user: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to verify user. Please try again later.')),
      );
    }
  }

  Future<void> _suspendUser(String userId, bool suspend) async {
    try {
      await SupabaseService.update(
        table: 'profiles',
        id: userId,
        data: {'is_suspended': suspend},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'User ${suspend ? 'suspended' : 'unsuspended'} successfully')),
      );

      _loadUsers();
    } catch (e) {
      debugPrint('Error updating user: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Failed to update user status. Please try again later.')),
      );
    }
  }

  void _viewUserProfile(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['full_name'] ?? 'User Profile'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProfileField('Email', user['email']),
              _buildProfileField('Phone', user['phone_number']),
              _buildProfileField('District', user['district']),
              _buildProfileField(
                  'Role', user['role']?.replaceAll('_', ' ').toUpperCase()),
              _buildProfileField(
                  'Verified', user['is_verified'] == true ? 'Yes' : 'No'),
              _buildProfileField(
                  'Suspended', user['is_suspended'] == true ? 'Yes' : 'No'),
              if (user['created_at'] != null)
                _buildProfileField(
                    'Joined',
                    DateFormat('MMM dd, yyyy')
                        .format(DateTime.parse(user['created_at']))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  void _confirmDeleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete ${user['full_name']}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUser(user['id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await SupabaseService.delete(table: 'profiles', id: userId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );

      _loadUsers();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to delete user. Please try again later.')),
      );
    }
  }
}
