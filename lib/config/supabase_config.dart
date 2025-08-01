import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Replace these with your actual Supabase project URL and anon key
  static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

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
