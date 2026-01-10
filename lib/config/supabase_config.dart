import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Replace these with your actual Supabase URL and anon key
  // Get these from your Supabase project dashboard > Settings > API
  static const String url = 'https://ywytjssxfbotslurtqko.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3eXRqc3N4ZmJvdHNsdXJ0cWtvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY4MTc4NDgsImV4cCI6MjA4MjM5Mzg0OH0.deFQPLasebYd9tHOnBpvaQh8iEJVn3j5IJdRyStVV-0';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}
