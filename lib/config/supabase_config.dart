import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Supabase project credentials
  static const String supabaseUrl = 'https://ptqsxaewfmebptcuoptc.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB0cXN4YWV3Zm1lYnB0Y3VvcHRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQwNDQwOTUsImV4cCI6MjA2OTYyMDA5NX0.7pHEKlFsGnDZP0-wQVtYo6Aj5cHiOxWW2mkTyf9VUj0';

  static late SupabaseClient client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
    );
    client = Supabase.instance.client;
  }

  static SupabaseClient get instance => client;
}

// Global access to Supabase client
final supabase = SupabaseConfig.instance;
