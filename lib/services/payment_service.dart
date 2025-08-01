import 'package:househelp/models/payment.dart';
import 'package:househelp/services/paypack_service.dart';
import 'package:househelp/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class PaymentService {
  static const String _paymentsTable = 'payments';
  static const _uuid = Uuid();

  // Initiate a payment for hiring a house helper
  static Future<Payment?> initiateHirePayment({
    required double amount,
    required String phoneNumber,
    required String hireRequestId,
    required String houseHelperId,
    required String houseHolderId,
    String? description,
  }) async {
    try {
      final paymentId = _uuid.v4();
      final paymentDescription =
          description ?? 'Payment for house helper services';

      // Create payment record in Supabase
      final payment = Payment(
        id: paymentId,
        transactionId: '', // Will be updated after Paypack response
        amount: amount,
        currency: 'RWF',
        phoneNumber: phoneNumber,
        description: paymentDescription,
        status: 'pending',
        paymentMethod: 'mobile_money',
        hireRequestId: hireRequestId,
        houseHelperId: houseHelperId,
        houseHolderId: houseHolderId,
        createdAt: DateTime.now(),
      );

      // Save to database
      await SupabaseService.create(
        table: _paymentsTable,
        data: payment.toJson(),
      );

      // Initiate payment with Paypack
      final paypackResponse = await PaypackService.initiatePayment(
        amount: amount,
        phoneNumber: phoneNumber,
        description: paymentDescription,
        webhookUrl:
            'YOUR_WEBHOOK_URL/payment-webhook', // Replace with your webhook URL
      );

      if (paypackResponse != null) {
        final transactionId = paypackResponse['ref']?.toString() ?? '';

        // Update payment with transaction ID
        final updatedPayment = await SupabaseService.update(
          table: _paymentsTable,
          id: paymentId,
          data: {'transaction_id': transactionId},
        );

        if (updatedPayment != null) {
          return Payment.fromJson(updatedPayment);
        }
      }

      return payment;
    } catch (e) {
      print('Error initiating hire payment: $e');
      return null;
    }
  }

  // Check payment status
  static Future<Payment?> checkPaymentStatus(String paymentId) async {
    try {
      final paymentData = await SupabaseService.readById(
        table: _paymentsTable,
        id: paymentId,
      );

      if (paymentData == null) return null;

      final payment = Payment.fromJson(paymentData);

      if (payment.transactionId.isNotEmpty && payment.isPending) {
        // Check status with Paypack
        final paypackStatus = await PaypackService.checkTransactionStatus(
          payment.transactionId,
        );

        if (paypackStatus != null) {
          final status =
              paypackStatus['status']?.toString().toLowerCase() ?? 'pending';
          String mappedStatus;

          switch (status) {
            case 'successful':
            case 'completed':
              mappedStatus = 'completed';
              break;
            case 'failed':
              mappedStatus = 'failed';
              break;
            case 'cancelled':
              mappedStatus = 'cancelled';
              break;
            default:
              mappedStatus = 'pending';
          }

          if (mappedStatus != payment.status) {
            // Update payment status
            final updatedData = await SupabaseService.update(
              table: _paymentsTable,
              id: paymentId,
              data: {
                'status': mappedStatus,
                'completed_at': mappedStatus == 'completed'
                    ? DateTime.now().toIso8601String()
                    : null,
                'metadata': paypackStatus,
              },
            );

            if (updatedData != null) {
              return Payment.fromJson(updatedData);
            }
          }
        }
      }

      return payment;
    } catch (e) {
      print('Error checking payment status: $e');
      return null;
    }
  }

  // Get payments for a house holder
  static Future<List<Payment>> getPaymentsForHouseHolder(
      String houseHolderId) async {
    try {
      final paymentsData = await SupabaseService.read(
        table: _paymentsTable,
        filters: {'house_holder_id': houseHolderId},
        orderBy: 'created_at',
        ascending: false,
      );

      return paymentsData.map((data) => Payment.fromJson(data)).toList();
    } catch (e) {
      print('Error getting payments for house holder: $e');
      return [];
    }
  }

  // Get payments for a house helper
  static Future<List<Payment>> getPaymentsForHouseHelper(
      String houseHelperId) async {
    try {
      final paymentsData = await SupabaseService.read(
        table: _paymentsTable,
        filters: {'house_helper_id': houseHelperId},
        orderBy: 'created_at',
        ascending: false,
      );

      return paymentsData.map((data) => Payment.fromJson(data)).toList();
    } catch (e) {
      print('Error getting payments for house helper: $e');
      return [];
    }
  }

  // Get all payments (for admin)
  static Future<List<Payment>> getAllPayments({
    int? limit,
    String? status,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (status != null) {
        filters['status'] = status;
      }

      final paymentsData = await SupabaseService.read(
        table: _paymentsTable,
        filters: filters.isNotEmpty ? filters : null,
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );

      return paymentsData.map((data) => Payment.fromJson(data)).toList();
    } catch (e) {
      print('Error getting all payments: $e');
      return [];
    }
  }

  // Cancel a payment
  static Future<bool> cancelPayment(String paymentId) async {
    try {
      await SupabaseService.update(
        table: _paymentsTable,
        id: paymentId,
        data: {
          'status': 'cancelled',
          'completed_at': DateTime.now().toIso8601String(),
        },
      );
      return true;
    } catch (e) {
      print('Error cancelling payment: $e');
      return false;
    }
  }

  // Get payment statistics
  static Future<Map<String, dynamic>> getPaymentStatistics() async {
    try {
      final allPayments = await getAllPayments();

      final totalPayments = allPayments.length;
      final completedPayments = allPayments.where((p) => p.isCompleted).length;
      final pendingPayments = allPayments.where((p) => p.isPending).length;
      final failedPayments = allPayments.where((p) => p.isFailed).length;

      final totalAmount = allPayments
          .where((p) => p.isCompleted)
          .fold(0.0, (sum, payment) => sum + payment.amount);

      return {
        'total_payments': totalPayments,
        'completed_payments': completedPayments,
        'pending_payments': pendingPayments,
        'failed_payments': failedPayments,
        'total_amount': totalAmount,
        'success_rate':
            totalPayments > 0 ? (completedPayments / totalPayments) * 100 : 0,
      };
    } catch (e) {
      print('Error getting payment statistics: $e');
      return {};
    }
  }

  // Get revenue analytics for admin dashboard
  static Future<Map<String, dynamic>> getRevenueAnalytics() async {
    try {
      final allPayments = await getAllPayments();
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      final lastMonth = DateTime(now.year, now.month - 1, 1);

      // Current month revenue
      final currentMonthRevenue = allPayments
          .where((p) => p.isCompleted && p.createdAt.isAfter(currentMonth))
          .fold(0.0, (sum, payment) => sum + payment.amount);

      // Last month revenue
      final lastMonthRevenue = allPayments
          .where((p) =>
              p.isCompleted &&
              p.createdAt.isAfter(lastMonth) &&
              p.createdAt.isBefore(currentMonth))
          .fold(0.0, (sum, payment) => sum + payment.amount);

      // Total revenue
      final totalRevenue = allPayments
          .where((p) => p.isCompleted)
          .fold(0.0, (sum, payment) => sum + payment.amount);

      // Service vs Training revenue (if payment_type exists)
      double serviceRevenue = 0.0;
      double trainingRevenue = 0.0;

      for (final payment in allPayments.where((p) => p.isCompleted)) {
        // Assuming we add payment_type to the Payment model later
        // For now, we'll treat all as service revenue
        serviceRevenue += payment.amount;
      }

      return {
        'currentMonthRevenue': currentMonthRevenue,
        'lastMonthRevenue': lastMonthRevenue,
        'totalRevenue': totalRevenue,
        'serviceRevenue': serviceRevenue,
        'trainingRevenue': trainingRevenue,
        'revenueGrowth': lastMonthRevenue > 0
            ? ((currentMonthRevenue - lastMonthRevenue) / lastMonthRevenue) *
                100
            : 0.0,
      };
    } catch (e) {
      print('Error getting revenue analytics: $e');
      return {
        'currentMonthRevenue': 0.0,
        'lastMonthRevenue': 0.0,
        'totalRevenue': 0.0,
        'serviceRevenue': 0.0,
        'trainingRevenue': 0.0,
        'revenueGrowth': 0.0,
      };
    }
  }

  // Update payment status and transaction details
  static Future<bool> updatePayment({
    required String paymentId,
    String? status,
    String? transactionId,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (status != null) {
        updateData['status'] = status;
      }

      if (transactionId != null) {
        updateData['transaction_id'] = transactionId;
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      await SupabaseService.update(
        table: 'payments',
        id: paymentId,
        data: updateData,
      );

      return true;
    } catch (e) {
      print('Error updating payment: $e');
      return false;
    }
  }

  // Initiate a payment for training enrollment
  static Future<Payment?> initiateTrainingPayment({
    required double amount,
    required String phoneNumber,
    required String trainingId,
    required String userId,
    String? description,
  }) async {
    try {
      final paymentId = _uuid.v4();
      final paymentDescription =
          description ?? 'Payment for training enrollment';

      // Create payment record in Supabase
      final payment = Payment(
        id: paymentId,
        transactionId: '', // Will be updated after Paypack response
        amount: amount,
        currency: 'RWF',
        phoneNumber: phoneNumber,
        description: paymentDescription,
        status: 'pending',
        paymentMethod: 'mobile_money',
        trainingId: trainingId,
        houseHelperId: userId,
        createdAt: DateTime.now(),
      );

      // Save to database
      await SupabaseService.create(
        table: _paymentsTable,
        data: payment.toJson(),
      );

      // Initiate payment with Paypack
      final paypackResponse = await PaypackService.initiatePayment(
        amount: amount,
        phoneNumber: phoneNumber,
        description: paymentDescription,
      );

      if (paypackResponse != null && paypackResponse['status'] == 'success') {
        final transactionId = paypackResponse['ref']?.toString() ??
            paypackResponse['id']?.toString();

        // Update payment with transaction ID
        await updatePayment(
          paymentId: paymentId,
          status: 'processing',
          transactionId: transactionId,
        );

        return payment.copyWith(
          transactionId: transactionId,
          status: 'processing',
        );
      } else {
        // Mark payment as failed
        await updatePayment(
          paymentId: paymentId,
          status: 'failed',
        );
        return null;
      }
    } catch (e) {
      print('Error initiating training payment: $e');
      return null;
    }
  }
}
