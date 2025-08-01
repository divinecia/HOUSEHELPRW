import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../auth_service.dart';
import '../../services/admin_service.dart';
import '../../services/training_service.dart';
import '../../middleware/route_guard.dart';
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
  final int _selectedIndex = 0;
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
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminRouteGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _handleLogout(context),
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(),
                      const SizedBox(height: 24),
                      _buildQuickActions(context),
                      const SizedBox(height: 24),
                      _buildAnalyticsOverview(),
                      const SizedBox(height: 24),
                      _buildRecentActivities(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, Administrator',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'HOUSEHELP Admin Panel',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Manage users, monitor activities, and oversee the platform operations.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildQuickActionCard(
              'User Management',
              Icons.people,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminManageUsers(),
                ),
              ),
            ),
            _buildQuickActionCard(
              'Training Management',
              Icons.school,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrainingManagementPage(),
                ),
              ),
            ),
            _buildQuickActionCard(
              'Behavior Reports',
              Icons.warning,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BehaviorReportsPage(),
                ),
              ),
            ),
            _buildQuickActionCard(
              'System Maintenance',
              Icons.build,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FixMessagesPage(),
                ),
              ),
            ),
            _buildQuickActionCard(
              'Payment Management',
              Icons.payment,
              Colors.indigo,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminManagePayments(),
                ),
              ),
            ),
            _buildQuickActionCard(
              'Settings',
              Icons.settings,
              Colors.grey,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SystemSettingsPage(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Overview',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildAnalyticsCard(
              'Total Users',
              _analytics['totalUsers']?.toString() ?? '0',
              Icons.people,
              Colors.blue,
            ),
            _buildAnalyticsCard(
              'Active Helpers',
              _analytics['activeHelpers']?.toString() ?? '0',
              Icons.work,
              Colors.green,
            ),
            _buildAnalyticsCard(
              'Open Requests',
              _analytics['openRequests']?.toString() ?? '0',
              Icons.assignment,
              Colors.orange,
            ),
            _buildAnalyticsCard(
              'Monthly Revenue',
              'RWF ${_formatCurrency(_analytics["monthlyRevenue"] ?? 0)}',
              Icons.attach_money,
              Colors.purple,
            ),
            _buildAnalyticsCard(
              'Training Sessions',
              _analytics['trainingCount']?.toString() ?? '0',
              Icons.school,
              Colors.indigo,
            ),
            _buildAnalyticsCard(
              'Pending Reports',
              _analytics['pendingReports']?.toString() ?? '0',
              Icons.report_problem,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activities',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildActivityItem(
                  'New user registration',
                  'John Doe registered as a house helper',
                  Icons.person_add,
                  Colors.green,
                  '2 hours ago',
                ),
                const Divider(),
                _buildActivityItem(
                  'Training completed',
                  'Safety Training Session completed by 15 participants',
                  Icons.school,
                  Colors.blue,
                  '4 hours ago',
                ),
                const Divider(),
                _buildActivityItem(
                  'Behavior report submitted',
                  'New incident reported by household in Kigali',
                  Icons.warning,
                  Colors.orange,
                  '6 hours ago',
                ),
                const Divider(),
                _buildActivityItem(
                  'Payment processed',
                  'Service payment of RWF 15,000 completed',
                  Icons.payment,
                  Colors.purple,
                  '8 hours ago',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String description,
    IconData icon,
    Color color,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
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
          _buildDrawerItem(context, 'Dashboard', Icons.dashboard, 0, () {
            Navigator.pop(context);
          }),
          _buildDrawerItem(context, 'Users', Icons.people, 1, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminManageUsers(),
              ),
            );
          }),
          _buildDrawerItem(context, 'House Helpers', Icons.home_work, 2, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminManageHouseHelpers(),
              ),
            );
          }),
          _buildDrawerItem(context, 'Hiring Requests', Icons.work, 3, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminManageHiringRequests(),
              ),
            );
          }),
          _buildDrawerItem(context, 'Training Management', Icons.school, 4, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TrainingManagementPage(),
              ),
            );
          }),
          _buildDrawerItem(context, 'Behavior Reports', Icons.warning, 5, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BehaviorReportsPage(),
              ),
            );
          }),
          _buildDrawerItem(context, 'System Maintenance', Icons.build, 6, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FixMessagesPage(),
              ),
            );
          }),
          _buildDrawerItem(context, 'Payments', Icons.payment, 7, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminManagePayments(),
              ),
            );
          }),
          _buildDrawerItem(context, 'Chats', Icons.chat, 8, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminManageChats(),
              ),
            );
          }),
          const Divider(),
          _buildDrawerItem(context, 'Settings', Icons.settings, 9, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SystemSettingsPage(),
              ),
            );
          }),
          _buildDrawerItem(context, 'My Profile', Icons.account_circle, 10, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfilePage(),
              ),
            );
          }),
          const Divider(),
          _buildDrawerItem(context, 'Logout', Icons.logout, 11, () {
            _handleLogout(context);
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    int index,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: onTap,
    );
  }

  void _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final authService = AuthService();
                await authService.signout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    final formatter = NumberFormat('#,###');
    return formatter.format(amount);
  }
}
