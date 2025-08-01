import 'package:flutter/material.dart';
import '../../services/household_service.dart';

class ReportWorkerBehaviorPage extends StatefulWidget {
  final String? workerId;
  final String? workerName;
  final String? requestId;

  const ReportWorkerBehaviorPage({
    super.key,
    this.workerId,
    this.workerName,
    this.requestId,
  });

  @override
  State<ReportWorkerBehaviorPage> createState() =>
      _ReportWorkerBehaviorPageState();
}

class _ReportWorkerBehaviorPageState extends State<ReportWorkerBehaviorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'misconduct';
  String _selectedSeverity = 'medium';
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = [
    {'value': 'misconduct', 'label': 'Misconduct', 'icon': '⚠️'},
    {'value': 'poor_work', 'label': 'Poor Work Quality', 'icon': '👎'},
    {
      'value': 'unprofessional',
      'label': 'Unprofessional Behavior',
      'icon': '😤'
    },
    {'value': 'dishonesty', 'label': 'Dishonesty/Theft', 'icon': '🚫'},
    {'value': 'harassment', 'label': 'Harassment', 'icon': '🛑'},
    {'value': 'safety_violation', 'label': 'Safety Violation', 'icon': '⚡'},
    {'value': 'other', 'label': 'Other', 'icon': '📝'},
  ];

  final List<Map<String, String>> _severities = [
    {'value': 'low', 'label': 'Minor Issue', 'color': 'green'},
    {'value': 'medium', 'label': 'Moderate Issue', 'color': 'orange'},
    {'value': 'high', 'label': 'Serious Issue', 'color': 'red'},
    {'value': 'critical', 'label': 'Critical Issue', 'color': 'darkred'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Worker Behavior'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 20),
              _buildWorkerInfo(),
              const SizedBox(height: 20),
              _buildCategorySelection(),
              const SizedBox(height: 20),
              _buildSeveritySelection(),
              const SizedBox(height: 20),
              _buildTitleField(),
              const SizedBox(height: 20),
              _buildDescriptionField(),
              const SizedBox(height: 20),
              _buildAnonymousOption(),
              const SizedBox(height: 20),
              _buildDisclaimerCard(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Report Guidelines',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• Only report genuine behavior issues\n'
              '• Provide specific details and examples\n'
              '• Reports are reviewed by our admin team\n'
              '• False reports may result in account suspension',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.blue.shade700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerInfo() {
    if (widget.workerName == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 25),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reporting about:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  Text(
                    widget.workerName!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category['value'];

            return InkWell(
              onTap: () =>
                  setState(() => _selectedCategory = category['value']!),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.white,
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category['icon']!,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category['label']!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[700],
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSeveritySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Severity Level *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...(_severities.map((severity) {
          final isSelected = _selectedSeverity == severity['value'];
          Color severityColor;

          switch (severity['color']) {
            case 'green':
              severityColor = Colors.green;
              break;
            case 'orange':
              severityColor = Colors.orange;
              break;
            case 'red':
              severityColor = Colors.red;
              break;
            case 'darkred':
              severityColor = Colors.red.shade800;
              break;
            default:
              severityColor = Colors.grey;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isSelected ? severityColor.withOpacity(0.1) : null,
            child: RadioListTile<String>(
              value: severity['value']!,
              groupValue: _selectedSeverity,
              onChanged: (value) => setState(() => _selectedSeverity = value!),
              title: Text(
                severity['label']!,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? severityColor : null,
                ),
              ),
              activeColor: severityColor,
            ),
          );
        })),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Brief summary of the issue',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            if (value.trim().length < 5) {
              return 'Title must be at least 5 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Description *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText:
                'Provide specific details about what happened, when, and any witnesses...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a detailed description';
            }
            if (value.trim().length < 20) {
              return 'Description must be at least 20 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAnonymousOption() {
    return Card(
      child: CheckboxListTile(
        value: _isAnonymous,
        onChanged: (value) => setState(() => _isAnonymous = value ?? false),
        title: const Text('Submit anonymously'),
        subtitle: const Text(
          'Your identity will not be revealed to the worker, but our admin team will still have access for investigation purposes.',
        ),
        secondary: const Icon(Icons.visibility_off),
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Important Notice',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This report will be reviewed by our admin team and may result in '
              'disciplinary action against the worker. For urgent safety concerns, '
              'please contact local authorities immediately.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Submitting Report...'),
                ],
              )
            : const Text(
                'Submit Report',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Report'),
        content: const Text(
          'Are you sure you want to submit this behavior report? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      await HouseholdService.submitBehaviorReport(
        workerId: widget.workerId,
        workerName: widget.workerName,
        requestId: widget.requestId,
        category: _selectedCategory,
        severity: _selectedSeverity,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        isAnonymous: _isAnonymous,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Report submitted successfully. Our team will review it.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
