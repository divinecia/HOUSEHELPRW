import 'package:flutter/material.dart';
import '../../services/hire_request_services.dart';
import '../../models/hire_request.dart';
import '../auth_service.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HireRequestService _hireRequestService = HireRequestService();
  final AuthService _authService = AuthService();

  List<HireRequest> todaysActivities = [];
  List<HireRequest> upcomingActivities = [];
  Map<String, List<HireRequest>> groupedActivities = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final today = await _hireRequestService.getTodaysHireRequests(user.uid);
        final upcoming = await _hireRequestService.getUpcomingHireRequests(
          user.uid,
        );
        final grouped = await _hireRequestService.getHireRequestsGroupedByDate(
          user.uid,
        );

        setState(() {
          todaysActivities = today;
          upcomingActivities = upcoming;
          groupedActivities = grouped;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load activities: $e')));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Activities'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Calendar'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadActivities,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTodayTab(),
            _buildUpcomingTab(),
            _buildCalendarTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (todaysActivities.isEmpty) {
      return const Center(child: Text('No activities scheduled for today'));
    }

    return ListView.builder(
      itemCount: todaysActivities.length,
      itemBuilder: (context, index) {
        final request = todaysActivities[index];
        return _buildActivityCard(request, isToday: true);
      },
    );
  }

  Widget _buildUpcomingTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (upcomingActivities.isEmpty) {
      return const Center(child: Text('No upcoming activities'));
    }

    return ListView.builder(
      itemCount: upcomingActivities.length,
      itemBuilder: (context, index) {
        final request = upcomingActivities[index];
        return _buildActivityCard(request, isToday: false);
      },
    );
  }

  Widget _buildCalendarTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (groupedActivities.isEmpty) {
      return const Center(child: Text('No scheduled activities'));
    }

    return ListView.builder(
      itemCount: groupedActivities.length,
      itemBuilder: (context, index) {
        final date = groupedActivities.keys.elementAt(index);
        final requests = groupedActivities[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _formatDateHeader(date),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...requests.map((request) => _buildActivityCard(request)),
          ],
        );
      },
    );
  }

  Widget _buildActivityCard(HireRequest request, {bool isToday = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  request.helperName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  label: Text(request.statusDisplayText),
                  backgroundColor: _getStatusColor(request.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${request.startTime} - ${request.hoursPerDay} hours'),
            Text('Activities: ${request.activities.join(", ")}'),
            Text('Location: ${request.workAddress}'),
            if (isToday) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _showActivityDetails(request),
                child: const Text(
                  'View Details',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
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
        return Colors.green;
      case HireStatus.finished:
        return Colors.green;
      case HireStatus.cancelled:
      case HireStatus.canceled:
        return Colors.red;
      case HireStatus.rejected:
        return Colors.red;
    }
  }

  String _formatDateHeader(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      if (date == today) return 'Today';
      if (date == tomorrow) return 'Tomorrow';

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString; // Return the original string if parsing fails
    }
  }

  void _showActivityDetails(HireRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Activity Details - ${request.helperName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', request.statusDisplayText),
              _buildDetailRow(
                'Date',
                '${request.startDate.day}/${request.startDate.month}/${request.startDate.year}',
              ),
              _buildDetailRow(
                'Time',
                '${request.startTime} for ${request.hoursPerDay} hours',
              ),
              _buildDetailRow('Activities', request.activities.join(", ")),
              _buildDetailRow('Address', request.workAddress),
              _buildDetailRow('Contact', request.helperPhone),
              if (request.notes != null)
                _buildDetailRow('Notes', request.notes!),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
