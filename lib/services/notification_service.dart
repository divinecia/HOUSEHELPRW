import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/supabase_config.dart';
import '../models/admin_models.dart';
import '../services/supabase_service.dart';

class NotificationService {
  static final SupabaseClient _supabase = SupabaseConfig.instance;
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'househelp_notifications',
    'HouseHelp Notifications',
    description: 'Notifications for job updates, payments, and training',
    importance: Importance.high,
  );

  /// Initialize notification services
  static Future<void> initialize() async {
    // Request permission for notifications
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications');
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Get FCM token for the current user
  static Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to a topic for role-based notifications
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  // Send email notification to Isange One Stop Center for behavior reports
  static Future<bool> sendBehaviorReportToIsange(
    BehaviorReport report,
    String adminEmail,
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        'send-behavior-report-email',
        body: {
          'report': {
            'id': report.id,
            'reportedWorkerName': report.reportedWorkerName,
            'reportedWorkerId': report.reportedWorkerId,
            'reporterName': report.reporterHouseholdName,
            'incidentDescription': report.incidentDescription,
            'severity': report.severity.toString().split('.').last,
            'incidentDate': report.incidentDate.toIso8601String(),
            'location': report.location,
            'evidenceUrls': report.evidenceUrls,
            'reportedAt': report.reportedAt.toIso8601String(),
          },
          'adminEmail': adminEmail,
          'isangeEmail': 'isange@gov.rw', // Official Isange email
          'companyEmail': 'admin@househelprw.com', // Your company email
        },
      );

      return response.status == 200;
    } catch (e) {
      print('Error sending behavior report to Isange: $e');
      return false;
    }
  }

  /// General send notification method for compatibility
  static Future<void> sendNotification({
    required String title,
    required String message,
    List<String>? userIds,
    String? userRole,
    Map<String, dynamic>? data,
  }) async {
    await sendPushNotification(
      title: title,
      message: message,
      userIds: userIds,
      userRole: userRole,
      data: data,
    );
  }

  /// Send notification to specific users
  static Future<bool> sendPushNotification({
    required String title,
    required String message,
    List<String>? userIds,
    String? userRole,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Call Supabase Edge Function to send notification
      await _supabase.functions.invoke(
        'send-push-notification',
        body: {
          'title': title,
          'message': message,
          'userIds': userIds,
          'userRole': userRole,
          'data': data,
        },
      );

      // Store notification in database for history
      await _storeNotificationHistory(
        title: title,
        message: message,
        userIds: userIds,
        userRole: userRole,
        data: data,
      );

      return true;
    } catch (e) {
      print('Error sending push notification: $e');
      return false;
    }
  }

  /// Store notification in database for history
  static Future<void> _storeNotificationHistory({
    required String title,
    required String message,
    List<String>? userIds,
    String? userRole,
    Map<String, dynamic>? data,
  }) async {
    try {
      await SupabaseService.create(
        table: 'notification_history',
        data: {
          'title': title,
          'message': message,
          'user_ids': userIds,
          'user_role': userRole,
          'data': data,
          'sent_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error storing notification history: $e');
    }
  }

  /// Show local notification
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: data?.toString(),
    );
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');

    final notification = message.notification;
    if (notification != null) {
      showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: notification.title ?? 'HouseHelp',
        body: notification.body ?? '',
        data: message.data,
      );
    }
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    // Handle navigation based on notification data
    _navigateBasedOnNotification(message.data);
  }

  /// Handle notification tap from local notifications
  static void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // Parse payload and navigate
    if (response.payload != null) {
      // Handle navigation based on payload
    }
  }

  /// Navigate based on notification data
  static void _navigateBasedOnNotification(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'new_job':
        // Navigate to job details
        break;
      case 'payment_confirmation':
        // Navigate to payment history
        break;
      case 'training_approval':
        // Navigate to training page
        break;
      case 'chat_message':
        // Navigate to chat
        break;
      case 'worker_arrival':
        // Navigate to job tracking
        break;
      case 'training_request':
        // Navigate to admin training management
        break;
      default:
        // Navigate to dashboard
        break;
    }
  }

  /// Get notification history for a user
  static Future<List<Map<String, dynamic>>> getNotificationHistory({
    String? userId,
    String? userRole,
    int limit = 50,
  }) async {
    try {
      Map<String, dynamic>? filters;

      if (userId != null) {
        filters = {'user_ids': '[*]"$userId"[*]'}; // JSON array contains
      } else if (userRole != null) {
        filters = {'user_role': userRole};
      }

      final data = await SupabaseService.read(
        table: 'notification_history',
        orderBy: 'sent_at',
        ascending: false,
        limit: limit,
        filters: filters,
      );

      return data;
    } catch (e) {
      print('Error getting notification history: $e');
      return [];
    }
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await SupabaseService.update(
        table: 'notification_history',
        id: notificationId,
        data: {
          'read_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Send job-related notifications
  static Future<void> sendJobNotification({
    required String type,
    required String jobId,
    required String title,
    required String message,
    List<String>? userIds,
    String? userRole,
  }) async {
    await sendPushNotification(
      title: title,
      message: message,
      userIds: userIds,
      userRole: userRole,
      data: {
        'type': type,
        'job_id': jobId,
        'action': 'navigate_to_job',
      },
    );
  }

  /// Send payment notifications
  static Future<void> sendPaymentNotification({
    required String paymentId,
    required String title,
    required String message,
    required String userId,
    double? amount,
  }) async {
    await sendPushNotification(
      title: title,
      message: message,
      userIds: [userId],
      data: {
        'type': 'payment_confirmation',
        'payment_id': paymentId,
        'amount': amount?.toString(),
        'action': 'navigate_to_payments',
      },
    );
  }

  /// Send training notifications
  static Future<void> sendTrainingNotification({
    required String type,
    required String trainingId,
    required String title,
    required String message,
    List<String>? userIds,
    String? userRole,
  }) async {
    await sendPushNotification(
      title: title,
      message: message,
      userIds: userIds,
      userRole: userRole,
      data: {
        'type': type,
        'training_id': trainingId,
        'action': 'navigate_to_training',
      },
    );
  }

  // Send email notification for training
  static Future<bool> sendTrainingNotification({
    required String trainingId,
    required String trainingTitle,
    required DateTime startDate,
    required List<String> participantEmails,
    required bool isReminder,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'send-training-notification',
        body: {
          'trainingId': trainingId,
          'trainingTitle': trainingTitle,
          'startDate': startDate.toIso8601String(),
          'participantEmails': participantEmails,
          'isReminder': isReminder,
        },
      );

      return response.status == 200;
    } catch (e) {
      print('Error sending training notification: $e');
      return false;
    }
  }

  // Send system maintenance notification
  static Future<bool> sendMaintenanceNotification({
    required String title,
    required String message,
    required DateTime scheduledTime,
    required Duration estimatedDuration,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'send-maintenance-notification',
        body: {
          'title': title,
          'message': message,
          'scheduledTime': scheduledTime.toIso8601String(),
          'estimatedDuration': estimatedDuration.inMinutes,
        },
      );

      return response.status == 200;
    } catch (e) {
      print('Error sending maintenance notification: $e');
      return false;
    }
  }

  // Update behavior report email status
  static Future<bool> markBehaviorReportEmailSent(String reportId) async {
    try {
      await _supabase.from('behavior_reports').update({
        'email_sent_to_isange': true,
        'email_sent_at': DateTime.now().toIso8601String(),
      }).eq('id', reportId);

      return true;
    } catch (e) {
      print('Error updating behavior report email status: $e');
      return false;
    }
  }

  // Get notification history
  static Future<List<Map<String, dynamic>>> getNotificationHistory({
    int limit = 50,
    String? type,
  }) async {
    try {
      var query = _supabase.from('notification_logs').select().limit(limit);

      if (type != null) {
        query = query.eq('type', type);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting notification history: $e');
      return [];
    }
  }
}

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');

  // Show local notification for background messages
  if (message.notification != null) {
    await NotificationService.showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: message.notification!.title ?? 'HouseHelp',
      body: message.notification!.body ?? '',
      data: message.data,
    );
  }
}
