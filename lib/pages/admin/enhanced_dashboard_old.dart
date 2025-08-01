import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../auth_service.dart';
import '../../services/admin_service.dart';
import '../../services/training_service.dart';
import './manage_users.dart';
import './manage_hiring_requests.dart';
import './manage_house_helpers.dart';
import './manage_payments.dart';
import './manage_chats.dart';
import './training_management.dart';
import './behavior_reports.dart';
import './fix_messages.dart';
import './system_settings.dart';
import './my_profile.dart';
import '../login.dart';

class EnhancedAdminDashboard extends StatefulWidget {
  const EnhancedAdminDashboard({super.key});

  @override
  State<EnhancedAdminDashboard> createState() => _EnhancedAdminDashboardState();
}

class _EnhancedAdminDashboardState extends State<EnhancedAdminDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final analytics = await AdminService.getAdminAnalytics();
      final trainingAnalytics = await TrainingService.getTrainingAnalytics();
      setState(() {
        _analytics = {...analytics, ...trainingAnalytics};
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAnalytics() async {
    await _loadDashboardData();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
            page: const EnhancedAdminDashboard(),
          ),
          const Divider(),
          _buildSectionHeader('User Management'),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'All Users',
            index: 1,
            page: const AdminManageUsers(),
          ),
          _buildDrawerItem(
            icon: Icons.home_work,
            title: 'House Helpers',
            index: 2,
            page: const AdminManageHouseHelpers(),
          ),
          _buildDrawerItem(
            icon: Icons.work,
            title: 'Hiring Requests',
            index: 3,
            page: const AdminManageHiringRequests(),
          ),
          const Divider(),
          _buildSectionHeader('Training & Development'),
          _buildDrawerItem(
            icon: Icons.school,
            title: 'Training Management',
            index: 4,
            page: const TrainingManagementPage(),
          ),
          const Divider(),
          _buildSectionHeader('Oversight & Reports'),
          _buildDrawerItem(
            icon: Icons.report_problem,
            title: 'Behavior Reports',
            index: 5,
            page: const BehaviorReportsPage(),
          ),
          _buildDrawerItem(
            icon: Icons.bug_report,
            title: 'System Issues',
            index: 6,
            page: const FixMessagesPage(),
          ),
          const Divider(),
          _buildSectionHeader('Financial'),
          _buildDrawerItem(
            icon: Icons.payments,
            title: 'Payment Management',
            index: 7,
            page: const AdminManagePayments(),
          ),
          const Divider(),
          _buildSectionHeader('Communication'),
          _buildDrawerItem(
            icon: Icons.chat,
            title: 'Manage Chats',
            index: 8,
            page: const AdminManageChats(),
          ),
          _buildDrawerItem(
            icon: Icons.notifications,
            title: 'Send Notifications',
            index: 9,
            onTap: _showNotificationDialog,
          ),
          const Divider(),
          _buildSectionHeader('System'),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'System Settings',
            index: 10,
            page: const SystemSettingsPage(),
          ),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'My Profile',
            index: 11,
            page: const ProfilePage(),
          ),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            index: 12,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    Widget? page,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: onTap ??
          () {
            _onItemTapped(index);
            if (page != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page),
              );
            }
          },
    );
  }

  Future<void> _showNotificationDialog() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedRole = 'all';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Send Notification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Send to',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Users')),
                  DropdownMenuItem(
                      value: 'house_helper', child: Text('House Helpers')),
                  DropdownMenuItem(
                      value: 'house_holder', child: Text('House Holders')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRole = value ?? 'all';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    messageController.text.isNotEmpty) {
                  final success = await AdminService.sendNotificationToUsers(
                    title: titleController.text,
                    message: messageController.text,
                    userRole: selectedRole == 'all' ? null : selectedRole,
                  );

                  if (mounted) {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Notification sent successfully'
                            : 'Failed to send notification'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showNotificationDialog,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 24),
                    _buildQuickStats(),
                    const SizedBox(height: 24),
                    _buildCharts(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Administrator',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: ${DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.now())}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              'Total Users',
              '${_analytics['totalUsers'] ?? 0}',
              Icons.people,
              Colors.blue,
            ),
            _buildStatCard(
              'Active Requests',
              '${_analytics['activeRequests'] ?? 0}',
              Icons.work,
              Colors.orange,
            ),
            _buildStatCard(
              'Pending Reports',
              '${_analytics['pendingReports'] ?? 0}',
              Icons.report_problem,
              Colors.red,
            ),
            _buildStatCard(
              'Total Payments',
              '${_analytics['totalPayments'] ?? 0}',
              Icons.payments,
              Colors.green,
            ),
            _buildStatCard(
              'Trainings',
              '${_analytics['totalTrainings'] ?? 0}',
              Icons.school,
              Colors.purple,
            ),
            _buildStatCard(
              'System Issues',
              '${_analytics['pendingFixMessages'] ?? 0}',
              Icons.bug_report,
              Colors.amber,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildUserDistributionChart()),
            const SizedBox(width: 16),
            Expanded(child: _buildPaymentTypeChart()),
          ],
        ),
      ],
    );
  }

  Widget _buildUserDistributionChart() {
    final workers = _analytics['workers'] ?? 0;
    final households = _analytics['households'] ?? 0;
    final total = workers + households;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'User Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: total > 0
                  ? PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: workers.toDouble(),
                            title: 'Workers\n$workers',
                            color: Colors.blue,
                            radius: 50,
                          ),
                          PieChartSectionData(
                            value: households.toDouble(),
                            title: 'Households\n$households',
                            color: Colors.green,
                            radius: 50,
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                      ),
                    )
                  : const Center(child: Text('No data available')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTypeChart() {
    final servicePayments = _analytics['servicePayments'] ?? 0;
    final trainingPayments = _analytics['trainingPayments'] ?? 0;
    final total = servicePayments + trainingPayments;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Payment Types',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: total > 0
                  ? PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: servicePayments.toDouble(),
                            title: 'Service\n$servicePayments',
                            color: Colors.orange,
                            radius: 50,
                          ),
                          PieChartSectionData(
                            value: trainingPayments.toDouble(),
                            title: 'Training\n$trainingPayments',
                            color: Colors.purple,
                            radius: 50,
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                      ),
                    )
                  : const Center(child: Text('No data available')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildActionCard(
              'Create Training',
              Icons.add_box,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TrainingManagementPage()),
              ),
            ),
            _buildActionCard(
              'View Reports',
              Icons.report,
              Colors.red,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BehaviorReportsPage()),
              ),
            ),
            _buildActionCard(
              'Manage Users',
              Icons.people_alt,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminManageUsers()),
              ),
            ),
            _buildActionCard(
              'System Settings',
              Icons.settings,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SystemSettingsPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
