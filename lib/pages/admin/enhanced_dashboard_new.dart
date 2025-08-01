import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../auth_service.dart';
import '../../services/admin_service.dart';
import '../../services/training_service.dart';
import '../../middleware/route_guard_new.dart';
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

class EnhancedAdminDashboardNew extends StatefulWidget {
  const EnhancedAdminDashboardNew({super.key});

  @override
  State<EnhancedAdminDashboardNew> createState() =>
      _EnhancedAdminDashboardNewState();
}

class _EnhancedAdminDashboardNewState extends State<EnhancedAdminDashboardNew>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadDashboardData();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _loadDashboardData(showLoading: false);
    });
  }

  Future<void> _loadDashboardData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final analytics = await AdminService.getAdminAnalytics();
      final trainingAnalytics = await TrainingService.getTrainingAnalytics();
      final recentActivities = await _getRecentActivities();

      setState(() {
        _analytics = {
          ...analytics,
          ...trainingAnalytics,
          'activeHelpers': analytics['workers'],
          'openRequests': analytics['activeRequests'],
          'monthlyRevenue': _calculateMonthlyRevenue(analytics),
          'pendingReports': analytics['pendingReports'],
        };
        _recentActivities = recentActivities;
        _isLoading = false;
      });

      if (showLoading) {
        _animationController.forward();
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard data: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _loadDashboardData(),
            ),
          ),
        );
      }
    }
  }

  double _calculateMonthlyRevenue(Map<String, dynamic> analytics) {
    // Simulate monthly revenue calculation
    final servicePayments = analytics['servicePayments'] ?? 0;
    final trainingPayments = analytics['trainingPayments'] ?? 0;
    return (servicePayments * 15000.0) + (trainingPayments * 5000.0);
  }

  Future<List<Map<String, dynamic>>> _getRecentActivities() async {
    // This would typically come from a real API
    return [
      {
        'title': 'New user registration',
        'description': 'House helper registered from Gasabo District',
        'icon': Icons.person_add,
        'color': Colors.green,
        'time': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'title': 'Training session completed',
        'description': 'Safety Training completed by 12 participants',
        'icon': Icons.school,
        'color': Colors.blue,
        'time': DateTime.now().subtract(const Duration(hours: 4)),
      },
      {
        'title': 'Behavior report resolved',
        'description': 'Incident in Nyarugenge resolved successfully',
        'icon': Icons.check_circle,
        'color': Colors.green,
        'time': DateTime.now().subtract(const Duration(hours: 6)),
      },
      {
        'title': 'Payment processed',
        'description': 'Service payment of RWF 18,000 completed',
        'icon': Icons.payment,
        'color': Colors.purple,
        'time': DateTime.now().subtract(const Duration(hours: 8)),
      },
      {
        'title': 'System maintenance',
        'description': 'Database optimization completed',
        'icon': Icons.build,
        'color': Colors.orange,
        'time': DateTime.now().subtract(const Duration(hours: 12)),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AdminRouteGuard(
      child: Scaffold(
        appBar: _buildAppBar(),
        drawer: _buildDrawer(context),
        body: _isLoading
            ? _buildLoadingScreen()
            : FadeTransition(
                opacity: _fadeAnimation,
                child: RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeSection(),
                        const SizedBox(height: 24),
                        _buildSystemHealthIndicator(),
                        const SizedBox(height: 24),
                        _buildQuickActions(context),
                        const SizedBox(height: 24),
                        _buildAnalyticsOverview(),
                        const SizedBox(height: 24),
                        _buildProgressSection(),
                        const SizedBox(height: 24),
                        _buildRecentActivities(),
                        const SizedBox(height: 24),
                        _buildSystemMetrics(),
                      ],
                    ),
                  ),
                ),
              ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('HOUSEHELP Admin Dashboard'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () => _showNotifications(context),
          tooltip: 'Notifications',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadDashboardData,
          tooltip: 'Refresh',
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Export Data'),
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
              ),
            ),
          ],
          onSelected: _handleMenuAction,
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading dashboard data...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, Administrator',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'HOUSEHELP Management System',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Monitor platform activities, manage users, and ensure smooth operations across Rwanda.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.95),
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                DateFormat('EEEE, MMMM d, y').format(now),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildSystemHealthIndicator() {
    final healthScore = _calculateSystemHealth();
    final healthColor = _getHealthColor(healthScore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: healthColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Health',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _getHealthStatusText(healthScore),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: healthColor,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              '${(healthScore * 100).toInt()}%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: healthColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateSystemHealth() {
    final pendingReports = _analytics['pendingReports'] ?? 0;
    final pendingFixMessages = _analytics['pendingFixMessages'] ?? 0;
    final totalIssues = pendingReports + pendingFixMessages;

    if (totalIssues == 0) return 1.0;
    if (totalIssues <= 5) return 0.9;
    if (totalIssues <= 10) return 0.7;
    if (totalIssues <= 20) return 0.5;
    return 0.3;
  }

  Color _getHealthColor(double health) {
    if (health >= 0.8) return Colors.green;
    if (health >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getHealthStatusText(double health) {
    if (health >= 0.8) return 'Excellent';
    if (health >= 0.6) return 'Good';
    if (health >= 0.4) return 'Fair';
    return 'Needs Attention';
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'title': 'User Management',
        'icon': Icons.people,
        'color': Colors.blue,
        'count': _analytics['totalUsers'],
        'route': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminManageUsers()),
            ),
      },
      {
        'title': 'House Helpers',
        'icon': Icons.home_work,
        'color': Colors.green,
        'count': _analytics['workers'],
        'route': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AdminManageHouseHelpers()),
            ),
      },
      {
        'title': 'Hiring Requests',
        'icon': Icons.work,
        'color': Colors.orange,
        'count': _analytics['activeRequests'],
        'route': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AdminManageHiringRequests()),
            ),
      },
      {
        'title': 'Training Sessions',
        'icon': Icons.school,
        'color': Colors.purple,
        'count': _analytics['trainingCount'],
        'route': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const TrainingManagementPage()),
            ),
      },
      {
        'title': 'Behavior Reports',
        'icon': Icons.warning,
        'color': Colors.red,
        'count': _analytics['pendingReports'],
        'route': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const BehaviorReportsPage()),
            ),
      },
      {
        'title': 'Payments',
        'icon': Icons.payment,
        'color': Colors.indigo,
        'count': _analytics['totalPayments'],
        'route': () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AdminManagePayments()),
            ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) =>
              _buildEnhancedQuickActionCard(actions[index]),
        ),
      ],
    );
  }

  Widget _buildEnhancedQuickActionCard(Map<String, dynamic> action) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: action['route'],
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                action['color'].withOpacity(0.1),
                action['color'].withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: action['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  action['icon'],
                  size: 28,
                  color: action['color'],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action['title'],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (action['count'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${action['count']}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: action['color'],
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
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
            _buildAnimatedAnalyticsCard(
              'Total Users',
              _analytics['totalUsers']?.toString() ?? '0',
              Icons.people,
              Colors.blue,
              trend: '+12%',
            ),
            _buildAnimatedAnalyticsCard(
              'Active Helpers',
              _analytics['activeHelpers']?.toString() ?? '0',
              Icons.work,
              Colors.green,
              trend: '+8%',
            ),
            _buildAnimatedAnalyticsCard(
              'Open Requests',
              _analytics['openRequests']?.toString() ?? '0',
              Icons.assignment,
              Colors.orange,
              trend: '-5%',
            ),
            _buildAnimatedAnalyticsCard(
              'Monthly Revenue',
              'RWF ${_formatCurrency(_analytics["monthlyRevenue"] ?? 0)}',
              Icons.attach_money,
              Colors.purple,
              trend: '+23%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? trend,
  }) {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 24, color: color),
                if (trend != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: trend.startsWith('+') ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trend,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
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

  Widget _buildProgressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildProgressItem('User Registrations', 0.8, Colors.blue),
            _buildProgressItem('Helper Verifications', 0.6, Colors.green),
            _buildProgressItem('Training Completions', 0.9, Colors.purple),
            _buildProgressItem('Report Resolutions', 0.7, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text('${(progress * 100).toInt()}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activities',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton(
              onPressed: () => _showAllActivities(),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _recentActivities
                  .take(5)
                  .map((activity) => _buildActivityItem(activity))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final time = activity['time'] as DateTime;
    final timeAgo = _getTimeAgo(time);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity['icon'],
              color: activity['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  activity['description'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          Text(
            timeAgo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildSystemMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Metrics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                      'Response Time', '150ms', Icons.speed, Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                      'Uptime', '99.9%', Icons.cloud_done, Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                      'Active Sessions', '24', Icons.group, Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                      'Data Usage', '1.2GB', Icons.storage, Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
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
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            accountName: const Text(
              'HOUSEHELP Admin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text(
              'System Administrator',
              style: TextStyle(fontSize: 14),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings,
                  size: 48, color: Colors.blue),
            ),
          ),
          _buildDrawerItem(context, 'Dashboard', Icons.dashboard, 0, () {
            Navigator.pop(context);
          }),
          _buildDrawerItem(context, 'Users', Icons.people, 1, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminManageUsers()),
            );
          }),
          _buildDrawerItem(context, 'House Helpers', Icons.home_work, 2, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AdminManageHouseHelpers()),
            );
          }),
          _buildDrawerItem(context, 'Hiring Requests', Icons.work, 3, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AdminManageHiringRequests()),
            );
          }),
          _buildDrawerItem(context, 'Training Management', Icons.school, 4, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const TrainingManagementPage()),
            );
          }),
          _buildDrawerItem(context, 'Behavior Reports', Icons.warning, 5, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const BehaviorReportsPage()),
            );
          }),
          _buildDrawerItem(context, 'System Maintenance', Icons.build, 6, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FixMessagesPage()),
            );
          }),
          _buildDrawerItem(context, 'Payments', Icons.payment, 7, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AdminManagePayments()),
            );
          }),
          _buildDrawerItem(context, 'Chats', Icons.chat, 8, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminManageChats()),
            );
          }),
          const Divider(),
          _buildDrawerItem(context, 'Settings', Icons.settings, 9, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SystemSettingsPage()),
            );
          }),
          _buildDrawerItem(context, 'My Profile', Icons.account_circle, 10, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
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
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
        ),
        selected: isSelected,
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          onTap();
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickAddMenu(),
      label: const Text('Quick Add'),
      icon: const Icon(Icons.add),
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
  }

  void _showQuickAddMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add New User'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to add user
              },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Schedule Training'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to schedule training
              },
            ),
            ListTile(
              leading: const Icon(Icons.announcement),
              title: const Text('Send Announcement'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to send announcement
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text('3 pending behavior reports'),
              subtitle: Text('Require immediate attention'),
            ),
            ListTile(
              leading: Icon(Icons.build, color: Colors.blue),
              title: Text('System maintenance scheduled'),
              subtitle: Text('Tomorrow at 2:00 AM'),
            ),
          ],
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

  void _showAllActivities() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Activities'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _recentActivities.length,
            itemBuilder: (context, index) =>
                _buildActivityItem(_recentActivities[index]),
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SystemSettingsPage()),
        );
        break;
      case 'export':
        _showExportDialog();
        break;
      case 'logout':
        _handleLogout(context);
        break;
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Choose the data you want to export:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export started...')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text(
              'Are you sure you want to logout from the admin panel?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final authService = AuthService();
                  await authService.signout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: ${e.toString()}')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('Logout', style: TextStyle(color: Colors.white)),
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
