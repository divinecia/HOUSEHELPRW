import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  print('🏠 Testing HouseHelp Supabase Connection...');
  print('Project URL: https://ptqsxaewfmebptcuoptc.supabase.co');

  // Initialize Supabase client
  final client = SupabaseClient(
    'https://ptqsxaewfmebptcuoptc.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB0cXN4YWV3Zm1lYnB0Y3VvcHRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzMwNzUzOTEsImV4cCI6MjA0ODY1MTM5MX0.QMPOL1JvBT6pjwvj7V5Lm1sJFwz7nCcGNl1rQP9Jbpc',
  );

  try {
    // Test basic connection - try to query the auth users
    print('📡 Testing connection...');

    // For testing, we'll try to access some basic functionality
    final response = await client.auth
        .signUp(email: 'test@example.com', password: 'testpassword123');

    if (response.user != null) {
      print('✅ Supabase connection successful!');
      print('Test user created: ${response.user!.email}');

      // Clean up - sign out
      await client.auth.signOut();
      print('🧹 Test user signed out');
    } else {
      print('⚠️  Connection established but signup failed');
      print('This might be expected if user already exists');
    }
  } catch (e) {
    print('❌ Connection error: $e');

    // More basic test
    print('🔄 Trying basic REST endpoint...');
    try {
      final response = await client.from('_realtime').select().limit(1);
      print('✅ Basic REST connection working');
    } catch (restError) {
      print('❌ REST error: $restError');
    }
  }

  print('\n📋 Next steps:');
  print('1. Deploy database schema manually via Supabase dashboard');
  print('2. Test Flutter app with actual Supabase backend');
  print('3. Create admin user for testing');

  exit(0);
}
