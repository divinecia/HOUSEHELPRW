import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth_service.dart';
import '../../models/user_role.dart';
import './manage_users.dart';
import './manage_hiring_requests.dart';
import './manage_payments.dart';
import './manage_house_helpers.dart';
import './my_profile.dart';
import '../login.dart';
import './dashboard.dart';

class AdminManageChats extends StatefulWidget {
  const AdminManageChats({super.key});

  @override
  State<AdminManageChats> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminManageChats> {
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
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _selectedIndex == 0,
            onTap: () {
              _onItemTapped(2);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Users'),
            selected: _selectedIndex == 1,
            onTap: () {
              _onItemTapped(2);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminManageUsers(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('House Helpers'),
            selected: _selectedIndex == 1,
            onTap: () {
              _onItemTapped(2);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminManageHouseHelpers(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Jobs'),
            selected: _selectedIndex == 2,
            onTap: () {
              _onItemTapped(2);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminManageHiringRequests(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.payments),
            title: const Text('Payments'),
            selected: _selectedIndex == 3,
            onTap: () {
              _onItemTapped(2);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminManagePayments(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Chats'),
            selected: _selectedIndex == 4,
            onTap: () {
              _onItemTapped(2);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminManageChats(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Profile'),
            onTap: () {
              _onItemTapped(2);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
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
                Navigator.push(
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

  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;

  // Analytics data
  int _totalUsers = 0;
  int _totalHelpers = 0;
  int _totalEmployers = 0;
  int _totalJobs = 0;
  double _totalRevenue = 0;
  List<ChartData> _userGrowthData = [];
  List<ChartData> _jobTrendsData = [];
  List<ChartData> _revenueData = [];
  List<RecentUser> _recentUsers = [];
  List<RecentJob> _recentJobs = [];

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
      return;
    }

    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get all analytics data in parallel
      await Future.wait([
        _getTotalUsers(),
        _getTotalHelpers(),
        _getTotalEmployers(),
        _getTotalJobs(),
        _getTotalRevenue(),
        _getUserGrowthData(),
        _getJobTrendsData(),
        _getRevenueData(),
        _getRecentUsers(),
        _getRecentJobs(),
      ], eagerError: true);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load analytics: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );

      debugPrint('Admin dashboard error: $e');
    }
  }

  Future<void> _getTotalUsers() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('users').count().get();
    setState(() {
      _totalUsers = snapshot.count!;
    });
  }

  Future<void> _getTotalHelpers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'house_helper')
        .count()
        .get();
    setState(() {
      _totalHelpers = snapshot.count!;
    });
  }

  Future<void> _getTotalEmployers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'house_holder')
        .count()
        .get();
    setState(() {
      _totalEmployers = snapshot.count!;
    });
  }

  Future<void> _getTotalJobs() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('hire_requests')
        .count()
        .get();
    setState(() {
      _totalJobs = snapshot.count!;
    });
  }

  Future<void> _getTotalRevenue() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('payments').get();
    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['amount'] ?? 0).toDouble();
    }
    setState(() {
      _totalRevenue = total;
    });
  }

  Future<void> _getUserGrowthData() async {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('createdAt', isGreaterThanOrEqualTo: sixMonthsAgo)
        .get();

    // Group by month
    final Map<String, int> monthlyCounts = {};
    for (var doc in snapshot.docs) {
      final date = (doc.data()['createdAt'] as Timestamp).toDate();
      final monthYear = DateFormat('MMM yyyy').format(date);
      monthlyCounts[monthYear] = (monthlyCounts[monthYear] ?? 0) + 1;
    }

    // Convert to chart data
    final List<ChartData> data = [];
    monthlyCounts.forEach((key, value) {
      data.add(ChartData(key, value.toDouble()));
    });

    setState(() {
      _userGrowthData = data;
    });
  }

  Future<void> _getJobTrendsData() async {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

    final snapshot = await FirebaseFirestore.instance
        .collection('hire_requests')
        .where('createdAt', isGreaterThanOrEqualTo: threeMonthsAgo)
        .get();

    // Group by month
    final Map<String, int> monthlyCounts = {};
    for (var doc in snapshot.docs) {
      final date = (doc.data()['createdAt'] as Timestamp).toDate();
      final monthYear = DateFormat('MMM yyyy').format(date);
      monthlyCounts[monthYear] = (monthlyCounts[monthYear] ?? 0) + 1;
    }

    // Convert to chart data
    final List<ChartData> data = [];
    monthlyCounts.forEach((key, value) {
      data.add(ChartData(key, value.toDouble()));
    });

    setState(() {
      _jobTrendsData = data;
    });
  }

  Future<void> _getRevenueData() async {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

    final snapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('paymentDate', isGreaterThanOrEqualTo: threeMonthsAgo)
        .get();

    // Group by month
    final Map<String, double> monthlyRevenue = {};
    for (var doc in snapshot.docs) {
      final date = (doc.data()['paymentDate'] as Timestamp).toDate();
      final monthYear = DateFormat('MMM yyyy').format(date);
      final amount = (doc.data()['amount'] ?? 0).toDouble();
      monthlyRevenue[monthYear] = (monthlyRevenue[monthYear] ?? 0) + amount;
    }

    // Convert to chart data
    final List<ChartData> data = [];
    monthlyRevenue.forEach((key, value) {
      data.add(ChartData(key, value));
    });

    setState(() {
      _revenueData = data;
    });
  }

  Future<void> _getRecentUsers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    final List<RecentUser> users = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      users.add(
        RecentUser(
          id: doc.id,
          name: data['fullName'] ?? '',
          email: data['email'] ?? 'No Email',
          role: data['role'] ?? 'user',
          date: (data['createdAt'] as Timestamp).toDate(),
        ),
      );
    }

    setState(() {
      _recentUsers = users;
    });
  }

  Future<void> _getRecentJobs() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('hire_requests')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    final List<RecentJob> jobs = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      jobs.add(
        RecentJob(
          id: doc.id,
          employer: data['employerName'] ?? '',
          helper: data['helperName'] ?? 'No Name',
          amount: (data['totalAmount'] ?? 0).toDouble(),
          status: data['status'] ?? 'pending',
          date: (data['createdAt'] as Timestamp).toDate(),
        ),
      );
    }

    setState(() {
      _recentJobs = jobs;
    });
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're on mobile or larger screen
        final isMobile = constraints.maxWidth < 600;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(isMobile),
              const SizedBox(height: 20),
              _buildStatsGrid(isMobile),
              const SizedBox(height: 20),
              _buildChartsSection(isMobile),
              const SizedBox(height: 20),
              _buildRecentActivitySection(isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(bool isMobile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Admin!',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Here\'s what\'s happening with your platform today',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: _loadAnalyticsData,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 10 : 12,
                      horizontal: isMobile ? 12 : 16,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh, size: 20),
                      const SizedBox(width: 8),
                      const Text('Refresh Data'),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    // Navigate to full analytics
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 10 : 12,
                      horizontal: isMobile ? 12 : 16,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.analytics, size: 20),
                      const SizedBox(width: 8),
                      const Text('View Full Analytics'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isMobile) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isMobile ? 1.2 : 1.5,
      children: [
        _buildStatCard(
          title: 'Total Users',
          value: _totalUsers.toString(),
          icon: Icons.people,
          color: Colors.blue,
          isMobile: isMobile,
        ),
        _buildStatCard(
          title: 'Total Helpers',
          value: _totalHelpers.toString(),
          icon: Icons.work_outline,
          color: Colors.green,
          isMobile: isMobile,
        ),
        _buildStatCard(
          title: 'Total Employers',
          value: _totalEmployers.toString(),
          icon: Icons.home_work,
          color: Colors.orange,
          isMobile: isMobile,
        ),
        _buildStatCard(
          title: 'Total Jobs',
          value: _totalJobs.toString(),
          icon: Icons.assignment,
          color: Colors.purple,
          isMobile: isMobile,
        ),
        _buildStatCard(
          title: 'Total Revenue',
          value: 'RWF ${_totalRevenue.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: Colors.teal,
          isMobile: isMobile,
        ),
        _buildStatCard(
          title: 'Avg. Job Value',
          value: _totalJobs > 0
              ? 'RWF ${(_totalRevenue / _totalJobs).toStringAsFixed(2)}'
              : 'RWF 0.00',
          icon: Icons.monetization_on,
          color: Colors.indigo,
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool? trend,
    required bool isMobile,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getColorWithOpacity(color, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: isMobile ? 20 : 24, color: color),
                ),
                if (trend != null)
                  Icon(
                    trend ? Icons.trending_up : Icons.trending_down,
                    color: trend ? Colors.green : Colors.red,
                    size: isMobile ? 20 : 24,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platform Analytics',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Growth (Last 6 Months)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: isMobile ? 200 : 250,
                  child: _userGrowthData.isNotEmpty
                      ? LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: isMobile ? 30 : 40,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: isMobile ? 30 : 40,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() <
                                        _userGrowthData.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          _userGrowthData[value.toInt()].x,
                                          style: TextStyle(
                                            fontSize: isMobile ? 8 : 10,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _userGrowthData
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) =>
                                          FlSpot(e.key.toDouble(), e.value.y),
                                    )
                                    .toList(),
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 3,
                                belowBarData: BarAreaData(show: false),
                                dotData: FlDotData(show: true),
                              ),
                            ],
                          ),
                        )
                      : const Center(child: Text('No data available')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        isMobile
            ? Column(
                children: [
                  _buildJobTrendsChart(isMobile),
                  const SizedBox(height: 12),
                  _buildRevenueChart(isMobile),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildJobTrendsChart(isMobile)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildRevenueChart(isMobile)),
                ],
              ),
      ],
    );
  }

  Widget _buildRevenueChart(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue (Last 3 Months)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: isMobile ? 180 : 200,
              child: _revenueData.isNotEmpty
                  ? LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: isMobile ? 30 : 40,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: isMobile ? 30 : 40,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < _revenueData.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _revenueData[value.toInt()].x,
                                      style: TextStyle(
                                        fontSize: isMobile ? 8 : 10,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _revenueData
                                .asMap()
                                .entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value.y))
                                .toList(),
                            isCurved: true,
                            color: Colors.teal,
                            barWidth: 3,
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color.fromRGBO(0, 150, 136, 0.3),
                            ),
                            dotData: FlDotData(show: true),
                          ),
                        ],
                      ),
                    )
                  : const Center(child: Text('No data available')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        isMobile
            ? Column(
                children: [
                  _buildRecentUsersCard(isMobile),
                  const SizedBox(height: 12),
                  _buildRecentJobsCard(isMobile),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRecentUsersCard(isMobile)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildRecentJobsCard(isMobile)),
                ],
              ),
      ],
    );
  }

  Widget _buildRecentUsersCard(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Users', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._recentUsers.map((user) => _buildRecentUserItem(user, isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentJobsCard(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Jobs', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._recentJobs.map((job) => _buildRecentJobItem(job, isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUserItem(RecentUser user, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 16 : 20,
            backgroundColor: Colors.grey.shade200,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 12 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Chip(
            label: Text(
              user.role.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(fontSize: isMobile ? 8 : 10),
            ),
            backgroundColor: user.role == 'house_helper'
                ? const Color.fromRGBO(76, 175, 80, 0.2)
                : const Color.fromRGBO(33, 150, 243, 0.2),
            labelStyle: TextStyle(
              color: user.role == 'house_helper' ? Colors.green : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentJobItem(RecentJob job, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Job #${job.id.substring(0, 6)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 12 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Chip(
                label: Text(
                  job.status.toUpperCase(),
                  style: TextStyle(fontSize: isMobile ? 8 : 10),
                ),
                backgroundColor: _getStatusColorWithOpacity(job.status),
                labelStyle: TextStyle(color: _getStatusColor(job.status)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${job.employer} → ${job.helper}',
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RWF ${job.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              Text(
                DateFormat('MMM d, y').format(job.date), // Improved date format
                style: TextStyle(
                  fontSize: isMobile ? 10 : 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobTrendsChart(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Trends (Last 3 Months)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: isMobile ? 180 : 200,
              child: _jobTrendsData.isNotEmpty
                  ? BarChart(
                      BarChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: isMobile ? 30 : 40,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: isMobile ? 30 : 40,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() < _jobTrendsData.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _jobTrendsData[value.toInt()].x,
                                      style: TextStyle(
                                        fontSize: isMobile ? 8 : 10,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        barGroups: _jobTrendsData
                            .asMap()
                            .entries
                            .map(
                              (e) => BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value.y,
                                    color: Colors.purple,
                                    width: isMobile ? 16 : 20,
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : const Center(child: Text('No data available')),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'ongoing':
        return Colors.blue;
      case 'finished':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getColorWithOpacity(Color color, double opacity) {
    return Color.fromRGBO(
      (color.r * 255.0).round() & 0xff,
      (color.g * 255.0).round() & 0xff,
      (color.b * 255.0).round() & 0xff,
      opacity,
    );
  }

  Color _getStatusColorWithOpacity(String status) {
    final color = _getStatusColor(status);
    return _getColorWithOpacity(color, 0.2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _selectedIndex == 0
          ? _buildDashboardContent()
          : Center(child: Text('Page $_selectedIndex')),
    );
  }
}

// Data models for charts
class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}

class RecentUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime date;

  RecentUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.date,
  });
}

class RecentJob {
  final String id;
  final String employer;
  final String helper;
  final double amount;
  final String status;
  final DateTime date;

  RecentJob({
    required this.id,
    required this.employer,
    required this.helper,
    required this.amount,
    required this.status,
    required this.date,
  });
}
