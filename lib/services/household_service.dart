import '../models/hire_request.dart';
import '../models/admin_models.dart';
import '../services/supabase_service.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';

class HouseholdService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const _uuid = Uuid();

  // Find and Filter Workers
  static Future<List<Map<String, dynamic>>> findWorkers({
    String? district,
    String? serviceType,
    double? maxHourlyRate,
    double? minRating,
    bool? isVerified,
    bool? isAvailable,
    String? sortBy, // 'newest', 'cheapest', 'nearest', 'rating', 'last_hired'
    bool? urgentBooking,
  }) async {
    try {
      // Build the base query
      var queryBuilder = _supabase.from('profiles').select('''
        id, full_name, phone_number, district, hourly_rate, rating, 
        is_verified, is_available, profile_picture_url, services_offered,
        created_at, last_active, location_latitude, location_longitude,
        total_jobs_completed, experience_years, languages_spoken
      ''').eq('role', 'house_helper');

      // Apply filters
      if (district != null) {
        queryBuilder = queryBuilder.eq('district', district);
      }

      if (isVerified != null && isVerified) {
        queryBuilder = queryBuilder.eq('is_verified', true);
      }

      if (isAvailable != null && isAvailable) {
        queryBuilder = queryBuilder.eq('is_available', true);
      }

      if (maxHourlyRate != null) {
        queryBuilder = queryBuilder.lte('hourly_rate', maxHourlyRate);
      }

      if (minRating != null) {
        queryBuilder = queryBuilder.gte('rating', minRating);
      }

      // Apply sorting and execute query
      List<Map<String, dynamic>> response;
      switch (sortBy) {
        case 'newest':
          response = await queryBuilder.order('created_at', ascending: false);
          break;
        case 'cheapest':
          response = await queryBuilder.order('hourly_rate', ascending: true);
          break;
        case 'rating':
          response = await queryBuilder.order('rating', ascending: false);
          break;
        case 'last_hired':
          response = await queryBuilder.order('last_active', ascending: false);
          break;
        default:
          response = await queryBuilder.order('rating', ascending: false);
      }

      // If urgent booking, filter for premium workers
      if (urgentBooking == true) {
        return response
            .where((worker) =>
                worker['is_verified'] == true &&
                (worker['rating'] ?? 0.0) >= 4.0)
            .toList();
      }

      return response;
    } catch (e) {
      print('Error finding workers: $e');
      rethrow;
    }
  }

  // Create Hire Request
  static Future<HireRequest> createHireRequest({
    required String helperId,
    required String helperName,
    required String employerId,
    required String employerName,
    required String serviceType,
    required String description,
    required DateTime startDate,
    DateTime? endDate,
    required double hourlyRate,
    required int estimatedHours,
    required String location,
    required String workAddress,
    required String startTime,
    required int hoursPerDay,
    required List<String> activities,
    required String helperPhone,
    required String employerPhone,
    String? notes,
    String? preferredArrivalWindow,
    bool isUrgent = false,
  }) async {
    try {
      final totalAmount = hourlyRate *
          estimatedHours *
          (isUrgent ? 1.2 : 1.0); // 20% premium for urgent

      final hireRequest = HireRequest(
        id: _uuid.v4(),
        helperUid: helperId,
        helperName: helperName,
        employerUid: employerId,
        employerName: employerName,
        serviceType: serviceType,
        description: description,
        startDate: startDate,
        endDate: endDate,
        hourlyRate: hourlyRate,
        estimatedHours: estimatedHours,
        totalAmount: totalAmount,
        status: HireStatus.pending,
        location: location,
        createdAt: DateTime.now(),
        notes: notes,
        startTime: startTime,
        hoursPerDay: hoursPerDay,
        activities: activities,
        workAddress: workAddress,
        helperPhone: helperPhone,
        employerPhone: employerPhone,
      );

      // Save to database
      await SupabaseService.create(
        table: 'hire_requests',
        data: hireRequest.toMap(),
      );

      // Send notification to helper
      await NotificationService.sendPushNotification(
        title: 'New Job Request',
        message: 'You have a new job request from $employerName',
        userIds: [helperId],
        data: {
          'type': 'hire_request',
          'request_id': hireRequest.id,
          'is_urgent': isUrgent.toString(),
        },
      );

      return hireRequest;
    } catch (e) {
      print('Error creating hire request: $e');
      rethrow;
    }
  }

  // Get Household's Hire Requests
  static Future<List<HireRequest>> getHouseholdHireRequests(
      String employerId) async {
    try {
      final data = await SupabaseService.read(
        table: 'hire_requests',
        filters: {'employer_uid': employerId},
        orderBy: 'created_at',
        ascending: false,
      );

      return data.map((json) => HireRequest.fromMap(json)).toList();
    } catch (e) {
      print('Error fetching hire requests: $e');
      rethrow;
    }
  }

  // Track Worker ETA and Location
  static Future<Map<String, dynamic>?> getWorkerETA(
      String workerId, String requestId) async {
    try {
      final response = await _supabase.from('worker_locations').select('''
        latitude, longitude, last_updated, eta_minutes, is_on_route, 
        estimated_arrival_time
      ''').eq('worker_id', workerId).eq('hire_request_id', requestId).single();

      return response;
    } catch (e) {
      print('Error getting worker ETA: $e');
      return null;
    }
  }

  // Update Worker Location (called by worker)
  static Future<bool> updateWorkerLocation({
    required String workerId,
    required String requestId,
    required double latitude,
    required double longitude,
    int? etaMinutes,
    bool? isOnRoute,
    DateTime? estimatedArrivalTime,
  }) async {
    try {
      await _supabase.from('worker_locations').upsert({
        'worker_id': workerId,
        'hire_request_id': requestId,
        'latitude': latitude,
        'longitude': longitude,
        'last_updated': DateTime.now().toIso8601String(),
        'eta_minutes': etaMinutes,
        'is_on_route': isOnRoute ?? false,
        'estimated_arrival_time': estimatedArrivalTime?.toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error updating worker location: $e');
      return false;
    }
  }

  // Confirm Worker Arrival
  static Future<bool> confirmWorkerArrival(
      String requestId, String workerId) async {
    try {
      // Update hire request status
      await SupabaseService.update(
        table: 'hire_requests',
        id: requestId,
        data: {
          'status': HireStatus.ongoing.toString().split('.').last,
          'actual_start_time': DateTime.now().toIso8601String(),
        },
      );

      // Notify household
      final request = await SupabaseService.read(
        table: 'hire_requests',
        filters: {'id': requestId},
        limit: 1,
      );

      if (request.isNotEmpty) {
        await NotificationService.sendPushNotification(
          title: 'Worker Arrived',
          message:
              '${request.first['helper_name']} has arrived at your location',
          userIds: [request.first['employer_uid']],
        );
      }

      return true;
    } catch (e) {
      print('Error confirming worker arrival: $e');
      return false;
    }
  }

  // Submit Behavior Report
  static Future<bool> submitBehaviorReport({
    required String reportedWorkerId,
    required String reportedWorkerName,
    required String reporterHouseholdId,
    required String reporterHouseholdName,
    required String incidentDescription,
    required String severity, // 'low', 'medium', 'high', 'critical'
    required DateTime incidentDate,
    required String location,
    List<String>? evidenceUrls,
  }) async {
    try {
      final reportId = _uuid.v4();

      // Create behavior report
      await SupabaseService.create(
        table: 'behavior_reports',
        data: {
          'id': reportId,
          'reported_worker_id': reportedWorkerId,
          'reported_worker_name': reportedWorkerName,
          'reporter_household_id': reporterHouseholdId,
          'reporter_household_name': reporterHouseholdName,
          'incident_description': incidentDescription,
          'severity': severity,
          'incident_date': incidentDate.toIso8601String(),
          'location': location,
          'evidence_urls': evidenceUrls,
          'status': 'pending',
          'reported_at': DateTime.now().toIso8601String(),
        },
      );

      // Send email to Isange One Stop Center
      // First create the BehaviorReport object for the notification
      final behaviorReport = BehaviorReport(
        id: reportId,
        reportedWorkerId: reportedWorkerId,
        reportedWorkerName: reportedWorkerName,
        reporterHouseholdId: reporterHouseholdId,
        reporterHouseholdName: reporterHouseholdName,
        incidentDescription: incidentDescription,
        severity: ReportSeverity.values.firstWhere(
          (e) => e.toString().split('.').last == severity,
          orElse: () => ReportSeverity.medium,
        ),
        incidentDate: incidentDate,
        location: location,
        evidenceUrls: evidenceUrls,
        reportedAt: DateTime.now(),
      );

      await NotificationService.sendBehaviorReportToIsange(
        behaviorReport,
        'admin@househelprw.com', // Admin email
      );

      return true;
    } catch (e) {
      print('Error submitting behavior report: $e');
      return false;
    }
  }

  // Get Household's Behavior Reports
  static Future<List<Map<String, dynamic>>> getHouseholdBehaviorReports(
      String householdId) async {
    try {
      final data = await SupabaseService.read(
        table: 'behavior_reports',
        filters: {'reporter_household_id': householdId},
        orderBy: 'reported_at',
        ascending: false,
      );

      return data;
    } catch (e) {
      print('Error fetching behavior reports: $e');
      rethrow;
    }
  }

  // Submit Fix Message (Bug/Improvement Report)
  static Future<bool> submitFixMessage({
    required String reporterId,
    required String reporterName,
    required String title,
    required String description,
    required String type, // 'bug', 'featureRequest', 'improvement', 'question'
    String priority = 'medium',
    List<String>? attachments,
  }) async {
    try {
      await SupabaseService.create(
        table: 'fix_messages',
        data: {
          'id': _uuid.v4(),
          'reporter_id': reporterId,
          'reporter_name': reporterName,
          'reporter_role': 'house_holder',
          'title': title,
          'description': description,
          'type': type,
          'priority': priority,
          'status': 'pending',
          'reported_at': DateTime.now().toIso8601String(),
          'attachments': attachments,
        },
      );

      return true;
    } catch (e) {
      print('Error submitting fix message: $e');
      return false;
    }
  }

  // Get Payment History
  static Future<List<Map<String, dynamic>>> getPaymentHistory({
    required String householdId,
    DateTime? fromDate,
    DateTime? toDate,
    String? paymentType, // 'service', 'training'
    String? workerId,
  }) async {
    try {
      var query = _supabase.from('payments').select('''
        id, amount, currency, status, payment_method, description,
        created_at, completed_at, house_helper_id, hire_request_id,
        payment_type, transaction_id
      ''').eq('house_holder_id', householdId);

      if (fromDate != null) {
        query = query.gte('created_at', fromDate.toIso8601String());
      }

      if (toDate != null) {
        query = query.lte('created_at', toDate.toIso8601String());
      }

      if (paymentType != null) {
        query = query.eq('payment_type', paymentType);
      }

      if (workerId != null) {
        query = query.eq('house_helper_id', workerId);
      }

      final response = await query.order('created_at', ascending: false);
      return response;
    } catch (e) {
      print('Error fetching payment history: $e');
      rethrow;
    }
  }

  // Process Payment for Service
  static Future<bool> processServicePayment({
    required String hireRequestId,
    required String householdId,
    required String workerId,
    required double amount,
    required String phoneNumber,
    String? description,
  }) async {
    try {
      final payment = await PaymentService.initiateHirePayment(
        amount: amount,
        phoneNumber: phoneNumber,
        hireRequestId: hireRequestId,
        houseHelperId: workerId,
        houseHolderId: householdId,
        description: description ?? 'Payment for house helper services',
      );

      return payment != null;
    } catch (e) {
      print('Error processing service payment: $e');
      return false;
    }
  }

  // Schedule Job with Worker Availability
  static Future<List<Map<String, dynamic>>> getWorkerAvailability(
      String workerId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _supabase
          .from('worker_availability')
          .select('''
        date, start_time, end_time, is_available, booking_type
      ''')
          .eq('worker_id', workerId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0]);

      return response;
    } catch (e) {
      print('Error fetching worker availability: $e');
      return [];
    }
  }

  // Get Recommended Workers
  static Future<List<Map<String, dynamic>>> getRecommendedWorkers({
    required String householdId,
    int limit = 10,
  }) async {
    try {
      // This would typically use ML algorithms based on:
      // - Previous hire history
      // - Location proximity
      // - Service type preferences
      // - Rating and reviews

      // For now, return top-rated verified workers in the area
      final household = await SupabaseService.read(
        table: 'profiles',
        filters: {'id': householdId},
        limit: 1,
      );

      if (household.isEmpty) return [];

      final householdDistrict = household.first['district'];

      final workers = await _supabase
          .from('profiles')
          .select('''
        id, full_name, phone_number, district, hourly_rate, rating,
        profile_picture_url, services_offered, total_jobs_completed
      ''')
          .eq('role', 'house_helper')
          .eq('is_verified', true)
          .eq('is_available', true)
          .eq('district', householdDistrict)
          .gte('rating', 4.0)
          .order('rating', ascending: false)
          .limit(limit);

      return workers;
    } catch (e) {
      print('Error getting recommended workers: $e');
      return [];
    }
  }

  // Real-time subscriptions for live tracking
  static Stream<Map<String, dynamic>> subscribeToWorkerLocation(
      String requestId) {
    return _supabase
        .from('worker_locations')
        .stream(primaryKey: ['worker_id', 'hire_request_id'])
        .eq('hire_request_id', requestId)
        .map((data) => data.isNotEmpty ? data.first : {});
  }

  static Stream<Map<String, dynamic>> subscribeToHireRequestUpdates(
      String requestId) {
    return _supabase
        .from('hire_requests')
        .stream(primaryKey: ['id'])
        .eq('id', requestId)
        .map((data) => data.isNotEmpty ? data.first : {});
  }

  // ETA and Arrival Tracking
  static Future<Map<String, dynamic>?> getETATracking(String requestId) async {
    try {
      final response = await _supabase.from('hire_requests').select('''
            id,
            status,
            helper_location_lat,
            helper_location_lng,
            household_location_lat,
            household_location_lng,
            estimated_arrival,
            distance_km,
            last_location_update
          ''').eq('id', requestId).maybeSingle();

      if (response == null) return null;

      return {
        'status': response['status'],
        'estimated_arrival': response['estimated_arrival'],
        'distance_km': response['distance_km'] ?? 0.0,
        'last_updated': response['last_location_update'],
        'helper_lat': response['helper_location_lat'],
        'helper_lng': response['helper_location_lng'],
        'household_lat': response['household_location_lat'],
        'household_lng': response['household_location_lng'],
      };
    } catch (e) {
      print('Error getting ETA tracking: $e');
      throw Exception('Failed to get tracking data: $e');
    }
  }

  // Job Scheduling Methods
  static Future<List<Map<String, dynamic>>> getScheduledJobs(
      String householdId) async {
    try {
      final response = await _supabase.from('scheduled_jobs').select('''
            *,
            house_helpers:helper_id(full_name, phone_number)
          ''').eq('household_id', householdId).order('next_run_date');

      return response
          .map((job) => {
                ...job,
                'helper_name': job['house_helpers']?['full_name'],
                'helper_phone': job['house_helpers']?['phone_number'],
              })
          .toList();
    } catch (e) {
      print('Error getting scheduled jobs: $e');
      return [];
    }
  }

  static Future<void> createScheduledJob({
    required String householdId,
    required String title,
    required String serviceType,
    required String frequency,
    required DateTime startDate,
    String? helperId,
    String? notes,
    double? estimatedDuration,
    double? estimatedCost,
  }) async {
    try {
      DateTime nextRunDate = startDate;

      // Calculate next run date based on frequency
      switch (frequency) {
        case 'daily':
          // If start date is in the past, start from tomorrow
          if (startDate.isBefore(DateTime.now())) {
            nextRunDate = DateTime.now().add(const Duration(days: 1));
          }
          break;
        case 'weekly':
          if (startDate.isBefore(DateTime.now())) {
            nextRunDate = DateTime.now().add(const Duration(days: 7));
          }
          break;
        case 'biweekly':
          if (startDate.isBefore(DateTime.now())) {
            nextRunDate = DateTime.now().add(const Duration(days: 14));
          }
          break;
        case 'monthly':
          if (startDate.isBefore(DateTime.now())) {
            nextRunDate = DateTime(
                DateTime.now().year, DateTime.now().month + 1, startDate.day);
          }
          break;
      }

      await _supabase.from('scheduled_jobs').insert({
        'household_id': householdId,
        'helper_id': helperId,
        'title': title,
        'service_type': serviceType,
        'frequency': frequency,
        'start_date': startDate.toIso8601String(),
        'next_run_date': nextRunDate.toIso8601String(),
        'estimated_duration': estimatedDuration,
        'estimated_cost': estimatedCost,
        'notes': notes,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating scheduled job: $e');
      throw Exception('Failed to create scheduled job: $e');
    }
  }

  static Future<void> updateScheduledJob({
    required String jobId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _supabase.from('scheduled_jobs').update({
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', jobId);
    } catch (e) {
      print('Error updating scheduled job: $e');
      throw Exception('Failed to update scheduled job: $e');
    }
  }

  static Future<void> deleteScheduledJob(String jobId) async {
    try {
      await _supabase.from('scheduled_jobs').delete().eq('id', jobId);
    } catch (e) {
      print('Error deleting scheduled job: $e');
      throw Exception('Failed to delete scheduled job: $e');
    }
  }

  static Future<void> runScheduledJobNow(String jobId) async {
    try {
      // Get job details
      final jobResponse = await _supabase
          .from('scheduled_jobs')
          .select('*')
          .eq('id', jobId)
          .single();

      // Create immediate hire request using the existing method signature
      await createHireRequest(
        helperId: jobResponse['helper_id'] ?? '',
        helperName: 'Scheduled Helper',
        employerId: jobResponse['household_id'],
        employerName: 'Household User',
        serviceType: jobResponse['service_type'],
        description: 'Scheduled job: ${jobResponse['title']}',
        startDate: DateTime.now().add(const Duration(hours: 1)),
        endDate: DateTime.now().add(const Duration(hours: 4)),
        hourlyRate: (jobResponse['estimated_cost'] ?? 5000) / 3.0,
        estimatedHours: 3,
        location: 'Client Location',
        workAddress: 'Client Address',
        startTime: '09:00',
        hoursPerDay: 3,
        activities: ['Scheduled Task'],
        helperPhone: '+250XXXXXXXXX',
        employerPhone: '+250XXXXXXXXX',
        notes: 'Automated scheduled job execution',
        isUrgent: false,
      );

      // Update next run date based on frequency
      DateTime nextRun = DateTime.parse(jobResponse['next_run_date']);
      switch (jobResponse['frequency']) {
        case 'daily':
          nextRun = nextRun.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextRun = nextRun.add(const Duration(days: 7));
          break;
        case 'biweekly':
          nextRun = nextRun.add(const Duration(days: 14));
          break;
        case 'monthly':
          nextRun = DateTime(nextRun.year, nextRun.month + 1, nextRun.day);
          break;
      }

      await _supabase.from('scheduled_jobs').update({
        'next_run_date': nextRun.toIso8601String(),
        'last_run_date': DateTime.now().toIso8601String(),
      }).eq('id', jobId);
    } catch (e) {
      print('Error running scheduled job: $e');
      throw Exception('Failed to run scheduled job: $e');
    }
  }

  // Profile and Settings Methods
  static Future<Map<String, dynamic>?> getHouseholdProfile(
      String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .eq('role', 'house_holder')
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting household profile: $e');
      return null;
    }
  }

  static Future<void> updateHouseholdProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? address,
    String? district,
    String? sector,
    String? cell,
    String? village,
    String? profilePictureUrl,
    String? preferredLanguage,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (email != null) updateData['email'] = email;
      if (address != null) updateData['address'] = address;
      if (district != null) updateData['district'] = district;
      if (sector != null) updateData['sector'] = sector;
      if (cell != null) updateData['cell'] = cell;
      if (village != null) updateData['village'] = village;
      if (profilePictureUrl != null) {
        updateData['profile_picture_url'] = profilePictureUrl;
      }
      if (preferredLanguage != null) {
        updateData['preferred_language'] = preferredLanguage;
      }

      await _supabase.from('profiles').update(updateData).eq('id', userId);
    } catch (e) {
      print('Error updating household profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  static Future<String?> uploadProfilePicture({
    required String userId,
    required String filePath,
    required Uint8List fileBytes,
  }) async {
    try {
      final fileExtension = filePath.split('.').last;
      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await _supabase.storage
          .from('profile-pictures')
          .uploadBinary(fileName, fileBytes);

      final publicUrl =
          _supabase.storage.from('profile-pictures').getPublicUrl(fileName);

      // Update profile with new picture URL
      await _supabase.from('profiles').update({
        'profile_picture_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      return publicUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  // Subscription Management
  static Future<List<Map<String, dynamic>>> getHouseholdSubscriptions(
      String householdId) async {
    try {
      final response = await _supabase
          .from('subscriptions')
          .select('''
            *,
            house_helpers:worker_id(full_name, profile_picture_url, district)
          ''')
          .eq('household_id', householdId)
          .order('created_at', ascending: false);

      return response
          .map((sub) => {
                ...sub,
                'worker_name': sub['house_helpers']?['full_name'],
                'worker_picture': sub['house_helpers']?['profile_picture_url'],
                'worker_district': sub['house_helpers']?['district'],
              })
          .toList();
    } catch (e) {
      print('Error getting subscriptions: $e');
      return [];
    }
  }

  static Future<void> subscribeToWorker({
    required String householdId,
    required String workerId,
    required String subscriptionType,
    required double amount,
    required DateTime expiryDate,
  }) async {
    try {
      await _supabase.from('subscriptions').insert({
        'household_id': householdId,
        'worker_id': workerId,
        'subscription_type': subscriptionType,
        'amount': amount,
        'start_date': DateTime.now().toIso8601String(),
        'expiry_date': expiryDate.toIso8601String(),
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Send notification to worker
      await NotificationService.sendPushNotification(
        title: 'New Subscription',
        message: 'A household has subscribed to your services!',
        userIds: [workerId],
        data: {
          'type': 'subscription',
          'household_id': householdId,
        },
      );
    } catch (e) {
      print('Error subscribing to worker: $e');
      throw Exception('Failed to subscribe to worker: $e');
    }
  }

  static Future<void> cancelSubscription(String subscriptionId) async {
    try {
      await _supabase.from('subscriptions').update({
        'is_active': false,
        'cancelled_at': DateTime.now().toIso8601String(),
      }).eq('id', subscriptionId);
    } catch (e) {
      print('Error cancelling subscription: $e');
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  // Premium Worker Filtering
  static Future<List<Map<String, dynamic>>> getVerifiedWorkers({
    required String householdId,
    String? serviceType,
    String? district,
    double? maxDistance,
    double? minRating,
    String? sortBy = 'rating', // rating, distance, price, newest
    int limit = 20,
  }) async {
    try {
      String orderColumn = 'avg_rating';
      bool ascending = false;

      // Determine ordering
      switch (sortBy) {
        case 'rating':
          orderColumn = 'avg_rating';
          ascending = false;
          break;
        case 'price':
          orderColumn = 'hourly_rate';
          ascending = true;
          break;
        case 'newest':
          orderColumn = 'created_at';
          ascending = false;
          break;
        case 'distance':
          orderColumn = 'created_at';
          ascending = false;
          break;
        default:
          orderColumn = 'avg_rating';
          ascending = false;
      }

      var queryBuilder = _supabase.from('house_helpers').select('''
            *,
            profiles:user_id(full_name, profile_picture_url, district, sector, phone_number),
            avg_rating,
            total_jobs_completed,
            is_verified,
            subscriptions!subscriptions_worker_id_fkey(
              id,
              household_id,
              is_active,
              expiry_date
            )
          ''').eq('is_available', true).eq('is_verified', true);

      if (serviceType != null && serviceType.isNotEmpty) {
        queryBuilder = queryBuilder.contains('services', [serviceType]);
      }

      if (district != null && district.isNotEmpty) {
        queryBuilder = queryBuilder.eq('profiles.district', district);
      }

      if (minRating != null) {
        queryBuilder = queryBuilder.gte('avg_rating', minRating);
      }

      final response = await queryBuilder
          .order(orderColumn, ascending: ascending)
          .limit(limit);

      return response.map((worker) {
        // Check if household has active subscription to this worker
        final subscriptions = worker['subscriptions'] as List? ?? [];
        final hasActiveSubscription = subscriptions.any((sub) =>
            sub['household_id'] == householdId &&
            sub['is_active'] == true &&
            DateTime.parse(sub['expiry_date']).isAfter(DateTime.now()));

        return {
          ...worker,
          'full_name': worker['profiles']['full_name'],
          'profile_picture_url': worker['profiles']['profile_picture_url'],
          'district': worker['profiles']['district'],
          'sector': worker['profiles']['sector'],
          'phone_number': worker['profiles']['phone_number'],
          'has_subscription': hasActiveSubscription,
        };
      }).toList();
    } catch (e) {
      print('Error getting verified workers: $e');
      return [];
    }
  }

  // Last Hired Workers
  static Future<List<Map<String, dynamic>>> getLastHiredWorkers({
    required String householdId,
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('hire_requests')
          .select('''
            helper_id,
            helper_name,
            service_type,
            total_amount,
            start_date,
            status,
            house_helpers:helper_id(
              user_id,
              hourly_rate,
              avg_rating,
              is_available,
              is_verified,
              profiles:user_id(full_name, profile_picture_url, district, phone_number)
            )
          ''')
          .eq('household_id', householdId)
          .eq('status', 'completed')
          .order('start_date', ascending: false)
          .limit(limit);

      // Group by helper_id to get unique workers
      final Map<String, Map<String, dynamic>> uniqueWorkers = {};

      for (final request in response) {
        final helperId = request['helper_id'];
        if (!uniqueWorkers.containsKey(helperId)) {
          final helper = request['house_helpers'];
          uniqueWorkers[helperId] = {
            'user_id': helper['user_id'],
            'helper_id': helperId,
            'full_name': helper['profiles']['full_name'],
            'profile_picture_url': helper['profiles']['profile_picture_url'],
            'district': helper['profiles']['district'],
            'phone_number': helper['profiles']['phone_number'],
            'hourly_rate': helper['hourly_rate'],
            'avg_rating': helper['avg_rating'],
            'is_available': helper['is_available'],
            'is_verified': helper['is_verified'],
            'last_service_type': request['service_type'],
            'last_hired_date': request['start_date'],
            'last_amount_paid': request['total_amount'],
          };
        }
      }

      return uniqueWorkers.values.toList();
    } catch (e) {
      print('Error getting last hired workers: $e');
      return [];
    }
  }

  // Urgent Booking
  static Future<String> createUrgentHireRequest({
    required String householdId,
    required String helperId,
    required String serviceType,
    required DateTime startDate,
    required DateTime endDate,
    required double baseAmount,
    String? description,
    List<String>? taskList,
    String? comfortZoneNotes,
  }) async {
    try {
      // Calculate premium fee (20% for urgent booking)
      final premiumFee = baseAmount * 0.20;
      final totalAmount = baseAmount + premiumFee;

      final response = await _supabase
          .from('hire_requests')
          .insert({
            'household_id': householdId,
            'helper_id': helperId,
            'helper_name': '', // Will be filled by trigger
            'service_type': serviceType,
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'total_amount': totalAmount,
            'base_amount': baseAmount,
            'premium_fee': premiumFee,
            'description': description,
            'task_list': taskList,
            'comfort_zone_notes': comfortZoneNotes,
            'is_urgent': true,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Send urgent notification to helper
      await NotificationService.sendPushNotification(
        title: 'URGENT: New Hire Request',
        message: 'You have an urgent hire request with premium pay!',
        userIds: [helperId],
        data: {
          'type': 'urgent_hire_request',
          'request_id': response['id'],
          'premium_fee': premiumFee,
        },
      );

      return response['id'];
    } catch (e) {
      print('Error creating urgent hire request: $e');
      throw Exception('Failed to create urgent hire request: $e');
    }
  }
}
