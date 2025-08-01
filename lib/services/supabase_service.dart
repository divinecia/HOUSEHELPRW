import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:househelp/config/supabase_config.dart';

class SupabaseService {
  static final _client = SupabaseConfig.instance;

  // Generic CRUD operations

  // Create a record
  static Future<Map<String, dynamic>?> create({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _client.from(table).insert(data).select().single();
      return response;
    } catch (e) {
      print('Error creating record in $table: $e');
      rethrow;
    }
  }

  // Read records with optional filters
  static Future<List<Map<String, dynamic>>> read({
    required String table,
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      var query = _client.from(table).select(select ?? '*');

      // Apply filters
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error reading from $table: $e');
      rethrow;
    }
  }

  // Read a single record by ID
  static Future<Map<String, dynamic>?> readById({
    required String table,
    required String id,
    String? select,
  }) async {
    try {
      final response =
          await _client.from(table).select(select ?? '*').eq('id', id).single();
      return response;
    } catch (e) {
      print('Error reading record from $table with id $id: $e');
      return null;
    }
  }

  // Update a record
  static Future<Map<String, dynamic>?> update({
    required String table,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response =
          await _client.from(table).update(data).eq('id', id).select().single();
      return response;
    } catch (e) {
      print('Error updating record in $table with id $id: $e');
      rethrow;
    }
  }

  // Delete a record
  static Future<void> delete({
    required String table,
    required String id,
  }) async {
    try {
      await _client.from(table).delete().eq('id', id);
    } catch (e) {
      print('Error deleting record from $table with id $id: $e');
      rethrow;
    }
  }

  // Search records with text search
  static Future<List<Map<String, dynamic>>> search({
    required String table,
    required String column,
    required String searchTerm,
    String? select,
    int? limit,
  }) async {
    try {
      var query = _client
          .from(table)
          .select(select ?? '*')
          .textSearch(column, searchTerm);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching in $table: $e');
      rethrow;
    }
  }

  // Listen to real-time changes
  static RealtimeChannel subscribeToTable({
    required String table,
    required void Function(PostgresChangePayload) onData,
    PostgresChangeEvent? event,
    String? schema,
  }) {
    final channel = _client
        .channel('$table-changes')
        .onPostgresChanges(
          event: event ?? PostgresChangeEvent.all,
          schema: schema ?? 'public',
          table: table,
          callback: onData,
        )
        .subscribe();

    return channel;
  }

  // Unsubscribe from real-time changes
  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  // Execute a custom query
  static Future<List<Map<String, dynamic>>> executeQuery(String query) async {
    try {
      final response = await _client.rpc(query);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error executing query: $e');
      rethrow;
    }
  }

  // File storage operations
  static Future<String?> uploadFile({
    required String bucket,
    required String path,
    required List<int> fileBytes,
    String? mimeType,
  }) async {
    try {
      await _client.storage.from(bucket).uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Delete a file
  static Future<bool> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _client.storage.from(bucket).remove([path]);
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Get public URL for a file
  static String getFileUrl({
    required String bucket,
    required String path,
  }) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}
