import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/training.dart';
import '../../services/training_service.dart';

class TrainingManagementPage extends StatefulWidget {
  const TrainingManagementPage({super.key});

  @override
  State<TrainingManagementPage> createState() => _TrainingManagementPageState();
}

class _TrainingManagementPageState extends State<TrainingManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Training> _trainings = [];
  List<TrainingParticipation> _participants = [];
  bool _isLoading = true;
  String _selectedTrainingId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTrainings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrainings() async {
    try {
      setState(() => _isLoading = true);
      final trainings = await TrainingService.getAllTrainings();
      setState(() {
        _trainings = trainings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading trainings: $e');
    }
  }

  Future<void> _loadParticipants(String trainingId) async {
    try {
      final participants =
          await TrainingService.getTrainingParticipants(trainingId);
      setState(() {
        _participants = participants;
        _selectedTrainingId = trainingId;
      });
    } catch (e) {
      _showErrorSnackBar('Error loading participants: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trainings', icon: Icon(Icons.school)),
            Tab(text: 'Participants', icon: Icon(Icons.people)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateTrainingDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrainings,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrainingsTab(),
          _buildParticipantsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildTrainingsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_trainings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No trainings available'),
            SizedBox(height: 8),
            Text('Tap + to create a new training'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrainings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _trainings.length,
        itemBuilder: (context, index) {
          final training = _trainings[index];
          return _buildTrainingCard(training);
        },
      ),
    );
  }

  Widget _buildTrainingCard(Training training) {
    final statusColor = _getStatusColor(training.status);

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
                    training.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    training.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              training.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(training.startDate),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    training.location,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (training.isMandatory)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'MANDATORY',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (training.isPaid)
                  Container(
                    margin: EdgeInsets.only(left: training.isMandatory ? 8 : 0),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PAID (${training.cost?.toStringAsFixed(0)} RWF)',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => _loadParticipants(training.id!),
                  child: const Text('View Participants'),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleTrainingAction(value, training),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsTab() {
    if (_selectedTrainingId.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Select a training to view participants'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _participants.length,
      itemBuilder: (context, index) {
        final participant = _participants[index];
        return _buildParticipantCard(participant);
      },
    );
  }

  Widget _buildParticipantCard(TrainingParticipation participant) {
    final statusColor = _getParticipationStatusColor(participant.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(Icons.person, color: statusColor),
        ),
        title: Text(participant.workerName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Requested: ${DateFormat('MMM dd, yyyy').format(participant.requestedAt)}'),
            if (participant.completedAt != null)
              Text(
                  'Completed: ${DateFormat('MMM dd, yyyy').format(participant.completedAt!)}'),
            if (participant.score != null)
              Text('Score: ${participant.score!.toStringAsFixed(1)}%'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleParticipantAction(value, participant),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'approve',
              child: Text('Approve'),
            ),
            const PopupMenuItem(
              value: 'reject',
              child: Text('Reject'),
            ),
            const PopupMenuItem(
              value: 'complete',
              child: Text('Mark Complete'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: TrainingService.getTrainingAnalytics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final analytics = snapshot.data ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Training Analytics',
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
                  _buildAnalyticsCard(
                    'Total Trainings',
                    '${analytics['totalTrainings'] ?? 0}',
                    Icons.school,
                    Colors.blue,
                  ),
                  _buildAnalyticsCard(
                    'Completed',
                    '${analytics['completedTrainings'] ?? 0}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildAnalyticsCard(
                    'Total Participants',
                    '${analytics['totalParticipants'] ?? 0}',
                    Icons.people,
                    Colors.orange,
                  ),
                  _buildAnalyticsCard(
                    'Completion Rate',
                    '${(analytics['completionRate'] ?? 0).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsCard(
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

  Color _getStatusColor(TrainingStatus status) {
    switch (status) {
      case TrainingStatus.scheduled:
        return Colors.blue;
      case TrainingStatus.inProgress:
        return Colors.orange;
      case TrainingStatus.completed:
        return Colors.green;
      case TrainingStatus.cancelled:
        return Colors.red;
      case TrainingStatus.postponed:
        return Colors.amber;
    }
  }

  Color _getParticipationStatusColor(ParticipationStatus status) {
    switch (status) {
      case ParticipationStatus.requested:
        return Colors.blue;
      case ParticipationStatus.approved:
        return Colors.green;
      case ParticipationStatus.rejected:
        return Colors.red;
      case ParticipationStatus.inProgress:
        return Colors.orange;
      case ParticipationStatus.completed:
        return Colors.green;
      case ParticipationStatus.failed:
        return Colors.red;
      case ParticipationStatus.cancelled:
        return Colors.grey;
    }
  }

  void _handleTrainingAction(String action, Training training) {
    switch (action) {
      case 'edit':
        _showEditTrainingDialog(training);
        break;
      case 'delete':
        _showDeleteTrainingDialog(training);
        break;
    }
  }

  void _handleParticipantAction(
      String action, TrainingParticipation participant) {
    switch (action) {
      case 'approve':
        _updateParticipantStatus(participant, ParticipationStatus.approved);
        break;
      case 'reject':
        _updateParticipantStatus(participant, ParticipationStatus.rejected);
        break;
      case 'complete':
        _showCompleteParticipantDialog(participant);
        break;
    }
  }

  Future<void> _updateParticipantStatus(
    TrainingParticipation participant,
    ParticipationStatus status,
  ) async {
    try {
      await TrainingService.updateParticipationStatus(
        participationId: participant.id!,
        status: status,
      );
      _loadParticipants(_selectedTrainingId);
      _showSuccessSnackBar('Participant status updated');
    } catch (e) {
      _showErrorSnackBar('Failed to update participant status: $e');
    }
  }

  void _showCreateTrainingDialog() {
    // Implementation for create training dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Training'),
        content: const Text('Training creation form would go here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditTrainingDialog(Training training) {
    // Implementation for edit training dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Training'),
        content: Text('Edit form for: ${training.title}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTrainingDialog(Training training) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Training'),
        content: Text('Are you sure you want to delete "${training.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await TrainingService.deleteTraining(training.id!);
                _loadTrainings();
                _showSuccessSnackBar('Training deleted successfully');
              } catch (e) {
                _showErrorSnackBar('Failed to delete training: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCompleteParticipantDialog(TrainingParticipation participant) {
    final scoreController = TextEditingController();
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Training'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scoreController,
              decoration: const InputDecoration(
                labelText: 'Score (0-100)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(
                labelText: 'Feedback',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              Navigator.pop(context);
              try {
                final score = double.tryParse(scoreController.text);
                await TrainingService.updateParticipationStatus(
                  participationId: participant.id!,
                  status: ParticipationStatus.completed,
                  score: score,
                  feedback: feedbackController.text.isEmpty
                      ? null
                      : feedbackController.text,
                  certificateIssued: score != null && score >= 70,
                );
                _loadParticipants(_selectedTrainingId);
                _showSuccessSnackBar('Training marked as completed');
              } catch (e) {
                _showErrorSnackBar('Failed to complete training: $e');
              }
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}
