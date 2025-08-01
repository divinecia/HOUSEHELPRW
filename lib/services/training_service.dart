import '../models/training.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainingService {
  // Training CRUD operations

  static Future<List<Training>> getAllTrainings({
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      final data = await SupabaseService.read(
        table: 'trainings',
        orderBy: orderBy ?? 'created_at',
        ascending: ascending,
        limit: limit,
      );

      return data.map((json) => Training.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching trainings: $e');
      rethrow;
    }
  }

  static Future<Training?> getTrainingById(String id) async {
    try {
      final data = await SupabaseService.read(
        table: 'trainings',
        filters: {'id': id},
        limit: 1,
      );

      if (data.isNotEmpty) {
        return Training.fromJson(data.first);
      }
      return null;
    } catch (e) {
      print('Error fetching training by ID: $e');
      rethrow;
    }
  }

  static Future<Training> createTraining(Training training) async {
    try {
      final data = await SupabaseService.create(
        table: 'trainings',
        data: training.toJson()..remove('id'),
      );

      if (data != null) {
        return Training.fromJson(data);
      }
      throw Exception('Failed to create training');
    } catch (e) {
      print('Error creating training: $e');
      rethrow;
    }
  }

  static Future<Training> updateTraining(String id, Training training) async {
    try {
      final data = await SupabaseService.update(
        table: 'trainings',
        id: id,
        data: training.toJson()
          ..['updated_at'] = DateTime.now().toIso8601String(),
      );

      if (data != null) {
        return Training.fromJson(data);
      }
      throw Exception('Failed to update training');
    } catch (e) {
      print('Error updating training: $e');
      rethrow;
    }
  }

  static Future<bool> deleteTraining(String id) async {
    try {
      await SupabaseService.delete(
        table: 'trainings',
        id: id,
      );
      return true;
    } catch (e) {
      print('Error deleting training: $e');
      return false;
    }
  }

  // Training Participation methods

  static Future<List<TrainingParticipation>> getTrainingParticipants(
      String trainingId) async {
    try {
      final data = await SupabaseService.read(
        table: 'training_participations',
        filters: {'training_id': trainingId},
        orderBy: 'requested_at',
        ascending: false,
      );

      return data.map((json) => TrainingParticipation.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching training participants: $e');
      rethrow;
    }
  }

  static Future<List<TrainingParticipation>> getWorkerTrainingHistory(
      String workerId) async {
    try {
      final data = await SupabaseService.read(
        table: 'training_participations',
        filters: {'worker_id': workerId},
        orderBy: 'requested_at',
        ascending: false,
      );

      return data.map((json) => TrainingParticipation.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching worker training history: $e');
      rethrow;
    }
  }

  static Future<TrainingParticipation> requestTrainingParticipation({
    required String trainingId,
    required String workerId,
    required String workerName,
    bool paymentRequired = false,
  }) async {
    try {
      final participation = TrainingParticipation(
        trainingId: trainingId,
        workerId: workerId,
        workerName: workerName,
        requestedAt: DateTime.now(),
        paymentRequired: paymentRequired,
      );

      final data = await SupabaseService.create(
        table: 'training_participations',
        data: participation.toJson()..remove('id'),
      );

      if (data != null) {
        return TrainingParticipation.fromJson(data);
      }
      throw Exception('Failed to request training participation');
    } catch (e) {
      print('Error requesting training participation: $e');
      rethrow;
    }
  }

  static Future<TrainingParticipation> updateParticipationStatus({
    required String participationId,
    required ParticipationStatus status,
    double? score,
    String? feedback,
    bool? certificateIssued,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == ParticipationStatus.completed) {
        updateData['completed_at'] = DateTime.now().toIso8601String();
        if (score != null) updateData['score'] = score;
        if (feedback != null) updateData['feedback'] = feedback;
        if (certificateIssued != null) {
          updateData['certificate_issued'] = certificateIssued;
        }
      }

      final data = await SupabaseService.update(
        table: 'training_participations',
        id: participationId,
        data: updateData,
      );

      if (data != null) {
        return TrainingParticipation.fromJson(data);
      }
      throw Exception('Failed to update participation status');
    } catch (e) {
      print('Error updating participation status: $e');
      rethrow;
    }
  }

  // Analytics methods

  static Future<Map<String, dynamic>> getTrainingAnalytics() async {
    try {
      final client = Supabase.instance.client;

      // Get total trainings
      final totalTrainings =
          await client.from('trainings').select().then((data) => data.length);

      // Get completed trainings
      final completedTrainings = await client
          .from('trainings')
          .select()
          .eq('status', 'completed')
          .then((data) => data.length);

      // Get total participants
      final totalParticipants = await client
          .from('training_participations')
          .select()
          .then((data) => data.length);

      // Get completion rate
      final completedParticipants = await client
          .from('training_participations')
          .select()
          .eq('status', 'completed')
          .then((data) => data.length);

      // Get upcoming trainings
      final upcomingTrainings = await client
          .from('trainings')
          .select()
          .eq('status', 'scheduled')
          .gte('start_date', DateTime.now().toIso8601String())
          .then((data) => data.length);

      return {
        'totalTrainings': totalTrainings,
        'completedTrainings': completedTrainings,
        'totalParticipants': totalParticipants,
        'completedParticipants': completedParticipants,
        'completionRate': totalParticipants > 0
            ? (completedParticipants / totalParticipants * 100)
            : 0.0,
        'upcomingTrainings': upcomingTrainings,
      };
    } catch (e) {
      print('Error fetching training analytics: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getMonthlyTrainingStats() async {
    try {
      final client = Supabase.instance.client;

      final response = await client.rpc('get_monthly_training_stats');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching monthly training stats: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTrainingCategoryStats() async {
    try {
      final client = Supabase.instance.client;

      final response = await client
          .from('trainings')
          .select('category')
          .not('category', 'is', null);

      final Map<String, int> categoryCount = {};
      for (var item in response) {
        final category = item['category'] as String;
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      return categoryCount.entries
          .map((e) => {'category': e.key, 'count': e.value})
          .toList();
    } catch (e) {
      print('Error fetching training category stats: $e');
      return [];
    }
  }
}
