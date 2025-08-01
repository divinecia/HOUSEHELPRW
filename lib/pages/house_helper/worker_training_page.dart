import 'package:flutter/material.dart';
import '../../services/worker_service.dart';
import '../../services/supabase_auth_service.dart';

class WorkerTrainingPage extends StatefulWidget {
  const WorkerTrainingPage({super.key});

  @override
  State<WorkerTrainingPage> createState() => _WorkerTrainingPageState();
}

class _WorkerTrainingPageState extends State<WorkerTrainingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _availableTrainings = [];
  List<Map<String, dynamic>> _myEnrollments = [];
  bool _isLoading = true;
  String? _selectedServiceFilter;
  String? _workerId;

  final List<String> _serviceTypes = [
    'All Services',
    'House Cleaning',
    'Cooking',
    'Laundry',
    'Child Care',
    'Elder Care',
    'Garden Maintenance',
    'Pet Care',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedServiceFilter = 'All Services';
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = SupabaseAuthService.getCurrentUser();
      if (user == null) return;

      _workerId = user.id;

      final [availableTrainings, enrollments] = await Future.wait([
        WorkerService.getAvailableTrainings(
          serviceType: _selectedServiceFilter == 'All Services'
              ? null
              : _selectedServiceFilter,
        ),
        WorkerService.getWorkerTrainingEnrollments(user.id),
      ]);

      if (mounted) {
        setState(() {
          _availableTrainings = availableTrainings;
          _myEnrollments = enrollments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading training data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available', icon: Icon(Icons.school)),
            Tab(text: 'My Enrollments', icon: Icon(Icons.assignment)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableTrainingsTab(),
                _buildMyEnrollmentsTab(),
              ],
            ),
    );
  }

  Widget _buildAvailableTrainingsTab() {
    return Column(
      children: [
        _buildServiceFilter(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _availableTrainings.isEmpty
                ? const Center(
                    child: Text('No training sessions available'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _availableTrainings.length,
                    itemBuilder: (context, index) {
                      return _buildAvailableTrainingCard(
                          _availableTrainings[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyEnrollmentsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _myEnrollments.isEmpty
          ? const Center(
              child: Text('No training enrollments yet'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myEnrollments.length,
              itemBuilder: (context, index) {
                return _buildEnrollmentCard(_myEnrollments[index]);
              },
            ),
    );
  }

  Widget _buildServiceFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<String>(
        value: _selectedServiceFilter,
        decoration: const InputDecoration(
          labelText: 'Filter by Service Type',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.filter_list),
        ),
        items: _serviceTypes
            .map((service) => DropdownMenuItem(
                  value: service,
                  child: Text(service),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedServiceFilter = value;
          });
          _loadData();
        },
      ),
    );
  }

  Widget _buildAvailableTrainingCard(Map<String, dynamic> training) {
    final startDate = DateTime.tryParse(training['start_date'] ?? '');
    final endDate = DateTime.tryParse(training['end_date'] ?? '');
    final cost = training['cost'] ?? 0.0;
    final isEnrolled = _myEnrollments
        .any((enrollment) => enrollment['training_id'] == training['id']);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    training['title'] ?? 'Unknown Training',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (cost > 0)
                  Chip(
                    label: Text('RWF ${cost.toStringAsFixed(0)}'),
                    backgroundColor: Colors.green.withOpacity(0.2),
                  )
                else
                  const Chip(
                    label: Text('FREE'),
                    backgroundColor: Colors.blue,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              training['description'] ?? 'No description available',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _buildTrainingDetail(Icons.calendar_today, 'Start Date',
                startDate?.toString().split(' ')[0] ?? 'TBD'),
            _buildTrainingDetail(Icons.event, 'End Date',
                endDate?.toString().split(' ')[0] ?? 'TBD'),
            _buildTrainingDetail(
                Icons.location_on, 'Location', training['location'] ?? 'TBD'),
            _buildTrainingDetail(Icons.group, 'Max Participants',
                training['max_participants']?.toString() ?? 'Unlimited'),
            if (training['target_services'] != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: (training['target_services'] as List)
                    .map((service) => Chip(
                          label: Text(service,
                              style: const TextStyle(fontSize: 10)),
                          backgroundColor: Colors.blue.withOpacity(0.1),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showTrainingDetails(training),
                    icon: const Icon(Icons.info, size: 16),
                    label: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        isEnrolled ? null : () => _requestEnrollment(training),
                    icon: Icon(
                      isEnrolled ? Icons.check : Icons.add,
                      size: 16,
                    ),
                    label: Text(isEnrolled ? 'Enrolled' : 'Request to Join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEnrolled ? Colors.grey : null,
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

  Widget _buildEnrollmentCard(Map<String, dynamic> enrollment) {
    final status = enrollment['status'] ?? 'unknown';
    final startDate =
        DateTime.tryParse(enrollment['training_start_date'] ?? '');
    final cost = enrollment['training_cost'] ?? 0.0;
    final paymentStatus = enrollment['payment_status'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    enrollment['training_title'] ?? 'Unknown Training',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: _getEnrollmentStatusColor(status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              enrollment['training_description'] ?? 'No description',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _buildTrainingDetail(Icons.calendar_today, 'Start Date',
                startDate?.toString().split(' ')[0] ?? 'TBD'),
            _buildTrainingDetail(Icons.location_on, 'Location',
                enrollment['training_location'] ?? 'TBD'),
            _buildTrainingDetail(Icons.access_time, 'Enrolled',
                enrollment['requested_at']?.substring(0, 10) ?? 'Unknown'),
            if (cost > 0) ...[
              _buildTrainingDetail(
                  Icons.payments, 'Cost', 'RWF ${cost.toStringAsFixed(0)}'),
              _buildTrainingDetail(
                  Icons.payment, 'Payment Status', paymentStatus ?? 'Pending'),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (cost > 0 && paymentStatus != 'paid' && status == 'approved')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _payForTraining(enrollment),
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Pay Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                if (status == 'pending')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelEnrollment(enrollment),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancel Request'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                if (status == 'approved' || status == 'enrolled')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showTrainingDetails(enrollment, isEnrollment: true),
                      icon: const Icon(Icons.info, size: 16),
                      label: const Text('View Details'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Color _getEnrollmentStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.withOpacity(0.2);
      case 'approved':
        return Colors.green.withOpacity(0.2);
      case 'enrolled':
        return Colors.blue.withOpacity(0.2);
      case 'completed':
        return Colors.purple.withOpacity(0.2);
      case 'rejected':
        return Colors.red.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Future<void> _requestEnrollment(Map<String, dynamic> training) async {
    if (_workerId == null) return;

    final motivation = await showDialog<String>(
      context: context,
      builder: (context) => _EnrollmentRequestDialog(),
    );

    if (motivation != null) {
      try {
        await WorkerService.requestTrainingEnrollment(
          workerId: _workerId!,
          trainingId: training['id'],
          motivation: motivation.isEmpty ? null : motivation,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Training request submitted successfully')),
        );

        _loadData(); // Refresh data
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting request: $e')),
        );
      }
    }
  }

  Future<void> _payForTraining(Map<String, dynamic> enrollment) async {
    if (_workerId == null) return;

    final phoneNumber = await showDialog<String>(
      context: context,
      builder: (context) => _PaymentDialog(
        amount: enrollment['training_cost']?.toDouble() ?? 0.0,
      ),
    );

    if (phoneNumber != null) {
      try {
        final success = await WorkerService.payForTraining(
          enrollmentId: enrollment['id'],
          workerId: _workerId!,
          amount: enrollment['training_cost']?.toDouble() ?? 0.0,
          phoneNumber: phoneNumber,
          description: 'Payment for ${enrollment['training_title']} training',
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment initiated successfully')),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment failed. Please try again.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing payment: $e')),
        );
      }
    }
  }

  void _showTrainingDetails(Map<String, dynamic> training,
      {bool isEnrollment = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEnrollment
              ? training['training_title'] ?? 'Training Details'
              : training['title'] ?? 'Training Details',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                isEnrollment
                    ? training['training_description'] ?? 'No description'
                    : training['description'] ?? 'No description',
              ),
              const SizedBox(height: 16),
              if (training['requirements'] != null) ...[
                Text(
                  'Requirements:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(training['requirements']),
                const SizedBox(height: 16),
              ],
              if (training['outcomes'] != null) ...[
                Text(
                  'Learning Outcomes:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(training['outcomes']),
                const SizedBox(height: 16),
              ],
              if (training['instructor'] != null) ...[
                Text(
                  'Instructor:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(training['instructor']),
              ],
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

  Future<void> _cancelEnrollment(Map<String, dynamic> enrollment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Enrollment'),
        content: const Text(
            'Are you sure you want to cancel this training request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Implementation would depend on your backend API
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrollment cancelled')),
      );
      _loadData();
    }
  }
}

class _EnrollmentRequestDialog extends StatefulWidget {
  @override
  _EnrollmentRequestDialogState createState() =>
      _EnrollmentRequestDialogState();
}

class _EnrollmentRequestDialogState extends State<_EnrollmentRequestDialog> {
  final _motivationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Training Enrollment'),
      content: TextField(
        controller: _motivationController,
        decoration: const InputDecoration(
          labelText: 'Motivation (Optional)',
          border: OutlineInputBorder(),
          hintText: 'Why do you want to join this training?',
        ),
        maxLines: 4,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _motivationController.text),
          child: const Text('Submit Request'),
        ),
      ],
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final double amount;

  const _PaymentDialog({required this.amount});

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _phoneController = TextEditingController();
  String _selectedProvider = 'MTN';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Training Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Amount: RWF ${widget.amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedProvider,
            decoration: const InputDecoration(
              labelText: 'Payment Provider',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'MTN', child: Text('MTN Mobile Money')),
              DropdownMenuItem(value: 'Airtel', child: Text('Airtel Money')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedProvider = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              prefixText: '+250 ',
            ),
            keyboardType: TextInputType.phone,
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
            if (_phoneController.text.isNotEmpty) {
              Navigator.pop(context, _phoneController.text);
            }
          },
          child: const Text('Pay Now'),
        ),
      ],
    );
  }
}
