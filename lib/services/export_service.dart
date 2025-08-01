import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/supabase_service.dart';

class ExportService {
  /// Export users data to CSV
  static Future<String?> exportUsersToCSV({
    String? role,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final data = await _getUsersData(
        role: role,
        startDate: startDate,
        endDate: endDate,
      );

      final csvData = [
        // Headers
        [
          'ID',
          'Email',
          'Full Name',
          'Phone',
          'Role',
          'Verification Status',
          'Created At',
          'Last Sign In',
          'Profile Completion',
          'Active Jobs',
          'Total Earnings'
        ],
        // Data rows
        ...data.map((user) => [
              user['id'] ?? '',
              user['email'] ?? '',
              user['full_name'] ?? '',
              user['phone'] ?? '',
              user['role'] ?? '',
              user['verification_status'] ?? 'pending',
              user['created_at'] ?? '',
              user['last_sign_in_at'] ?? '',
              '${user['profile_completion'] ?? 0}%',
              user['active_jobs'] ?? 0,
              'RWF ${user['total_earnings'] ?? 0}',
            ]),
      ];

      return await _createCSVFile(csvData, 'users_export');
    } catch (e) {
      print('Error exporting users: $e');
      return null;
    }
  }

  /// Export hiring requests data to CSV
  static Future<String?> exportHiringRequestsToCSV({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final data = await _getHiringRequestsData(
        status: status,
        startDate: startDate,
        endDate: endDate,
      );

      final csvData = [
        // Headers
        [
          'ID',
          'Household Name',
          'Worker Name',
          'Service Type',
          'Status',
          'Start Date',
          'End Date',
          'Hourly Rate',
          'Total Hours',
          'Total Amount',
          'Created At',
          'Location'
        ],
        // Data rows
        ...data.map((request) => [
              request['id'] ?? '',
              request['household_name'] ?? '',
              request['worker_name'] ?? '',
              request['service_type'] ?? '',
              request['status'] ?? '',
              request['start_date'] ?? '',
              request['end_date'] ?? '',
              'RWF ${request['hourly_rate'] ?? 0}',
              '${request['total_hours'] ?? 0}h',
              'RWF ${request['total_amount'] ?? 0}',
              request['created_at'] ?? '',
              request['location'] ?? '',
            ]),
      ];

      return await _createCSVFile(csvData, 'hiring_requests_export');
    } catch (e) {
      print('Error exporting hiring requests: $e');
      return null;
    }
  }

  /// Export payments data to CSV
  static Future<String?> exportPaymentsToCSV({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final data = await _getPaymentsData(
        status: status,
        startDate: startDate,
        endDate: endDate,
      );

      final csvData = [
        // Headers
        [
          'ID',
          'Transaction ID',
          'Payer Name',
          'Receiver Name',
          'Amount',
          'Fee',
          'Net Amount',
          'Status',
          'Payment Method',
          'Purpose',
          'Created At',
          'Completed At'
        ],
        // Data rows
        ...data.map((payment) => [
              payment['id'] ?? '',
              payment['transaction_id'] ?? '',
              payment['payer_name'] ?? '',
              payment['receiver_name'] ?? '',
              'RWF ${payment['amount'] ?? 0}',
              'RWF ${payment['fee'] ?? 0}',
              'RWF ${payment['net_amount'] ?? 0}',
              payment['status'] ?? '',
              payment['payment_method'] ?? '',
              payment['purpose'] ?? '',
              payment['created_at'] ?? '',
              payment['completed_at'] ?? '',
            ]),
      ];

      return await _createCSVFile(csvData, 'payments_export');
    } catch (e) {
      print('Error exporting payments: $e');
      return null;
    }
  }

  /// Export training data to CSV
  static Future<String?> exportTrainingToCSV({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final data = await _getTrainingData(
        status: status,
        startDate: startDate,
        endDate: endDate,
      );

      final csvData = [
        // Headers
        [
          'ID',
          'Worker Name',
          'Training Title',
          'Category',
          'Status',
          'Progress',
          'Score',
          'Started At',
          'Completed At',
          'Certificate ID',
          'Instructor'
        ],
        // Data rows
        ...data.map((training) => [
              training['id'] ?? '',
              training['worker_name'] ?? '',
              training['title'] ?? '',
              training['category'] ?? '',
              training['status'] ?? '',
              '${training['progress'] ?? 0}%',
              '${training['score'] ?? 0}%',
              training['started_at'] ?? '',
              training['completed_at'] ?? '',
              training['certificate_id'] ?? '',
              training['instructor'] ?? '',
            ]),
      ];

      return await _createCSVFile(csvData, 'training_export');
    } catch (e) {
      print('Error exporting training: $e');
      return null;
    }
  }

  /// Export behavior reports to CSV
  static Future<String?> exportBehaviorReportsToCSV({
    String? severity,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final data = await _getBehaviorReportsData(
        severity: severity,
        startDate: startDate,
        endDate: endDate,
      );

      final csvData = [
        // Headers
        [
          'ID',
          'Reporter Name',
          'Reported User',
          'Type',
          'Severity',
          'Status',
          'Description',
          'Action Taken',
          'Created At',
          'Resolved At'
        ],
        // Data rows
        ...data.map((report) => [
              report['id'] ?? '',
              report['reporter_name'] ?? '',
              report['reported_user_name'] ?? '',
              report['type'] ?? '',
              report['severity'] ?? '',
              report['status'] ?? '',
              report['description'] ?? '',
              report['action_taken'] ?? '',
              report['created_at'] ?? '',
              report['resolved_at'] ?? '',
            ]),
      ];

      return await _createCSVFile(csvData, 'behavior_reports_export');
    } catch (e) {
      print('Error exporting behavior reports: $e');
      return null;
    }
  }

  /// Export emergency reports to CSV
  static Future<String?> exportEmergencyReportsToCSV({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final data = await _getEmergencyReportsData(
        status: status,
        startDate: startDate,
        endDate: endDate,
      );

      final csvData = [
        // Headers
        [
          'ID',
          'Reporter Name',
          'Reporter Role',
          'Emergency Type',
          'Status',
          'Contact Used',
          'Location',
          'Description',
          'Admin Notes',
          'Reported At',
          'Reviewed At'
        ],
        // Data rows
        ...data.map((report) => [
              report['id'] ?? '',
              report['reporter_name'] ?? '',
              report['user_role'] ?? '',
              report['emergency_type'] ?? '',
              report['status'] ?? '',
              report['contact_used'] ?? '',
              report['location'] ?? '',
              report['description'] ?? '',
              report['admin_notes'] ?? '',
              report['reported_at'] ?? '',
              report['reviewed_at'] ?? '',
            ]),
      ];

      return await _createCSVFile(csvData, 'emergency_reports_export');
    } catch (e) {
      print('Error exporting emergency reports: $e');
      return null;
    }
  }

  /// Generate comprehensive system report
  static Future<Map<String, dynamic>> generateSystemReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final reportData = <String, dynamic>{};

      // User statistics
      final users = await _getUsersData(startDate: startDate, endDate: endDate);
      reportData['users'] = {
        'total': users.length,
        'by_role': _groupByRole(users),
        'verified':
            users.where((u) => u['verification_status'] == 'verified').length,
        'active_this_period': users
            .where((u) =>
                _isActivePeriod(u['last_sign_in_at'], startDate, endDate))
            .length,
      };

      // Hiring statistics
      final hiringRequests =
          await _getHiringRequestsData(startDate: startDate, endDate: endDate);
      reportData['hiring'] = {
        'total_requests': hiringRequests.length,
        'by_status': _groupByField(hiringRequests, 'status'),
        'total_value': _sumField(hiringRequests, 'total_amount'),
        'avg_hourly_rate': _averageField(hiringRequests, 'hourly_rate'),
      };

      // Payment statistics
      final payments =
          await _getPaymentsData(startDate: startDate, endDate: endDate);
      reportData['payments'] = {
        'total_transactions': payments.length,
        'total_amount': _sumField(payments, 'amount'),
        'total_fees': _sumField(payments, 'fee'),
        'by_status': _groupByField(payments, 'status'),
        'by_method': _groupByField(payments, 'payment_method'),
      };

      // Training statistics
      final training =
          await _getTrainingData(startDate: startDate, endDate: endDate);
      reportData['training'] = {
        'total_enrollments': training.length,
        'completed': training.where((t) => t['status'] == 'completed').length,
        'avg_score': _averageField(
            training.where((t) => t['status'] == 'completed').toList(),
            'score'),
        'by_category': _groupByField(training, 'category'),
      };

      // Behavior reports
      final behaviorReports =
          await _getBehaviorReportsData(startDate: startDate, endDate: endDate);
      reportData['behavior_reports'] = {
        'total': behaviorReports.length,
        'by_severity': _groupByField(behaviorReports, 'severity'),
        'resolved':
            behaviorReports.where((r) => r['status'] == 'resolved').length,
        'pending':
            behaviorReports.where((r) => r['status'] == 'pending').length,
      };

      // Emergency reports
      final emergencyReports = await _getEmergencyReportsData(
          startDate: startDate, endDate: endDate);
      reportData['emergency_reports'] = {
        'total': emergencyReports.length,
        'by_type': _groupByField(emergencyReports, 'emergency_type'),
        'resolved':
            emergencyReports.where((r) => r['status'] == 'resolved').length,
        'pending':
            emergencyReports.where((r) => r['status'] == 'submitted').length,
      };

      reportData['report_generated_at'] = DateTime.now().toIso8601String();
      reportData['period_start'] = startDate?.toIso8601String();
      reportData['period_end'] = endDate?.toIso8601String();

      return reportData;
    } catch (e) {
      print('Error generating system report: $e');
      return {};
    }
  }

  /// Export system report to JSON file
  static Future<String?> exportSystemReportToJSON({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final reportData = await generateSystemReport(
        startDate: startDate,
        endDate: endDate,
      );

      final jsonString = const JsonEncoder.withIndent('  ').convert(reportData);

      return await _createTextFile(jsonString, 'system_report', 'json');
    } catch (e) {
      print('Error exporting system report: $e');
      return null;
    }
  }

  /// Share exported file
  static Future<void> shareFile(String filePath, String title) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: title,
      );
    } catch (e) {
      print('Error sharing file: $e');
    }
  }

  // Private helper methods

  static Future<List<Map<String, dynamic>>> _getUsersData({
    String? role,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final filters = <String, dynamic>{};
    if (role != null) filters['role'] = role;

    final data = await SupabaseService.read(
      table: 'profiles',
      filters: filters.isEmpty ? null : filters,
      orderBy: 'created_at',
      ascending: false,
    );

    return data.where((user) {
      if (startDate != null && endDate != null) {
        final createdAt = DateTime.tryParse(user['created_at'] ?? '');
        if (createdAt != null) {
          return createdAt.isAfter(startDate) && createdAt.isBefore(endDate);
        }
      }
      return true;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> _getHiringRequestsData({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final filters = <String, dynamic>{};
    if (status != null) filters['status'] = status;

    final data = await SupabaseService.read(
      table: 'hiring_requests',
      filters: filters.isEmpty ? null : filters,
      orderBy: 'created_at',
      ascending: false,
    );

    return data.where((request) {
      if (startDate != null && endDate != null) {
        final createdAt = DateTime.tryParse(request['created_at'] ?? '');
        if (createdAt != null) {
          return createdAt.isAfter(startDate) && createdAt.isBefore(endDate);
        }
      }
      return true;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> _getPaymentsData({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final filters = <String, dynamic>{};
    if (status != null) filters['status'] = status;

    final data = await SupabaseService.read(
      table: 'payments',
      filters: filters.isEmpty ? null : filters,
      orderBy: 'created_at',
      ascending: false,
    );

    return data.where((payment) {
      if (startDate != null && endDate != null) {
        final createdAt = DateTime.tryParse(payment['created_at'] ?? '');
        if (createdAt != null) {
          return createdAt.isAfter(startDate) && createdAt.isBefore(endDate);
        }
      }
      return true;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> _getTrainingData({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final filters = <String, dynamic>{};
    if (status != null) filters['status'] = status;

    final data = await SupabaseService.read(
      table: 'training_enrollments',
      filters: filters.isEmpty ? null : filters,
      orderBy: 'started_at',
      ascending: false,
    );

    return data.where((training) {
      if (startDate != null && endDate != null) {
        final startedAt = DateTime.tryParse(training['started_at'] ?? '');
        if (startedAt != null) {
          return startedAt.isAfter(startDate) && startedAt.isBefore(endDate);
        }
      }
      return true;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> _getBehaviorReportsData({
    String? severity,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final filters = <String, dynamic>{};
    if (severity != null) filters['severity'] = severity;

    final data = await SupabaseService.read(
      table: 'behavior_reports',
      filters: filters.isEmpty ? null : filters,
      orderBy: 'created_at',
      ascending: false,
    );

    return data.where((report) {
      if (startDate != null && endDate != null) {
        final createdAt = DateTime.tryParse(report['created_at'] ?? '');
        if (createdAt != null) {
          return createdAt.isAfter(startDate) && createdAt.isBefore(endDate);
        }
      }
      return true;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> _getEmergencyReportsData({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final filters = <String, dynamic>{};
    if (status != null) filters['status'] = status;

    final data = await SupabaseService.read(
      table: 'emergency_reports',
      filters: filters.isEmpty ? null : filters,
      orderBy: 'reported_at',
      ascending: false,
    );

    return data.where((report) {
      if (startDate != null && endDate != null) {
        final reportedAt = DateTime.tryParse(report['reported_at'] ?? '');
        if (reportedAt != null) {
          return reportedAt.isAfter(startDate) && reportedAt.isBefore(endDate);
        }
      }
      return true;
    }).toList();
  }

  static Future<String> _createCSVFile(
      List<List<dynamic>> csvData, String fileName) async {
    final csv = const ListToCsvConverter().convert(csvData);
    return await _createTextFile(csv, fileName, 'csv');
  }

  static Future<String> _createTextFile(
      String content, String fileName, String extension) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/${fileName}_$timestamp.$extension');

    await file.writeAsString(content);
    return file.path;
  }

  static Map<String, int> _groupByRole(List<Map<String, dynamic>> data) {
    final grouped = <String, int>{};
    for (final item in data) {
      final role = item['role'] ?? 'unknown';
      grouped[role] = (grouped[role] ?? 0) + 1;
    }
    return grouped;
  }

  static Map<String, int> _groupByField(
      List<Map<String, dynamic>> data, String field) {
    final grouped = <String, int>{};
    for (final item in data) {
      final value = item[field]?.toString() ?? 'unknown';
      grouped[value] = (grouped[value] ?? 0) + 1;
    }
    return grouped;
  }

  static double _sumField(List<Map<String, dynamic>> data, String field) {
    double sum = 0;
    for (final item in data) {
      final value = item[field];
      if (value is num) {
        sum += value.toDouble();
      }
    }
    return sum;
  }

  static double _averageField(List<Map<String, dynamic>> data, String field) {
    if (data.isEmpty) return 0;
    return _sumField(data, field) / data.length;
  }

  static bool _isActivePeriod(
      String? lastSignIn, DateTime? startDate, DateTime? endDate) {
    if (lastSignIn == null || startDate == null || endDate == null) {
      return false;
    }
    final signInDate = DateTime.tryParse(lastSignIn);
    if (signInDate == null) return false;
    return signInDate.isAfter(startDate) && signInDate.isBefore(endDate);
  }
}
