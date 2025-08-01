import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ptqsxaewfmebptcuoptc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB0cXN4YWV3Zm1lYnB0Y3VvcHRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzMwNzUzOTEsImV4cCI6MjA0ODY1MTM5MX0.QMPOL1JvBT6pjwvj7V5Lm1sJFwz7nCcGNl1rQP9Jbpc',
  );

  print('🏠 Testing HouseHelp Supabase Connection...');
  print('Project URL: https://ptqsxaewfmebptcuoptc.supabase.co');

  try {
    // Test basic connection
    final client = Supabase.instance.client;

    // Try to create a simple table for testing
    final response = await client.rpc('get_schema_version');
    print('✅ Connection successful!');
    print('Response: $response');
  } catch (e) {
    print('❌ Connection error: $e');

    // Try a simpler test - check auth status
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      print('📊 Auth status: ${user != null ? 'Authenticated' : 'Anonymous'}');
      print('✅ Basic Supabase client initialized successfully');
    } catch (authError) {
      print('❌ Auth error: $authError');
    }
  }

  print('\n🔗 Ready to deploy database schema...');
  exit(0);
}
