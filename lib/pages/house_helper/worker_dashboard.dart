import 'package:flutter/material.dart';
import '../../services/worker_service.dart';
import '../../services/supabase_auth_service.dart';
import '../auth_service.dart';
import 'worker_profile_page.dart';
import 'worker_job_calendar.dart';
import 'worker_training_page.dart';
import 'worker_chat_list.dart';
import 'worker_ratings_page.dart';
import 'worker_settings_page.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  Map<String, dynamic>? _workerProfile;
  List<Map<String, dynamic>> _todaysJobs = [];
  List<Map<String, dynamic>> _upcomingJobs = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;
  String? _workerId;

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    try {
      final user = SupabaseAuthService.getCurrentUser();
      if (user == null) return;

      _workerId = user.id;

      final [profile, todaysJobs, upcomingJobs, analytics] = await Future.wait([
        WorkerService.getWorkerProfile(user.id),
        WorkerService.getTodaysJobs(user.id),
        WorkerService.getUpcomingJobs(user.id),
        WorkerService.getWorkerAnalytics(user.id),
      ]);

      if (mounted) {
        setState(() {
          _workerProfile = profile as Map<String, dynamic>?;
          _todaysJobs = todaysJobs as List<Map<String, dynamic>>;
          _upcomingJobs = upcomingJobs as List<Map<String, dynamic>>;
          _analytics = analytics as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkerData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                final authService = AuthService();
                await authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWorkerData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 16),
              _buildStatsCards(),
              const SizedBox(height: 16),
              _buildTodaysJobsCard(),
              const SizedBox(height: 16),
              _buildUpcomingJobsCard(),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 16),
              _buildVerificationStatus(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildWelcomeCard() {
    final profile = _workerProfile;
    final isVerified = profile?['verification_status'] == 'verified';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: profile?['profiles']?['profile_picture_url'] !=
                      null
                  ? NetworkImage(profile!['profiles']['profile_picture_url'])
                  : null,
              child: profile?['profiles']?['profile_picture_url'] == null
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${profile?['profiles']?['full_name'] ?? 'Worker'}!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isVerified ? Icons.verified : Icons.pending,
                        size: 16,
                        color: isVerified ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVerified ? 'Verified' : 'Pending Verification',
                        style: TextStyle(
                          color: isVerified ? Colors.green : Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (profile?['services'] != null)
                    Text(
                      'Services: ${(profile!['services'] as List).join(', ')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Jobs Today',
            _todaysJobs.length.toString(),
            Icons.today,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Total Jobs',
            _analytics['total_jobs']?.toString() ?? '0',
            Icons.work,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Rating',
            _analytics['average_rating']?.toStringAsFixed(1) ?? '0.0',
            Icons.star,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Earnings',
            'RWF ${_analytics['this_month_earnings']?.toStringAsFixed(0) ?? '0'}',
            Icons.payments,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
      ),
    );
  }

  Widget _buildTodaysJobsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Jobs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkerJobCalendar(),
                    ),
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_todaysJobs.isEmpty)
              const Text('No jobs scheduled for today')
            else
              Column(
                children: _todaysJobs
                    .take(3)
                    .map((job) => _buildJobCard(job))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingJobsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Jobs',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (_upcomingJobs.isEmpty)
              const Text('No upcoming jobs')
            else
              Column(
                children: _upcomingJobs
                    .take(2)
                    .map((job) => _buildJobCard(job))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final startDate = DateTime.tryParse(job['start_date'] ?? '');
    final isToday = startDate != null &&
        startDate.day == DateTime.now().day &&
        startDate.month == DateTime.now().month &&
        startDate.year == DateTime.now().year;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isToday ? Colors.green : Colors.blue,
          child: Icon(
            isToday ? Icons.today : Icons.schedule,
            color: Colors.white,
          ),
        ),
        title: Text(job['service_type'] ?? 'Unknown Service'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${job['household_name'] ?? 'Unknown'}'),
            if (startDate != null)
              Text(
                  'Time: ${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}'),
          ],
        ),
        trailing: Chip(
          label: Text(
            job['status']?.toString().toUpperCase() ?? 'UNKNOWN',
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: _getStatusColor(job['status']),
        ),
        onTap: () {
          // Navigate to job details
          _showJobDetailsDialog(job);
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange.withOpacity(0.2);
      case 'accepted':
        return Colors.green.withOpacity(0.2);
      case 'ongoing':
        return Colors.blue.withOpacity(0.2);
      case 'completed':
        return Colors.purple.withOpacity(0.2);
      case 'cancelled':
        return Colors.red.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  'Update Profile',
                  Icons.person,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkerProfilePage(),
                    ),
                  ),
                ),
                _buildActionButton(
                  'View Trainings',
                  Icons.school,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkerTrainingPage(),
                    ),
                  ),
                ),
                _buildActionButton(
                  'My Ratings',
                  Icons.star,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkerRatingsPage(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVerificationStatus() {
    final verificationStatus = _workerProfile?['verification_status'];

    if (verificationStatus == 'verified') return const SizedBox.shrink();

    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Verification Required',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your profile verification to receive job requests. Upload your ID and required documents.',
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkerProfilePage(),
                ),
              ),
              child: const Text('Complete Verification'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Jobs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: 'Training',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on dashboard
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkerJobCalendar(),
              ),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkerTrainingPage(),
              ),
            );
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkerChatList(),
              ),
            );
            break;
          case 4:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkerSettingsPage(),
              ),
            );
            break;
        }
      },
    );
  }

  void _showJobDetailsDialog(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(job['service_type'] ?? 'Job Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${job['household_name'] ?? 'Unknown'}'),
            Text('Phone: ${job['household_phone'] ?? 'N/A'}'),
            Text(
                'Location: ${job['location'] ?? job['household_district'] ?? 'N/A'}'),
            Text('Date: ${job['start_date']?.substring(0, 10) ?? 'N/A'}'),
            Text('Duration: ${job['duration_hours'] ?? 'N/A'} hours'),
            Text(
                'Rate: RWF ${job['agreed_rate'] ?? job['hourly_rate'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Description:', style: Theme.of(context).textTheme.titleSmall),
            Text(job['description'] ?? 'No description provided'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (job['status'] == 'accepted' && _workerId != null)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _confirmArrival(job['id']);
              },
              child: const Text('Confirm Arrival'),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmArrival(String jobId) async {
    try {
      await WorkerService.confirmArrival(
        requestId: jobId,
        workerId: _workerId!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arrival confirmed successfully')),
      );

      _loadWorkerData(); // Refresh data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming arrival: $e')),
      );
    }
  }
}
