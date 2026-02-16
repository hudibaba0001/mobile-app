import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Override in CI/prod with:
  // --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co
  // --dart-define=SUPABASE_ANON_KEY=<anon-key>
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ywytjssxfbotslurtqko.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3eXRqc3N4ZmJvdHNsdXJ0cWtvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY4MTc4NDgsImV4cCI6MjA4MjM5Mzg0OH0.deFQPLasebYd9tHOnBpvaQh8iEJVn3j5IJdRyStVV-0',
  );

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Supabase configuration is missing. '
        'Set SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}
