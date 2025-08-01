import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/household_service.dart';
import '../../models/hire_request.dart';
import '../../middleware/route_guard.dart';
import '../../models/user_role.dart';
import './find_helpers.dart';
import './chat_page.dart';
import '../auth_service.dart';
import '../login.dart';

class HouseholdDashboard extends StatefulWidget {
  const HouseholdDashboard({super.key});

  @override
  State<HouseholdDashboard> createState() => _HouseholdDashboardState();
}

class _HouseholdDashboardState extends State<HouseholdDashboard> {
  int _selectedIndex = 0;
  List<HireRequest> _recentRequests = [];
  List<Map<String, dynamic>> _recommendedWorkers = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      // Get current user ID (you'll need to implement this in AuthService)
      _currentUserId = AuthService().currentUser?.uid ?? 'demo_household_id';

      // Load recent hire requests
      final requests =
          await HouseholdService.getHouseholdHireRequests(_currentUserId!);
      final recommended = await HouseholdService.getRecommendedWorkers(
        householdId: _currentUserId!,
        limit: 5,
      );

      setState(() {
        _recentRequests = requests.take(3).toList();
        _recommendedWorkers = recommended;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RouteGuard(
      requiredRole: UserRole.house_holder,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('HOUSEHELP'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Profile'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'help',
                  child: ListTile(
                    leading: Icon(Icons.help),
                    title: Text('Help & Support'),
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
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Find Helpers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work),
              label: 'My Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const FindHelpersPage();
      case 2:
        return _buildMyJobsTab();
      case 3:
        return const HouseholderChatPage();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildRecentRequests(),
            const SizedBox(height: 20),
            _buildRecommendedWorkers(),
            const SizedBox(height: 20),
            _buildHelpAndSupport(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find trusted house helpers in your area',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _onItemTapped(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Find Helper Now'),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
            _buildActionCard(
              'Find Helper',
              Icons.search,
              Colors.blue,
              () => _onItemTapped(1),
            ),
            _buildActionCard(
              'Urgent Booking',
              Icons.flash_on,
              Colors.orange,
              () => _showUrgentBookingDialog(),
            ),
            _buildActionCard(
              'Payment History',
              Icons.payment,
              Colors.green,
              () => _showPaymentHistory(),
            ),
            _buildActionCard(
              'Report Issue',
              Icons.report_problem,
              Colors.red,
              () => _showReportDialog(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
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
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Requests',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () => _onItemTapped(2),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentRequests.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No recent requests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by finding a house helper',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_recentRequests.map((request) => _buildRequestCard(request))),
      ],
    );
  }

  Widget _buildRequestCard(HireRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(request.status),
          child: Icon(
            _getStatusIcon(request.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(request.helperName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.serviceType),
            Text(
              DateFormat('MMM dd, yyyy').format(request.startDate),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'RWF ${NumberFormat('#,###').format(request.totalAmount)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              request.status.toString().split('.').last.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(request.status),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        onTap: () => _showRequestDetails(request),
      ),
    );
  }

  Widget _buildRecommendedWorkers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended for You',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (_recommendedWorkers.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No recommendations available at the moment',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendedWorkers.length,
              itemBuilder: (context, index) {
                return _buildWorkerCard(_recommendedWorkers[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => _showWorkerDetails(worker),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: worker['profile_picture_url'] != null
                      ? NetworkImage(worker['profile_picture_url'])
                      : null,
                  child: worker['profile_picture_url'] == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  worker['full_name'] ?? 'Unknown',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  worker['district'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      '${worker['rating'] ?? 0.0}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'RWF ${worker['hourly_rate'] ?? 0}/hr',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpAndSupport() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help & Support',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('How to hire a helper'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showHelpDialog('hiring'),
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Payment methods'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showHelpDialog('payment'),
            ),
            ListTile(
              leading: const Icon(Icons.report_problem),
              title: const Text('Report an issue'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showReportDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyJobsTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'My Hire Requests',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          // Add filters and sorting options here
          ..._recentRequests.map((request) => _buildRequestCard(request)),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Profile & Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Edit Profile'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showEditProfileDialog(),
              ),
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('Payment History'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showPaymentHistory(),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showLanguageDialog(),
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showNotificationSettings(),
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showHelpDialog('general'),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title:
                    const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () => _handleLogout(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(HireStatus status) {
    switch (status) {
      case HireStatus.pending:
        return Colors.orange;
      case HireStatus.accepted:
        return Colors.blue;
      case HireStatus.ongoing:
        return Colors.purple;
      case HireStatus.completed:
        return Colors.green;
      case HireStatus.cancelled:
      case HireStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(HireStatus status) {
    switch (status) {
      case HireStatus.pending:
        return Icons.schedule;
      case HireStatus.accepted:
        return Icons.check_circle;
      case HireStatus.ongoing:
        return Icons.work;
      case HireStatus.completed:
        return Icons.done_all;
      case HireStatus.cancelled:
      case HireStatus.rejected:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        _onItemTapped(4);
        break;
      case 'settings':
        _showNotificationSettings();
        break;
      case 'help':
        _showHelpDialog('general');
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  void _showUrgentBookingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Urgent Booking'),
        content: const Text(
          'Urgent bookings have a 20% premium fee and will prioritize verified workers with high ratings. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FindHelpersPage(),
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showPaymentHistory() {
    // Navigate to payment history page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening payment history...')),
    );
  }

  void _showReportDialog() {
    // Navigate to report issue page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening report issue form...')),
    );
  }

  void _showRequestDetails(HireRequest request) {
    // Navigate to request details page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Helper: ${request.helperName}'),
            Text('Service: ${request.serviceType}'),
            Text(
                'Date: ${DateFormat('MMM dd, yyyy').format(request.startDate)}'),
            Text(
                'Amount: RWF ${NumberFormat('#,###').format(request.totalAmount)}'),
            Text('Status: ${request.status.toString().split('.').last}'),
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

  void _showWorkerDetails(Map<String, dynamic> worker) {
    // Navigate to worker profile page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(worker['full_name'] ?? 'Worker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('District: ${worker['district'] ?? 'N/A'}'),
            Text('Rating: ${worker['rating'] ?? 0.0}'),
            Text('Rate: RWF ${worker['hourly_rate'] ?? 0}/hr'),
            Text('Jobs completed: ${worker['total_jobs_completed'] ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to hire this worker
            },
            child: const Text('Hire'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening profile editor...')),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Kinyarwanda'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Français'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Kiswahili'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening notification settings...')),
    );
  }

  void _showHelpDialog(String type) {
    String content;
    switch (type) {
      case 'hiring':
        content =
            'To hire a helper:\n1. Search for helpers in your area\n2. View their profiles and ratings\n3. Select a helper and create a request\n4. Complete payment\n5. Track your helper\'s arrival';
        break;
      case 'payment':
        content =
            'We accept:\n• MTN Mobile Money\n• Airtel Money\n\nPayments are secure and processed through Paypack.';
        break;
      default:
        content =
            'For support, contact us at:\n• Email: support@househelprw.com\n• Phone: +250 xxx xxx xxx';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help'),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
      ),
    );
  }
}
