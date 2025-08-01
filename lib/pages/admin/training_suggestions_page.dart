import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../services/training_service.dart';

class TrainingSuggestionsPage extends StatefulWidget {
  const TrainingSuggestionsPage({super.key});

  @override
  State<TrainingSuggestionsPage> createState() =>
      _TrainingSuggestionsPageState();
}

class _TrainingSuggestionsPageState extends State<TrainingSuggestionsPage> {
  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> _trainings = [];
  List<Map<String, dynamic>> _workers = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'all';

  final List<Map<String, String>> _statusFilters = [
    {'value': 'all', 'label': 'All Suggestions'},
    {'value': 'pending', 'label': 'Pending Review'},
    {'value': 'approved', 'label': 'Approved'},
    {'value': 'rejected', 'label': 'Rejected'},
    {'value': 'admin_suggested', 'label': 'Admin Suggested'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final suggestions = await AdminService.getAllTrainingSuggestions(
        statusFilter:
            _selectedStatusFilter == 'all' ? null : _selectedStatusFilter,
        orderBy: 'created_at',
        ascending: false,
      );

      final trainings = await TrainingService.getAllTrainings();
      final workers =
          await AdminService.getAllWorkers?.call() ?? []; // Defensive

      setState(() {
        _suggestions = suggestions;
        _trainings = trainings
            .map((t) => t is Map<String, dynamic> ? t : t.toJson())
            .toList();
        _workers = workers
            .map((w) => w is Map<String, dynamic> ? w : w.toJson())
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Suggestions'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSuggestionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _suggestions.isEmpty
              ? _buildEmptyState()
              : _buildSuggestionsList(),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatusFilter,
              decoration: const InputDecoration(
                labelText: 'Filter by Status',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _statusFilters
                  .map((filter) => DropdownMenuItem(
                        value: filter['value'],
                        child: Text(filter['label']!),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedStatusFilter = value ?? 'all');
                _loadData();
              },
            ),
          ),
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
              Icons.school_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Training Suggestions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suggestions will appear here when households recommend workers for training',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateSuggestionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Suggestion'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          return _buildSuggestionCard(_suggestions[index]);
        },
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final status = suggestion['status'] ?? 'pending';
    DateTime? createdAt;
    try {
      createdAt = DateTime.parse(suggestion['created_at']);
    } catch (_) {
      createdAt = null;
    }
    final isFromHousehold = suggestion['suggested_by_household_id'] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status),
          child: Icon(
            _getStatusIcon(status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          suggestion['worker_name'] ?? 'Unknown Worker',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Training: ${suggestion['training_title'] ?? 'Unknown Training'}'),
            Text(
              isFromHousehold
                  ? 'Suggested by: ${suggestion['suggested_by_household_name'] ?? 'Household'}'
                  : 'Suggested by: Admin',
            ),
            Text(
                'Date: ${createdAt != null ? DateFormat('MMM dd, yyyy').format(createdAt) : 'Unknown'}'),
            Text(
              'Status: ${status.toUpperCase()}',
              style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: status == 'pending'
            ? PopupMenuButton<String>(
                onSelected: (action) =>
                    _handleSuggestionAction(action, suggestion),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'approve',
                    child: ListTile(
                      leading: Icon(Icons.check, color: Colors.green),
                      title: Text('Approve'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reject',
                    child: ListTile(
                      leading: Icon(Icons.close, color: Colors.red),
                      title: Text('Reject'),
                    ),
                  ),
                ],
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (suggestion['notes'] != null &&
                    suggestion['notes'].isNotEmpty) ...[
                  Text(
                    'Notes:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(suggestion['notes']),
                  const SizedBox(height: 12),
                ],
                if (suggestion['admin_notes'] != null &&
                    suggestion['admin_notes'].isNotEmpty) ...[
                  Text(
                    'Admin Notes:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(suggestion['admin_notes']),
                  const SizedBox(height: 12),
                ],
                if (suggestion['processed_at'] != null) ...[
                  Text(
                    'Processed: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.tryParse(suggestion['processed_at']) ?? DateTime.now())}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  if (suggestion['processed_by'] != null)
                    Text(
                      'By: ${suggestion['processed_by']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'admin_suggested':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'admin_suggested':
        return Icons.admin_panel_settings;
      default:
        return Icons.help;
    }
  }

  void _handleSuggestionAction(String action, Map<String, dynamic> suggestion) {
    if (action == 'approve') {
      _showApprovalDialog(suggestion);
    } else if (action == 'reject') {
      _showRejectionDialog(suggestion);
    }
  }

  void _showApprovalDialog(Map<String, dynamic> suggestion) {
    final notesController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Approve Training Suggestion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Approve training suggestion for ${suggestion['worker_name']}?'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Admin Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      setState(() => isProcessing = true);
                      Navigator.pop(context);
                      await _processSuggestion(
                        suggestion['id'],
                        'approved',
                        notesController.text.trim(),
                      );
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectionDialog(Map<String, dynamic> suggestion) {
    final notesController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Reject Training Suggestion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Reject training suggestion for ${suggestion['worker_name']}?'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Rejection',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (notesController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please provide a reason for rejection')),
                        );
                        return;
                      }
                      setState(() => isProcessing = true);
                      Navigator.pop(context);
                      await _processSuggestion(
                        suggestion['id'],
                        'rejected',
                        notesController.text.trim(),
                      );
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Reject'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processSuggestion(
      String suggestionId, String status, String notes) async {
    try {
      await AdminService.processTrainingSuggestion(
        suggestionId: suggestionId,
        status: status,
        adminNotes: notes.isEmpty ? null : notes,
        processedBy: 'Admin User', // TODO: Replace with actual admin name
      );

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Training suggestion $status'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process suggestion: $e')),
        );
      }
    }
  }

  void _showCreateSuggestionDialog() {
    String? selectedWorkerId;
    String? selectedTrainingId;
    final notesController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Training Suggestion'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedWorkerId,
                  decoration: const InputDecoration(
                    labelText: 'Select Worker',
                    border: OutlineInputBorder(),
                  ),
                  items: _workers.isNotEmpty
                      ? _workers
                          .map((worker) => DropdownMenuItem<String>(
                                value: worker['id'] as String,
                                child: Text(worker['name'] ?? 'Unknown Worker'),
                              ))
                          .toList()
                      : [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No workers found'),
                          ),
                        ],
                  onChanged: (value) =>
                      setState(() => selectedWorkerId = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTrainingId,
                  decoration: const InputDecoration(
                    labelText: 'Select Training',
                    border: OutlineInputBorder(),
                  ),
                  items: _trainings.isNotEmpty
                      ? _trainings
                          .map((training) => DropdownMenuItem<String>(
                                value: training['id'] as String,
                                child: Text(
                                    training['title'] ?? 'Unknown Training'),
                              ))
                          .toList()
                      : [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No trainings found'),
                          ),
                        ],
                  onChanged: (value) =>
                      setState(() => selectedTrainingId = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (selectedWorkerId != null &&
                      selectedTrainingId != null &&
                      !isProcessing)
                  ? () async {
                      setState(() => isProcessing = true);
                      Navigator.pop(context);
                      await _createAdminSuggestion(
                        selectedWorkerId!,
                        selectedTrainingId!,
                        notesController.text.trim(),
                      );
                    }
                  : null,
              child: isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAdminSuggestion(
      String workerId, String trainingId, String notes) async {
    try {
      final training = _trainings.firstWhere((t) => t['id'] == trainingId);
      final worker = _workers.firstWhere((w) => w['id'] == workerId);

      await AdminService.createWorkerTrainingSuggestion(
        workerId: workerId,
        workerName: worker['name'] ?? 'Selected Worker',
        trainingId: trainingId,
        trainingTitle: training['title'],
        suggestedByAdminId: 'admin_user_id',
        suggestedByAdminName: 'Admin User',
        notes: notes.isEmpty ? null : notes,
      );

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Training suggestion created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create suggestion: $e')),
        );
      }
    }
  }
}
