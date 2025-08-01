import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'payment_service.dart';
import 'notification_service.dart';

class WorkerService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get worker profile with joined user profile fields.
  static Future<Map<String, dynamic>?> getWorkerProfile(String workerId) async {
    try {
      final response = await _supabase.from('house_helpers').select('''
            *,
            profiles:user_id(
              full_name,
              phone_number,
              email,
              profile_picture_url,
              district,
              sector,
              cell,
              village,
              preferred_language
            )
          ''').eq('user_id', workerId).maybeSingle();

      return response;
    } catch (e) {
      print('Error getting worker profile: $e');
      return null;
    }
  }

  // Update worker profile and house_helpers info.
  static Future<void> updateWorkerProfile({
    required String workerId,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? district,
    String? sector,
    String? cell,
    String? village,
    String? profilePictureUrl,
    String? preferredLanguage,
    List<String>? services,
    double? hourlyRate,
    String? insuranceProvider,
    bool? ejoHezaOptIn,
    String? taxStatus,
    String? bankAccount,
    String? experience,
    String? bio,
  }) async {
    try {
      final profileUpdateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (fullName != null) profileUpdateData['full_name'] = fullName;
      if (phoneNumber != null) profileUpdateData['phone_number'] = phoneNumber;
      if (email != null) profileUpdateData['email'] = email;
      if (district != null) profileUpdateData['district'] = district;
      if (sector != null) profileUpdateData['sector'] = sector;
      if (cell != null) profileUpdateData['cell'] = cell;
      if (village != null) profileUpdateData['village'] = village;
      if (profilePictureUrl != null)
        profileUpdateData['profile_picture_url'] = profilePictureUrl;
      if (preferredLanguage != null)
        profileUpdateData['preferred_language'] = preferredLanguage;

      await _supabase
          .from('profiles')
          .update(profileUpdateData)
          .eq('id', workerId);

      final helperUpdateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (services != null) helperUpdateData['services'] = services;
      if (hourlyRate != null) helperUpdateData['hourly_rate'] = hourlyRate;
      if (insuranceProvider != null)
        helperUpdateData['insurance_provider'] = insuranceProvider;
      if (ejoHezaOptIn != null)
        helperUpdateData['ejo_heza_opt_in'] = ejoHezaOptIn;
      if (taxStatus != null) helperUpdateData['tax_status'] = taxStatus;
      if (bankAccount != null) helperUpdateData['bank_account'] = bankAccount;
      if (experience != null) helperUpdateData['experience'] = experience;
      if (bio != null) helperUpdateData['bio'] = bio;

      await _supabase
          .from('house_helpers')
          .update(helperUpdateData)
          .eq('user_id', workerId);
    } catch (e) {
      print('Error updating worker profile: $e');
      rethrow;
    }
  }

  /// Upload worker profile picture and update profile.
  static Future<String?> uploadWorkerProfilePicture({
    required String workerId,
    required String filePath,
    required Uint8List fileBytes,
  }) async {
    try {
      final fileExtension = filePath.split('.').last;
      final fileName =
          'worker_profile_${workerId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await _supabase.storage
          .from('profile-pictures')
          .uploadBinary(fileName, fileBytes);

      final publicUrl =
          _supabase.storage.from('profile-pictures').getPublicUrl(fileName);

      await _supabase.from('profiles').update({
        'profile_picture_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', workerId);

      return publicUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Upload verification document and store record.
  static Future<String?> uploadVerificationDocument({
    required String workerId,
    required String documentType,
    required String filePath,
    required Uint8List fileBytes,
  }) async {
    try {
      final fileExtension = filePath.split('.').last;
      final fileName =
          'verification_${workerId}_${documentType}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await _supabase.storage
          .from('verification-documents')
          .uploadBinary(fileName, fileBytes);

      final publicUrl = _supabase.storage
          .from('verification-documents')
          .getPublicUrl(fileName);

      await _supabase.from('worker_documents').insert({
        'worker_id': workerId,
        'document_type': documentType,
        'document_url': publicUrl,
        'uploaded_at': DateTime.now().toIso8601String(),
        'verification_status': 'pending',
      });

      return publicUrl;
    } catch (e) {
      print('Error uploading document: $e');
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Get worker jobs with optional filters.
  static Future<List<Map<String, dynamic>>> getWorkerJobs({
    required String workerId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      var query = _supabase.from('hire_requests').select('''
            *,
            profiles:household_id(full_name, phone_number, district)
          ''').eq('helper_id', workerId);

      if (startDate != null) {
        query = query.gte('start_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('start_date', endDate.toIso8601String());
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final List<dynamic> response = await query.order('start_date');
      return response
          .map<Map<String, dynamic>>((job) => {
                ...job as Map<String, dynamic>,
                'household_name': job['profiles']?['full_name'],
                'household_phone': job['profiles']?['phone_number'],
                'household_district': job['profiles']?['district'],
              })
          .toList();
    } catch (e) {
      print('Error getting worker jobs: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTodaysJobs(
      String workerId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getWorkerJobs(
      workerId: workerId,
      startDate: startOfDay,
      endDate: endOfDay,
      status: 'accepted',
    );
  }

  static Future<List<Map<String, dynamic>>> getUpcomingJobs(
      String workerId) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final nextWeek = DateTime.now().add(const Duration(days: 7));
    return getWorkerJobs(
      workerId: workerId,
      startDate: tomorrow,
      endDate: nextWeek,
    );
  }

  /// Confirm worker arrival for a job.
  static Future<void> confirmArrival({
    required String requestId,
    required String workerId,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      await _supabase.from('hire_requests').update({
        'status': 'ongoing',
        'actual_start_time': DateTime.now().toIso8601String(),
        'worker_location_lat': latitude,
        'worker_location_lng': longitude,
        'arrival_notes': notes,
        'confirmed_arrival_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);

      final request = await _supabase
          .from('hire_requests')
          .select('household_id, helper_name')
          .eq('id', requestId)
          .maybeSingle();

      if (request != null) {
        await NotificationService.sendPushNotification(
          title: 'Worker Arrived',
          message:
              '${request['helper_name']} has arrived and confirmed their presence',
          userIds: [request['household_id']],
          data: {
            'type': 'worker_arrival',
            'request_id': requestId,
          },
        );
      }
    } catch (e) {
      print('Error confirming arrival: $e');
      throw Exception('Failed to confirm arrival: $e');
    }
  }

  /// Report delay for a job.
  static Future<void> reportDelay({
    required String requestId,
    required int delayMinutes,
    required String reason,
    String? notes,
  }) async {
    try {
      final newETA = DateTime.now().add(Duration(minutes: delayMinutes));
      await _supabase.from('hire_requests').update({
        'estimated_arrival': newETA.toIso8601String(),
        'delay_reason': reason,
        'delay_notes': notes,
        'delay_reported_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);

      final request = await _supabase
          .from('hire_requests')
          .select('household_id, helper_name')
          .eq('id', requestId)
          .maybeSingle();

      if (request != null) {
        await NotificationService.sendPushNotification(
          title: 'Delay Notification',
          message:
              '${request['helper_name']} will be $delayMinutes minutes late. Reason: $reason',
          userIds: [request['household_id']],
          data: {
            'type': 'worker_delay',
            'request_id': requestId,
            'delay_minutes': delayMinutes,
          },
        );
      }
    } catch (e) {
      print('Error reporting delay: $e');
      throw Exception('Failed to report delay: $e');
    }
  }

  /// Request job reschedule.
  static Future<void> requestReschedule({
    required String requestId,
    required DateTime newDate,
    required String reason,
    String? notes,
  }) async {
    try {
      await _supabase.from('reschedule_requests').insert({
        'hire_request_id': requestId,
        'requested_new_date': newDate.toIso8601String(),
        'reason': reason,
        'notes': notes,
        'status': 'pending',
        'requested_at': DateTime.now().toIso8601String(),
      });

      final request = await _supabase
          .from('hire_requests')
          .select('household_id, helper_name')
          .eq('id', requestId)
          .maybeSingle();

      if (request != null) {
        await NotificationService.sendPushNotification(
          title: 'Reschedule Request',
          message: '${request['helper_name']} requested to reschedule your job',
          userIds: [request['household_id']],
          data: {
            'type': 'reschedule_request',
            'request_id': requestId,
          },
        );
      }
    } catch (e) {
      print('Error requesting reschedule: $e');
      throw Exception('Failed to request reschedule: $e');
    }
  }

  /// Get available trainings.
  static Future<List<Map<String, dynamic>>> getAvailableTrainings({
    String? serviceType,
    bool upcomingOnly = true,
  }) async {
    try {
      var query = _supabase.from('trainings').select('*').eq('is_active', true);
      if (upcomingOnly) {
        query = query.gte('start_date', DateTime.now().toIso8601String());
      }
      if (serviceType != null) {
        query = query.contains('target_services', [serviceType]);
      }
      final List<dynamic> response = await query.order('start_date');
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting available trainings: $e');
      return [];
    }
  }

  /// Request training enrollment.
  static Future<void> requestTrainingEnrollment({
    required String workerId,
    required String trainingId,
    String? motivation,
  }) async {
    try {
      final existing = await _supabase
          .from('training_enrollments')
          .select('id')
          .eq('worker_id', workerId)
          .eq('training_id', trainingId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Already enrolled or requested for this training');
      }

      await _supabase.from('training_enrollments').insert({
        'worker_id': workerId,
        'training_id': trainingId,
        'enrollment_type': 'worker_request',
        'motivation': motivation,
        'status': 'pending',
        'requested_at': DateTime.now().toIso8601String(),
      });

      final training = await _supabase
          .from('trainings')
          .select('title')
          .eq('id', trainingId)
          .maybeSingle();

      if (training != null) {
        await NotificationService.sendPushNotification(
          title: 'Training Request',
          message:
              'A worker has requested to join "${training['title']}" training',
          userRole: 'admin',
          data: {
            'type': 'training_request',
            'training_id': trainingId,
            'worker_id': workerId,
          },
        );
      }
    } catch (e) {
      print('Error requesting training enrollment: $e');
      throw Exception('Failed to request training: $e');
    }
  }

  /// Get worker's training enrollments.
  static Future<List<Map<String, dynamic>>> getWorkerTrainingEnrollments(
      String workerId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('training_enrollments')
          .select('''
            *,
            trainings:training_id(title, description, start_date, end_date, cost, location)
          ''')
          .eq('worker_id', workerId)
          .order('requested_at', ascending: false);

      return response
          .map<Map<String, dynamic>>((enrollment) => {
                ...enrollment as Map<String, dynamic>,
                'training_title': enrollment['trainings']?['title'],
                'training_description': enrollment['trainings']?['description'],
                'training_start_date': enrollment['trainings']?['start_date'],
                'training_end_date': enrollment['trainings']?['end_date'],
                'training_cost': enrollment['trainings']?['cost'],
                'training_location': enrollment['trainings']?['location'],
              })
          .toList();
    } catch (e) {
      print('Error getting training enrollments: $e');
      return [];
    }
  }

  /// Pay for training.
  static Future<bool> payForTraining({
    required String enrollmentId,
    required String workerId,
    required double amount,
    required String phoneNumber,
    String? description,
  }) async {
    try {
      final enrollment = await _supabase
          .from('training_enrollments')
          .select('training_id')
          .eq('id', enrollmentId)
          .maybeSingle();

      if (enrollment == null) return false;
      final trainingId = enrollment['training_id'] as String;

      final payment = await PaymentService.initiateTrainingPayment(
        amount: amount,
        phoneNumber: phoneNumber,
        trainingId: trainingId,
        userId: workerId,
        description: description ?? 'Training fee payment',
      );

      if (payment != null) {
        await _supabase.from('training_enrollments').update({
          'payment_status': 'paid',
          'paid_at': DateTime.now().toIso8601String(),
          'payment_id': payment.id,
        }).eq('id', enrollmentId);

        return true;
      }
      return false;
    } catch (e) {
      print('Error processing training payment: $e');
      return false;
    }
  }

  /// Get worker chats.
  static Future<List<Map<String, dynamic>>> getWorkerChats(
      String workerId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('hire_requests')
          .select('''
            id,
            household_id,
            helper_name,
            service_type,
            start_date,
            status,
            profiles:household_id(full_name, profile_picture_url)
          ''')
          .eq('helper_id', workerId)
          .inFilter('status', ['accepted', 'ongoing', 'completed'])
          .order('start_date', ascending: false);

      return response
          .map<Map<String, dynamic>>((job) => {
                'job_id': job['id'],
                'household_id': job['household_id'],
                'household_name': job['profiles']?['full_name'],
                'household_picture': job['profiles']?['profile_picture_url'],
                'service_type': job['service_type'],
                'start_date': job['start_date'],
                'status': job['status'],
              })
          .toList();
    } catch (e) {
      print('Error getting worker chats: $e');
      return [];
    }
  }

  /// Get chat messages for a job.
  static Future<List<Map<String, dynamic>>> getChatMessages({
    required String jobId,
    required String workerId,
  }) async {
    try {
      final List<dynamic> response = await _supabase
          .from('chat_messages')
          .select('*')
          .eq('hire_request_id', jobId)
          .order('sent_at');
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting chat messages: $e');
      return [];
    }
  }

  /// Send chat message.
  static Future<void> sendChatMessage({
    required String jobId,
    required String senderId,
    required String message,
    String? messageType = 'text',
    String? attachmentUrl,
  }) async {
    try {
      await _supabase.from('chat_messages').insert({
        'hire_request_id': jobId,
        'sender_id': senderId,
        'message': message,
        'message_type': messageType,
        'attachment_url': attachmentUrl,
        'sent_at': DateTime.now().toIso8601String(),
      });

      final job = await _supabase
          .from('hire_requests')
          .select('household_id')
          .eq('id', jobId)
          .maybeSingle();

      if (job != null) {
        await NotificationService.sendPushNotification(
          title: 'New Message',
          message:
              message.length > 50 ? '${message.substring(0, 50)}...' : message,
          userIds: [job['household_id']],
          data: {
            'type': 'chat_message',
            'job_id': jobId,
          },
        );
      }
    } catch (e) {
      print('Error sending chat message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get worker rating stats and recent reviews.
  static Future<Map<String, dynamic>> getWorkerRatingsStats(
      String workerId) async {
    try {
      final stats = await _supabase.rpc('get_worker_rating_stats',
          params: {'worker_id_param': workerId});
      final List<dynamic> reviews = await _supabase
          .from('ratings_reviews')
          .select('''
            *,
            profiles:household_id(full_name)
          ''')
          .eq('worker_id', workerId)
          .order('created_at', ascending: false)
          .limit(10);

      return {
        'average_rating': stats['average_rating'] ?? 0.0,
        'total_ratings': stats['total_ratings'] ?? 0,
        'rating_distribution': stats['rating_distribution'] ?? {},
        'total_jobs_completed': stats['total_jobs_completed'] ?? 0,
        'recent_reviews': reviews
            .map<Map<String, dynamic>>((review) => {
                  ...review as Map<String, dynamic>,
                  'household_name': review['profiles']?['full_name'],
                })
            .toList(),
      };
    } catch (e) {
      print('Error getting rating stats: $e');
      return {
        'average_rating': 0.0,
        'total_ratings': 0,
        'rating_distribution': {},
        'total_jobs_completed': 0,
        'recent_reviews': [],
      };
    }
  }

  /// Get worker reviews with pagination.
  static Future<List<Map<String, dynamic>>> getWorkerReviews({
    required String workerId,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _supabase.from('ratings_reviews').select('''
            *,
            profiles:household_id(full_name, profile_picture_url),
            hire_requests:job_id(service_type, start_date)
          ''').eq('worker_id', workerId).order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 10) - 1);
      }

      final List<dynamic> response = await query;

      return response
          .map<Map<String, dynamic>>((review) => {
                ...review as Map<String, dynamic>,
                'household_name': review['profiles']?['full_name'],
                'household_picture': review['profiles']?['profile_picture_url'],
                'service_type': review['hire_requests']?['service_type'],
                'job_date': review['hire_requests']?['start_date'],
              })
          .toList();
    } catch (e) {
      print('Error getting worker reviews: $e');
      return [];
    }
  }

  /// Update job status and notify household.
  static Future<void> updateJobStatus({
    required String requestId,
    required String status,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (status == 'completed') {
        updateData['actual_end_time'] = DateTime.now().toIso8601String();
      }
      if (notes != null) {
        updateData['worker_notes'] = notes;
      }

      await _supabase
          .from('hire_requests')
          .update(updateData)
          .eq('id', requestId);

      final request = await _supabase
          .from('hire_requests')
          .select('household_id, helper_name')
          .eq('id', requestId)
          .maybeSingle();

      if (request != null) {
        String notificationMessage;
        switch (status) {
          case 'completed':
            notificationMessage =
                '${request['helper_name']} has completed the job';
            break;
          case 'cancelled':
            notificationMessage =
                '${request['helper_name']} has cancelled the job';
            break;
          default:
            notificationMessage =
                'Job status updated by ${request['helper_name']}';
        }

        await NotificationService.sendPushNotification(
          title: 'Job Status Update',
          message: notificationMessage,
          userIds: [request['household_id']],
          data: {
            'type': 'job_status_update',
            'request_id': requestId,
            'new_status': status,
          },
        );
      }
    } catch (e) {
      print('Error updating job status: $e');
      throw Exception('Failed to update job status: $e');
    }
  }

  /// Get worker analytics.
  static Future<Map<String, dynamic>> getWorkerAnalytics(
      String workerId) async {
    try {
      final response = await _supabase
          .rpc('get_worker_analytics', params: {'worker_id_param': workerId});
      return response as Map<String, dynamic>? ??
          {
            'total_jobs': 0,
            'completed_jobs': 0,
            'cancelled_jobs': 0,
            'total_earnings': 0.0,
            'this_month_earnings': 0.0,
            'average_rating': 0.0,
            'completion_rate': 0.0,
          };
    } catch (e) {
      print('Error getting worker analytics: $e');
      return {
        'total_jobs': 0,
        'completed_jobs': 0,
        'cancelled_jobs': 0,
        'total_earnings': 0.0,
        'this_month_earnings': 0.0,
        'average_rating': 0.0,
        'completion_rate': 0.0,
      };
    }
  }
}
