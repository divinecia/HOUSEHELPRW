import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';

class BehaviorReportsPage extends StatefulWidget {
  const BehaviorReportsPage({super.key});

  @override
  State<BehaviorReportsPage> createState() => _BehaviorReportsPageState();
}

class _BehaviorReportsPageState extends State<BehaviorReportsPage> {
  List<BehaviorReport> _reports = [];
  bool _isLoading = true;
  ReportStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      setState(() => _isLoading = true);
      final reports = await AdminService.getAllBehaviorReports(
        statusFilter: _selectedStatus,
      );
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading reports: $e');
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
        title: const Text('Behavior Reports'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<ReportStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) {
              setState(() => _selectedStatus = status);
              _loadReports();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Reports'),
              ),
              const PopupMenuItem(
                value: ReportStatus.pending,
                child: Text('Pending'),
              ),
              const PopupMenuItem(
                value: ReportStatus.investigating,
                child: Text('Investigating'),
              ),
              const PopupMenuItem(
                value: ReportStatus.resolved,
                child: Text('Resolved'),
              ),
              const PopupMenuItem(
                value: ReportStatus.dismissed,
                child: Text('Dismissed'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
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

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.report_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedStatus == null
                  ? 'No behavior reports found'
                  : 'No ${_selectedStatus.toString().split('.').last} reports found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reports will appear here when households submit them',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildReportCard(BehaviorReport report) {
    final severityColor = _getSeverityColor(report.severity);
    final statusColor = _getStatusColor(report.status);

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report against ${report.reportedWorkerName}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${report.reporterHouseholdName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: severityColor),
                      ),
                      child: Text(
                        report.severity
                            .toString()
                            .split('.')
                            .last
                            .toUpperCase(),
                        style: TextStyle(
                          color: severityColor,
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
                        report.status.toString().split('.').last.toUpperCase(),
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
            const SizedBox(height: 12),
            Text(
              'Incident Description:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              report.incidentDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Incident: ${DateFormat('MMM dd, yyyy').format(report.incidentDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.location,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Reported: ${DateFormat('MMM dd, yyyy HH:mm').format(report.reportedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (report.adminNotes?.isNotEmpty == true) ...[
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
                      report.adminNotes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                          ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (!report.emailSentToIsange &&
                    report.status != ReportStatus.dismissed)
                  ElevatedButton.icon(
                    onPressed: () => _sendToIsange(report),
                    icon: const Icon(Icons.email, size: 16),
                    label: const Text('Send to Isange'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (report.emailSentToIsange)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Sent to Isange',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleReportAction(value, report),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'investigate',
                      child: Row(
                        children: [
                          Icon(Icons.search),
                          SizedBox(width: 8),
                          Text('Start Investigation'),
                        ],
                      ),
                    ),
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
                      value: 'escalate',
                      child: Row(
                        children: [
                          Icon(Icons.priority_high, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Escalate'),
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
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(ReportSeverity severity) {
    switch (severity) {
      case ReportSeverity.low:
        return Colors.green;
      case ReportSeverity.medium:
        return Colors.orange;
      case ReportSeverity.high:
        return Colors.red;
      case ReportSeverity.critical:
        return Colors.purple;
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.blue;
      case ReportStatus.investigating:
        return Colors.orange;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.dismissed:
        return Colors.grey;
      case ReportStatus.escalated:
        return Colors.red;
    }
  }

  void _handleReportAction(String action, BehaviorReport report) {
    switch (action) {
      case 'investigate':
        _updateReportStatus(report, ReportStatus.investigating);
        break;
      case 'resolve':
        _showResolveDialog(report);
        break;
      case 'dismiss':
        _showDismissDialog(report);
        break;
      case 'escalate':
        _updateReportStatus(report, ReportStatus.escalated);
        break;
      case 'notes':
        _showNotesDialog(report);
        break;
    }
  }

  Future<void> _updateReportStatus(
      BehaviorReport report, ReportStatus status) async {
    try {
      await AdminService.updateBehaviorReport(
        id: report.id!,
        status: status,
      );
      _loadReports();
      _showSuccessSnackBar('Report status updated');
    } catch (e) {
      _showErrorSnackBar('Failed to update report status: $e');
    }
  }

  Future<void> _sendToIsange(BehaviorReport report) async {
    try {
      final success = await AdminService.sendReportToIsange(report.id!);
      if (success) {
        _loadReports();
        _showSuccessSnackBar('Report sent to Isange One Stop Center');
      } else {
        _showErrorSnackBar('Failed to send report to Isange');
      }
    } catch (e) {
      _showErrorSnackBar('Error sending report: $e');
    }
  }

  void _showResolveDialog(BehaviorReport report) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Are you sure you want to mark this report as resolved?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Resolution Notes',
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
                await AdminService.updateBehaviorReport(
                  id: report.id!,
                  status: ReportStatus.resolved,
                  adminNotes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                );
                _loadReports();
                _showSuccessSnackBar('Report marked as resolved');
              } catch (e) {
                _showErrorSnackBar('Failed to resolve report: $e');
              }
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  void _showDismissDialog(BehaviorReport report) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismiss Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you dismissing this report?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for dismissal',
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
              if (reasonController.text.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await AdminService.updateBehaviorReport(
                    id: report.id!,
                    status: ReportStatus.dismissed,
                    adminNotes: reasonController.text,
                  );
                  _loadReports();
                  _showSuccessSnackBar('Report dismissed');
                } catch (e) {
                  _showErrorSnackBar('Failed to dismiss report: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  void _showNotesDialog(BehaviorReport report) {
    final notesController =
        TextEditingController(text: report.adminNotes ?? '');

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
                await AdminService.updateBehaviorReport(
                  id: report.id!,
                  adminNotes: notesController.text,
                );
                _loadReports();
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
}
