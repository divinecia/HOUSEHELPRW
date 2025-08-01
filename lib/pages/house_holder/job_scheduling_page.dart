import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/household_service.dart';

class JobSchedulingPage extends StatefulWidget {
  const JobSchedulingPage({super.key});

  @override
  State<JobSchedulingPage> createState() => _JobSchedulingPageState();
}

class _JobSchedulingPageState extends State<JobSchedulingPage> {
  List<Map<String, dynamic>> _scheduledJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduledJobs();
  }

  Future<void> _loadScheduledJobs() async {
    try {
      setState(() => _isLoading = true);

      // Get current user ID
      const householdId = 'demo_household_id'; // Replace with actual user ID

      final jobs = await HouseholdService.getScheduledJobs(householdId);

      setState(() {
        _scheduledJobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading scheduled jobs: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Scheduling'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScheduledJobs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateJobDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_scheduledJobs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadScheduledJobs,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuickScheduleCard(),
          const SizedBox(height: 20),
          _buildJobsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Scheduled Jobs',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule recurring jobs or one-time tasks with your favorite helpers',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateJobDialog,
              icon: const Icon(Icons.add),
              label: const Text('Schedule New Job'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickScheduleCard() {
    return Card(
      elevation: 4,
      child: Container(
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
              'Quick Schedule',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule common tasks quickly',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickScheduleButton(
                    'Daily Cleaning',
                    Icons.cleaning_services,
                    () => _scheduleQuickJob('cleaning', 'daily'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickScheduleButton(
                    'Weekly Deep Clean',
                    Icons.home,
                    () => _scheduleQuickJob('deep_cleaning', 'weekly'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickScheduleButton(
      String title, IconData icon, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scheduled Jobs',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ..._scheduledJobs.map((job) => _buildJobCard(job)),
      ],
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final nextRun = DateTime.parse(job['next_run_date']);
    final isActive = job['is_active'] == true;
    final frequency = job['frequency'] ?? 'once';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.grey,
          child: Icon(
            _getJobIcon(job['service_type'] ?? 'cleaning'),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          job['title'] ?? 'Untitled Job',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? null : Colors.grey[600],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Helper: ${job['helper_name'] ?? 'Not assigned'}'),
            Text('Next: ${DateFormat('MMM dd, yyyy HH:mm').format(nextRun)}'),
            Text('Frequency: ${frequency.toUpperCase()}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleJobAction(action, job),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
              ),
            ),
            PopupMenuItem(
              value: isActive ? 'pause' : 'resume',
              child: ListTile(
                leading: Icon(isActive ? Icons.pause : Icons.play_arrow),
                title: Text(isActive ? 'Pause' : 'Resume'),
              ),
            ),
            const PopupMenuItem(
              value: 'run_now',
              child: ListTile(
                leading: Icon(Icons.play_circle),
                title: Text('Run Now'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
        onTap: () => _showJobDetails(job),
      ),
    );
  }

  IconData _getJobIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'cleaning':
        return Icons.cleaning_services;
      case 'deep_cleaning':
        return Icons.home;
      case 'cooking':
        return Icons.restaurant;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'gardening':
        return Icons.yard;
      case 'babysitting':
        return Icons.child_care;
      default:
        return Icons.work;
    }
  }

  void _scheduleQuickJob(String serviceType, String frequency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('Schedule ${serviceType.replaceAll('_', ' ').toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Schedule $frequency ${serviceType.replaceAll('_', ' ')}?'),
            const SizedBox(height: 16),
            Text(
              'You can customize the schedule and assign a helper after creation.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createQuickJob(serviceType, frequency);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createQuickJob(String serviceType, String frequency) async {
    try {
      await HouseholdService.createScheduledJob(
        householdId: 'demo_household_id',
        title:
            '${frequency.toUpperCase()} ${serviceType.replaceAll('_', ' ').toUpperCase()}',
        serviceType: serviceType,
        frequency: frequency,
        startDate: DateTime.now().add(const Duration(days: 1)),
        // Default time slots and other parameters
      );

      await _loadScheduledJobs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quick job scheduled successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create job: $e')),
        );
      }
    }
  }

  void _showCreateJobDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateJobDialog(
        onJobCreated: () {
          _loadScheduledJobs();
        },
      ),
    );
  }

  void _showJobDetails(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(job['title'] ?? 'Job Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${job['service_type'] ?? 'N/A'}'),
            Text('Helper: ${job['helper_name'] ?? 'Not assigned'}'),
            Text('Frequency: ${job['frequency'] ?? 'once'}'),
            Text(
                'Next Run: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(job['next_run_date']))}'),
            Text('Status: ${job['is_active'] == true ? 'Active' : 'Paused'}'),
            if (job['notes'] != null && job['notes'].isNotEmpty)
              Text('Notes: ${job['notes']}'),
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
              _showEditJobDialog(job);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showEditJobDialog(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => _EditJobDialog(
        job: job,
        onJobUpdated: () {
          _loadScheduledJobs();
        },
      ),
    );
  }

  void _handleJobAction(String action, Map<String, dynamic> job) async {
    switch (action) {
      case 'edit':
        _showEditJobDialog(job);
        break;
      case 'pause':
      case 'resume':
        await _toggleJobStatus(job['id'], action == 'resume');
        break;
      case 'run_now':
        await _runJobNow(job);
        break;
      case 'delete':
        await _deleteJob(job['id']);
        break;
    }
  }

  Future<void> _toggleJobStatus(String jobId, bool isActive) async {
    try {
      await HouseholdService.updateScheduledJob(
        jobId: jobId,
        updates: {'is_active': isActive},
      );

      await _loadScheduledJobs();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Job resumed' : 'Job paused'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update job: $e')),
        );
      }
    }
  }

  Future<void> _runJobNow(Map<String, dynamic> job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run Job Now'),
        content:
            Text('Create an immediate hire request for "${job['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Run Now'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await HouseholdService.runScheduledJobNow(job['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Job started! Check your hire requests.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to run job: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteJob(String jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text(
            'Are you sure you want to delete this scheduled job? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await HouseholdService.deleteScheduledJob(jobId);

        await _loadScheduledJobs();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete job: $e')),
          );
        }
      }
    }
  }
}

class _CreateJobDialog extends StatefulWidget {
  final VoidCallback onJobCreated;

  const _CreateJobDialog({required this.onJobCreated});

  @override
  State<_CreateJobDialog> createState() => _CreateJobDialogState();
}

class _CreateJobDialogState extends State<_CreateJobDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedService = 'cleaning';
  String _selectedFrequency = 'weekly';
  final DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  final TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isSubmitting = false;

  final List<String> _services = [
    'cleaning',
    'deep_cleaning',
    'cooking',
    'laundry',
    'gardening',
    'babysitting',
    'elderly_care',
    'other'
  ];

  final List<String> _frequencies = [
    'once',
    'daily',
    'weekly',
    'biweekly',
    'monthly'
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Scheduled Job'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Job Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedService,
                  decoration: const InputDecoration(
                    labelText: 'Service Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _services
                      .map((service) => DropdownMenuItem(
                            value: service,
                            child: Text(
                                service.replaceAll('_', ' ').toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedService = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: _frequencies
                      .map((freq) => DropdownMenuItem(
                            value: freq,
                            child: Text(freq.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedFrequency = value!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _createJob,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await HouseholdService.createScheduledJob(
        householdId: 'demo_household_id',
        title: _titleController.text.trim(),
        serviceType: _selectedService,
        frequency: _selectedFrequency,
        startDate: _startDate,
        notes: _notesController.text.trim(),
      );

      widget.onJobCreated();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job scheduled successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create job: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}

class _EditJobDialog extends StatefulWidget {
  final Map<String, dynamic> job;
  final VoidCallback onJobUpdated;

  const _EditJobDialog({required this.job, required this.onJobUpdated});

  @override
  State<_EditJobDialog> createState() => _EditJobDialogState();
}

class _EditJobDialogState extends State<_EditJobDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.job['title']);
    _notesController = TextEditingController(text: widget.job['notes'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Job'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Job Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _updateJob,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await HouseholdService.updateScheduledJob(
        jobId: widget.job['id'],
        updates: {
          'title': _titleController.text.trim(),
          'notes': _notesController.text.trim(),
        },
      );

      widget.onJobUpdated();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update job: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
