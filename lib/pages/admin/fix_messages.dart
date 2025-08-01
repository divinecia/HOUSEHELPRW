import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/admin_models.dart';
import '../../models/user_role.dart';
import '../../services/admin_service.dart';

class FixMessagesPage extends StatefulWidget {
  const FixMessagesPage({super.key});

  @override
  State<FixMessagesPage> createState() => _FixMessagesPageState();
}

class _FixMessagesPageState extends State<FixMessagesPage> {
  List<FixMessage> _fixMessages = [];
  bool _isLoading = true;
  FixMessageStatus? _selectedStatus;
  FixMessagePriority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _loadFixMessages();
  }

  Future<void> _loadFixMessages() async {
    try {
      setState(() => _isLoading = true);
      final messages = await AdminService.getAllFixMessages(
        statusFilter: _selectedStatus,
        priorityFilter: _selectedPriority,
      );
      setState(() {
        _fixMessages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading fix messages: $e');
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
        title: const Text('System Issues'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => _showFilterDialog(),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.tune),
                    SizedBox(width: 8),
                    Text('Filter'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFixMessages,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_fixMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bug_report_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No system issues found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Issues reported by users will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFixMessages,
      child: Column(
        children: [
          if (_selectedStatus != null || _selectedPriority != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtered by: ${_getFilterText()}',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedStatus = null;
                        _selectedPriority = null;
                      });
                      _loadFixMessages();
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _fixMessages.length,
              itemBuilder: (context, index) {
                final message = _fixMessages[index];
                return _buildFixMessageCard(message);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterText() {
    final filters = <String>[];
    if (_selectedStatus != null) {
      filters.add(_selectedStatus.toString().split('.').last);
    }
    if (_selectedPriority != null) {
      filters.add('${_selectedPriority.toString().split('.').last} priority');
    }
    return filters.join(', ');
  }

  Widget _buildFixMessageCard(FixMessage message) {
    final priorityColor = _getPriorityColor(message.priority);
    final statusColor = _getStatusColor(message.status);
    final typeIcon = _getTypeIcon(message.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(typeIcon, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: priorityColor),
                      ),
                      child: Text(
                        message.priority
                            .toString()
                            .split('.')
                            .last
                            .toUpperCase(),
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        message.status.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Reported by: ${message.reporterName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(message.reporterRole).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message.reporterRole
                        .toString()
                        .split('.')
                        .last
                        .replaceAll('_', ' ')
                        .toUpperCase(),
                    style: TextStyle(
                      color: _getRoleColor(message.reporterRole),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Reported: ${DateFormat('MMM dd, yyyy HH:mm').format(message.reportedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (message.assignedTo != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned to: ${message.assignedTo}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (message.adminNotes?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Notes:',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.adminNotes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                          ),
                    ),
                  ],
                ),
              ),
            ],
            if (message.resolution?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resolution:',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.resolution!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green[700],
                          ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (message.status == FixMessageStatus.pending)
                  ElevatedButton.icon(
                    onPressed: () => _updateMessageStatus(
                        message, FixMessageStatus.inProgress),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Start Work'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMessageAction(value, message),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'assign',
                      child: Row(
                        children: [
                          Icon(Icons.person_add),
                          SizedBox(width: 8),
                          Text('Assign'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'notes',
                      child: Row(
                        children: [
                          Icon(Icons.note_add),
                          SizedBox(width: 8),
                          Text('Add Notes'),
                        ],
                      ),
                    ),
                    if (message.status != FixMessageStatus.resolved)
                      const PopupMenuItem(
                        value: 'resolve',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Mark Resolved'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'dismiss',
                      child: Row(
                        children: [
                          Icon(Icons.close, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Dismiss'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'moreInfo',
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Need More Info'),
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

  Color _getPriorityColor(FixMessagePriority priority) {
    switch (priority) {
      case FixMessagePriority.low:
        return Colors.green;
      case FixMessagePriority.medium:
        return Colors.orange;
      case FixMessagePriority.high:
        return Colors.red;
      case FixMessagePriority.urgent:
        return Colors.purple;
    }
  }

  Color _getStatusColor(FixMessageStatus status) {
    switch (status) {
      case FixMessageStatus.pending:
        return Colors.blue;
      case FixMessageStatus.inProgress:
        return Colors.orange;
      case FixMessageStatus.resolved:
        return Colors.green;
      case FixMessageStatus.dismissed:
        return Colors.grey;
      case FixMessageStatus.needsMoreInfo:
        return Colors.amber;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.house_helper:
        return Colors.blue;
      case UserRole.house_holder:
        return Colors.green;
    }
  }

  IconData _getTypeIcon(FixMessageType type) {
    switch (type) {
      case FixMessageType.bug:
        return Icons.bug_report;
      case FixMessageType.featureRequest:
        return Icons.lightbulb;
      case FixMessageType.improvement:
        return Icons.trending_up;
      case FixMessageType.question:
        return Icons.help;
      case FixMessageType.other:
        return Icons.more_horiz;
    }
  }

  void _handleMessageAction(String action, FixMessage message) {
    switch (action) {
      case 'assign':
        _showAssignDialog(message);
        break;
      case 'notes':
        _showNotesDialog(message);
        break;
      case 'resolve':
        _showResolveDialog(message);
        break;
      case 'dismiss':
        _showDismissDialog(message);
        break;
      case 'moreInfo':
        _updateMessageStatus(message, FixMessageStatus.needsMoreInfo);
        break;
    }
  }

  Future<void> _updateMessageStatus(
      FixMessage message, FixMessageStatus status) async {
    try {
      await AdminService.updateFixMessage(
        id: message.id!,
        status: status,
      );
      _loadFixMessages();
      _showSuccessSnackBar('Message status updated');
    } catch (e) {
      _showErrorSnackBar('Failed to update message status: $e');
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Messages'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<FixMessageStatus?>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('All Statuses')),
                ...FixMessageStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status.toString().split('.').last),
                  ),
                ),
              ],
              onChanged: (value) => _selectedStatus = value,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FixMessagePriority?>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('All Priorities')),
                ...FixMessagePriority.values.map(
                  (priority) => DropdownMenuItem(
                    value: priority,
                    child: Text(priority.toString().split('.').last),
                  ),
                ),
              ],
              onChanged: (value) => _selectedPriority = value,
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
              _loadFixMessages();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(FixMessage message) {
    final assigneeController =
        TextEditingController(text: message.assignedTo ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Message'),
        content: TextField(
          controller: assigneeController,
          decoration: const InputDecoration(
            labelText: 'Assign to',
            border: OutlineInputBorder(),
          ),
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
                await AdminService.updateFixMessage(
                  id: message.id!,
                  assignedTo: assigneeController.text.isEmpty
                      ? null
                      : assigneeController.text,
                );
                _loadFixMessages();
                _showSuccessSnackBar('Message assigned');
              } catch (e) {
                _showErrorSnackBar('Failed to assign message: $e');
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showNotesDialog(FixMessage message) {
    final notesController =
        TextEditingController(text: message.adminNotes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Notes'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
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
                await AdminService.updateFixMessage(
                  id: message.id!,
                  adminNotes: notesController.text,
                );
                _loadFixMessages();
                _showSuccessSnackBar('Notes updated');
              } catch (e) {
                _showErrorSnackBar('Failed to update notes: $e');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(FixMessage message) {
    final resolutionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Describe how this issue was resolved:'),
            const SizedBox(height: 16),
            TextField(
              controller: resolutionController,
              decoration: const InputDecoration(
                labelText: 'Resolution',
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
              if (resolutionController.text.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await AdminService.updateFixMessage(
                    id: message.id!,
                    status: FixMessageStatus.resolved,
                    resolution: resolutionController.text,
                  );
                  _loadFixMessages();
                  _showSuccessSnackBar('Issue marked as resolved');
                } catch (e) {
                  _showErrorSnackBar('Failed to resolve issue: $e');
                }
              }
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  void _showDismissDialog(FixMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismiss Issue'),
        content: const Text('Are you sure you want to dismiss this issue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AdminService.updateFixMessage(
                  id: message.id!,
                  status: FixMessageStatus.dismissed,
                );
                _loadFixMessages();
                _showSuccessSnackBar('Issue dismissed');
              } catch (e) {
                _showErrorSnackBar('Failed to dismiss issue: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}
