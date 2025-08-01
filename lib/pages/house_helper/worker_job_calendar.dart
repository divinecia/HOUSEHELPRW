import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/worker_service.dart';
import '../../services/supabase_auth_service.dart';

class WorkerJobCalendar extends StatefulWidget {
  const WorkerJobCalendar({super.key});

  @override
  State<WorkerJobCalendar> createState() => _WorkerJobCalendarState();
}

class _WorkerJobCalendarState extends State<WorkerJobCalendar> {
  late final ValueNotifier<List<Map<String, dynamic>>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Map<String, dynamic>> _allJobs = [];
  bool _isLoading = true;
  String? _workerId;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadJobs();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    try {
      final user = SupabaseAuthService.getCurrentUser();
      if (user == null) return;

      _workerId = user.id;

      // Load jobs for the current month and next month
      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

      final jobs = await WorkerService.getWorkerJobs(
        workerId: user.id,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _allJobs = jobs;
          _isLoading = false;
        });
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _allJobs.where((job) {
      final jobDate = DateTime.tryParse(job['start_date'] ?? '');
      if (jobDate == null) return false;

      return isSameDay(jobDate, day);
    }).toList();
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
        title: const Text('Job Calendar'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadJobs,
          ),
          PopupMenuButton<CalendarFormat>(
            onSelected: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CalendarFormat.month,
                child: Text('Month View'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.twoWeeks,
                child: Text('2 Weeks View'),
              ),
              const PopupMenuItem(
                value: CalendarFormat.week,
                child: Text('Week View'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Map<String, dynamic>>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _selectedEvents.value = _getEventsForDay(selectedDay);
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              _loadJobs(); // Load jobs for the new month
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: _selectedEvents,
              builder: (context, events, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Jobs for ${_selectedDay?.day}/${_selectedDay?.month}/${_selectedDay?.year}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: events.isEmpty
                          ? const Center(
                              child: Text('No jobs scheduled for this day'),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: events.length,
                              itemBuilder: (context, index) {
                                return _buildJobCard(events[index]);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final startDate = DateTime.tryParse(job['start_date'] ?? '');
    final status = job['status'] ?? 'unknown';
    final isToday = startDate != null && isSameDay(startDate, DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job['service_type'] ?? 'Unknown Service',
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
                  backgroundColor: _getStatusColor(status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 4),
                Text('Client: ${job['household_name'] ?? 'Unknown'}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Text(
                    'Location: ${job['location'] ?? job['household_district'] ?? 'N/A'}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                    'Time: ${startDate != null ? "${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}" : 'N/A'}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 4),
                Text('Duration: ${job['duration_hours'] ?? 'N/A'} hours'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.payments, size: 16),
                const SizedBox(width: 4),
                Text(
                    'Rate: RWF ${job['agreed_rate'] ?? job['hourly_rate'] ?? 'N/A'}'),
              ],
            ),
            if (job['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Description:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(job['description']),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (status == 'accepted' && isToday)
                  ElevatedButton.icon(
                    onPressed: () => _confirmArrival(job),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Confirm Arrival'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (status == 'accepted')
                  OutlinedButton.icon(
                    onPressed: () => _reportDelay(job),
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('Report Delay'),
                  ),
                if (status == 'accepted')
                  OutlinedButton.icon(
                    onPressed: () => _requestReschedule(job),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('Reschedule'),
                  ),
                if (status == 'ongoing')
                  ElevatedButton.icon(
                    onPressed: () => _completeJob(job),
                    icon: const Icon(Icons.done, size: 16),
                    label: const Text('Complete Job'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
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

  Future<void> _confirmArrival(Map<String, dynamic> job) async {
    if (_workerId == null) return;

    try {
      await WorkerService.confirmArrival(
        requestId: job['id'],
        workerId: _workerId!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arrival confirmed successfully')),
      );

      _loadJobs(); // Refresh jobs
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming arrival: $e')),
      );
    }
  }

  Future<void> _reportDelay(Map<String, dynamic> job) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _DelayReportDialog(),
    );

    if (result != null) {
      try {
        await WorkerService.reportDelay(
          requestId: job['id'],
          delayMinutes: result['minutes'],
          reason: result['reason'],
          notes: result['notes'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delay reported successfully')),
        );

        _loadJobs();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reporting delay: $e')),
        );
      }
    }
  }

  Future<void> _requestReschedule(Map<String, dynamic> job) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _RescheduleRequestDialog(),
    );

    if (result != null) {
      try {
        await WorkerService.requestReschedule(
          requestId: job['id'],
          newDate: result['newDate'],
          reason: result['reason'],
          notes: result['notes'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reschedule request sent successfully')),
        );

        _loadJobs();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting reschedule: $e')),
        );
      }
    }
  }

  Future<void> _completeJob(Map<String, dynamic> job) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => _JobCompletionDialog(),
    );

    if (notes != null) {
      try {
        await WorkerService.updateJobStatus(
          requestId: job['id'],
          status: 'completed',
          notes: notes.isEmpty ? null : notes,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job completed successfully')),
        );

        _loadJobs();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing job: $e')),
        );
      }
    }
  }
}

class _DelayReportDialog extends StatefulWidget {
  @override
  _DelayReportDialogState createState() => _DelayReportDialogState();
}

class _DelayReportDialogState extends State<_DelayReportDialog> {
  final _minutesController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedReason = 'Traffic';

  final List<String> _delayReasons = [
    'Traffic',
    'Transportation Issue',
    'Emergency',
    'Weather',
    'Personal Issue',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Delay'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _minutesController,
              decoration: const InputDecoration(
                labelText: 'Delay (minutes)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              items: _delayReasons
                  .map((reason) => DropdownMenuItem(
                        value: reason,
                        child: Text(reason),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReason = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
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
          onPressed: () {
            final minutes = int.tryParse(_minutesController.text);
            if (minutes != null && minutes > 0) {
              Navigator.pop(context, {
                'minutes': minutes,
                'reason': _selectedReason,
                'notes': _notesController.text,
              });
            }
          },
          child: const Text('Report'),
        ),
      ],
    );
  }
}

class _RescheduleRequestDialog extends StatefulWidget {
  @override
  _RescheduleRequestDialogState createState() =>
      _RescheduleRequestDialogState();
}

class _RescheduleRequestDialogState extends State<_RescheduleRequestDialog> {
  DateTime? _selectedDate;
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Reschedule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('New Date'),
              subtitle: Text(
                  _selectedDate?.toString().split(' ')[0] ?? 'Select date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Reschedule',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
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
          onPressed: () {
            if (_selectedDate != null && _reasonController.text.isNotEmpty) {
              Navigator.pop(context, {
                'newDate': _selectedDate!,
                'reason': _reasonController.text,
                'notes': _notesController.text,
              });
            }
          },
          child: const Text('Send Request'),
        ),
      ],
    );
  }
}

class _JobCompletionDialog extends StatefulWidget {
  @override
  _JobCompletionDialogState createState() => _JobCompletionDialogState();
}

class _JobCompletionDialogState extends State<_JobCompletionDialog> {
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete Job'),
      content: TextField(
        controller: _notesController,
        decoration: const InputDecoration(
          labelText: 'Completion Notes (Optional)',
          border: OutlineInputBorder(),
          hintText: 'Any additional notes about the completed work...',
        ),
        maxLines: 4,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _notesController.text),
          child: const Text('Complete Job'),
        ),
      ],
    );
  }
}
