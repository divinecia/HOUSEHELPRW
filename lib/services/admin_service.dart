import '../models/admin_models.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  // Behavior Reports

  static Future<List<BehaviorReport>> getAllBehaviorReports({
    String? orderBy,
    bool ascending = false,
    int? limit,
    ReportStatus? statusFilter,
  }) async {
    try {
      Map<String, dynamic>? filters;
      if (statusFilter != null) {
        filters = {'status': statusFilter.toString().split('.').last};
      }

      final data = await SupabaseService.read(
        table: 'behavior_reports',
        orderBy: orderBy ?? 'reported_at',
        ascending: ascending,
        limit: limit,
        filters: filters,
      );

      return data.map((json) => BehaviorReport.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching behavior reports: $e');
      rethrow;
    }
  }

  static Future<BehaviorReport?> getBehaviorReportById(String id) async {
    try {
      final data = await SupabaseService.read(
        table: 'behavior_reports',
        filters: {'id': id},
        limit: 1,
      );

      if (data.isNotEmpty) {
        return BehaviorReport.fromJson(data.first);
      }
      return null;
    } catch (e) {
      print('Error fetching behavior report: $e');
      rethrow;
    }
  }

  static Future<BehaviorReport> createBehaviorReport(
      BehaviorReport report) async {
    try {
      final data = await SupabaseService.create(
        table: 'behavior_reports',
        data: report.toJson()..remove('id'),
      );

      if (data != null) {
        return BehaviorReport.fromJson(data);
      }
      throw Exception('Failed to create behavior report');
    } catch (e) {
      print('Error creating behavior report: $e');
      rethrow;
    }
  }

  static Future<BehaviorReport> updateBehaviorReport({
    required String id,
    ReportStatus? status,
    String? adminNotes,
    String? resolvedBy,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (status != null) {
        updateData['status'] = status.toString().split('.').last;
        if (status == ReportStatus.resolved) {
          updateData['resolved_at'] = DateTime.now().toIso8601String();
          updateData['resolved_by'] = resolvedBy;
        }
      }

      if (adminNotes != null) {
        updateData['admin_notes'] = adminNotes;
      }

      final data = await SupabaseService.update(
        table: 'behavior_reports',
        id: id,
        data: updateData,
      );

      if (data != null) {
        return BehaviorReport.fromJson(data);
      }
      throw Exception('Failed to update behavior report');
    } catch (e) {
      print('Error updating behavior report: $e');
      rethrow;
    }
  }

  static Future<bool> sendReportToIsange(String reportId) async {
    try {
      // This would typically call a Supabase Edge Function to send email
      final client = Supabase.instance.client;

      await client.functions.invoke(
        'send-report-to-isange',
        body: {'reportId': reportId},
      );

      // Update the report to mark email as sent
      await SupabaseService.update(
        table: 'behavior_reports',
        id: reportId,
        data: {
          'email_sent_to_isange': true,
          'email_sent_at': DateTime.now().toIso8601String(),
        },
      );

      return true;
    } catch (e) {
      print('Error sending report to Isange: $e');
      return false;
    }
  }

  // Fix Messages

  static Future<List<FixMessage>> getAllFixMessages({
    String? orderBy,
    bool ascending = false,
    int? limit,
    FixMessageStatus? statusFilter,
    FixMessagePriority? priorityFilter,
  }) async {
    try {
      Map<String, dynamic>? filters;

      if (statusFilter != null || priorityFilter != null) {
        filters = {};
        if (statusFilter != null) {
          filters['status'] = statusFilter.toString().split('.').last;
        }
        if (priorityFilter != null) {
          filters['priority'] = priorityFilter.toString().split('.').last;
        }
      }

      final data = await SupabaseService.read(
        table: 'fix_messages',
        orderBy: orderBy ?? 'reported_at',
        ascending: ascending,
        limit: limit,
        filters: filters,
      );

      return data.map((json) => FixMessage.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching fix messages: $e');
      rethrow;
    }
  }

  static Future<FixMessage?> getFixMessageById(String id) async {
    try {
      final data = await SupabaseService.read(
        table: 'fix_messages',
        filters: {'id': id},
        limit: 1,
      );

      if (data.isNotEmpty) {
        return FixMessage.fromJson(data.first);
      }
      return null;
    } catch (e) {
      print('Error fetching fix message: $e');
      rethrow;
    }
  }

  static Future<FixMessage> createFixMessage(FixMessage fixMessage) async {
    try {
      final data = await SupabaseService.create(
        table: 'fix_messages',
        data: fixMessage.toJson()..remove('id'),
      );

      if (data != null) {
        return FixMessage.fromJson(data);
      }
      throw Exception('Failed to create fix message');
    } catch (e) {
      print('Error creating fix message: $e');
      rethrow;
    }
  }

  static Future<FixMessage> updateFixMessage({
    required String id,
    FixMessageStatus? status,
    String? assignedTo,
    String? adminNotes,
    String? resolution,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (status != null) {
        updateData['status'] = status.toString().split('.').last;
        if (status == FixMessageStatus.resolved) {
          updateData['resolved_at'] = DateTime.now().toIso8601String();
          if (resolution != null) {
            updateData['resolution'] = resolution;
          }
        }
      }

      if (assignedTo != null) {
        updateData['assigned_to'] = assignedTo;
        updateData['assigned_at'] = DateTime.now().toIso8601String();
      }

      if (adminNotes != null) {
        updateData['admin_notes'] = adminNotes;
      }

      final data = await SupabaseService.update(
        table: 'fix_messages',
        id: id,
        data: updateData,
      );

      if (data != null) {
        return FixMessage.fromJson(data);
      }
      throw Exception('Failed to update fix message');
    } catch (e) {
      print('Error updating fix message: $e');
      rethrow;
    }
  }

  // Analytics

  static Future<Map<String, dynamic>> getAdminAnalytics() async {
    try {
      final client = Supabase.instance.client;

      // Get total users by role
      final totalUsers =
          await client.from('profiles').select().then((data) => data.length);

      final workers = await client
          .from('profiles')
          .select()
          .eq('role', 'house_helper')
          .then((data) => data.length);

      final households = await client
          .from('profiles')
          .select()
          .eq('role', 'house_holder')
          .then((data) => data.length);

      // Get active hiring requests
      final activeRequests = await client
          .from('hire_requests')
          .select()
          .eq('status', 'pending')
          .then((data) => data.length);

      // Get behavior reports
      final pendingReports = await client
          .from('behavior_reports')
          .select()
          .eq('status', 'pending')
          .then((data) => data.length);

      // Get fix messages
      final pendingFixMessages = await client
          .from('fix_messages')
          .select()
          .eq('status', 'pending')
          .then((data) => data.length);

      // Get payments (basic count)
      final totalPayments =
          await client.from('payments').select().then((data) => data.length);

      final servicePayments = await client
          .from('payments')
          .select()
          .eq('payment_type', 'service')
          .then((data) => data.length);

      final trainingPayments = await client
          .from('payments')
          .select()
          .eq('payment_type', 'training')
          .then((data) => data.length);

      return {
        'totalUsers': totalUsers,
        'workers': workers,
        'households': households,
        'activeRequests': activeRequests,
        'pendingReports': pendingReports,
        'pendingFixMessages': pendingFixMessages,
        'totalPayments': totalPayments,
        'servicePayments': servicePayments,
        'trainingPayments': trainingPayments,
      };
    } catch (e) {
      print('Error fetching admin analytics: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getRevenueAnalytics() async {
    try {
      final client = Supabase.instance.client;

      // This would typically call a database function for aggregated revenue data
      final response = await client.rpc('get_revenue_analytics');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching revenue analytics: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getServiceRequestStats() async {
    try {
      final client = Supabase.instance.client;

      final response =
          await client.from('hire_requests').select('service_type');

      final Map<String, int> serviceCount = {};
      for (var item in response) {
        final service = item['service_type'] as String? ?? 'Unknown';
        serviceCount[service] = (serviceCount[service] ?? 0) + 1;
      }

      return serviceCount.entries
          .map((e) => {'service': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    } catch (e) {
      print('Error fetching service request stats: $e');
      return [];
    }
  }

  // System Settings

  static Future<SystemSettings?> getSystemSettings() async {
    try {
      final data = await SupabaseService.read(
        table: 'system_settings',
        limit: 1,
        orderBy: 'updated_at',
        ascending: false,
      );

      if (data.isNotEmpty) {
        return SystemSettings.fromJson(data.first);
      }

      // Return default settings if none exist
      return SystemSettings(
        id: null,
        defaultLanguage: 'en',
        taxRate: 0.18,
        serviceFeePercentage: 0.05,
        benefitsOptions: {
          'health_insurance': true,
          'transport_allowance': false,
          'meal_allowance': true,
        },
        notificationSettings: {
          'email_enabled': true,
          'push_enabled': true,
          'sms_enabled': false,
          'emergency_alerts': true,
        },
        paymentSettings: {
          'paypack_enabled': true,
          'mobile_money_enabled': true,
          'bank_transfer_enabled': false,
          'minimum_amount': 1000,
        },
        lastUpdated: DateTime.now(),
        updatedBy: 'system',
      );
    } catch (e) {
      print('Error fetching system settings: $e');
      // Return default settings on error
      return SystemSettings(
        id: null,
        defaultLanguage: 'en',
        taxRate: 0.18,
        serviceFeePercentage: 0.05,
        benefitsOptions: {
          'health_insurance': true,
          'transport_allowance': false,
          'meal_allowance': true,
        },
        notificationSettings: {
          'email_enabled': true,
          'push_enabled': true,
          'sms_enabled': false,
          'emergency_alerts': true,
        },
        paymentSettings: {
          'paypack_enabled': true,
          'mobile_money_enabled': true,
          'bank_transfer_enabled': false,
          'minimum_amount': 1000,
        },
        lastUpdated: DateTime.now(),
        updatedBy: 'system',
      );
    }
  }

  static Future<SystemSettings> updateSystemSettings(
      SystemSettings settings) async {
    try {
      final data = await SupabaseService.update(
        table: 'system_settings',
        id: settings.id!,
        data: settings.toJson()
          ..['last_updated'] = DateTime.now().toIso8601String(),
      );

      if (data != null) {
        return SystemSettings.fromJson(data);
      }
      throw Exception('Failed to update system settings');
    } catch (e) {
      print('Error updating system settings: $e');
      rethrow;
    }
  }

  // Notification management

  static Future<bool> sendNotificationToUsers({
    required String title,
    required String message,
    List<String>? userIds,
    String? userRole,
  }) async {
    try {
      final client = Supabase.instance.client;

      await client.functions.invoke(
        'send-notification',
        body: {
          'title': title,
          'message': message,
          'userIds': userIds,
          'userRole': userRole,
        },
      );

      return true;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // Training Suggestions Management

  static Future<List<Map<String, dynamic>>> getAllTrainingSuggestions({
    String? orderBy,
    bool ascending = false,
    int? limit,
    String? statusFilter,
  }) async {
    try {
      Map<String, dynamic>? filters;
      if (statusFilter != null) {
        filters = {'status': statusFilter};
      }

      final data = await SupabaseService.read(
        table: 'training_suggestions',
        orderBy: orderBy ?? 'created_at',
        ascending: ascending,
        limit: limit,
        filters: filters,
      );

      return data;
    } catch (e) {
      print('Error fetching training suggestions: $e');
      return [];
    }
  }

  static Future<bool> processTrainingSuggestion({
    required String suggestionId,
    required String status, // 'approved', 'rejected'
    String? adminNotes,
    String? processedBy,
  }) async {
    try {
      final updateData = {
        'status': status,
        'processed_at': DateTime.now().toIso8601String(),
        'processed_by': processedBy,
        'admin_notes': adminNotes,
      };

      await SupabaseService.update(
        table: 'training_suggestions',
        id: suggestionId,
        data: updateData,
      );

      // If approved, enroll worker in training
      if (status == 'approved') {
        final suggestion = await SupabaseService.read(
          table: 'training_suggestions',
          filters: {'id': suggestionId},
          limit: 1,
        );

        if (suggestion.isNotEmpty) {
          final suggestionData = suggestion.first;

          // Create training enrollment
          await SupabaseService.create(
            table: 'training_enrollments',
            data: {
              'worker_id': suggestionData['worker_id'],
              'training_id': suggestionData['training_id'],
              'enrollment_type': 'admin_suggested',
              'suggested_by_household_id':
                  suggestionData['suggested_by_household_id'],
              'enrolled_at': DateTime.now().toIso8601String(),
              'status': 'enrolled',
            },
          );

          // Notify worker about approval
          await sendNotificationToUsers(
            title: 'Training Approved!',
            message:
                'You have been enrolled in ${suggestionData['training_title']} training',
            userIds: [suggestionData['worker_id']],
          );

          // Notify household about approval
          await sendNotificationToUsers(
            title: 'Training Suggestion Approved',
            message:
                'Your suggestion for ${suggestionData['worker_name']} has been approved',
            userIds: [suggestionData['suggested_by_household_id']],
          );
        }
      }

      return true;
    } catch (e) {
      print('Error processing training suggestion: $e');
      return false;
    }
  }

  static Future<bool> createWorkerTrainingSuggestion({
    required String workerId,
    required String workerName,
    required String trainingId,
    required String trainingTitle,
    required String suggestedByAdminId,
    required String suggestedByAdminName,
    String? notes,
  }) async {
    try {
      await SupabaseService.create(
        table: 'training_suggestions',
        data: {
          'worker_id': workerId,
          'worker_name': workerName,
          'training_id': trainingId,
          'training_title': trainingTitle,
          'suggested_by_admin_id': suggestedByAdminId,
          'suggested_by_admin_name': suggestedByAdminName,
          'notes': notes,
          'status': 'admin_suggested',
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      // Notify worker
      await sendNotificationToUsers(
        title: 'Training Recommendation',
        message: 'Admin recommended you for "$trainingTitle" training',
        userIds: [workerId],
      );

      return true;
    } catch (e) {
      print('Error creating training suggestion: $e');
      return false;
    }
  }
}
