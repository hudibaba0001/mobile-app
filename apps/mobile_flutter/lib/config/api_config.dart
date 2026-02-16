import 'supabase_config.dart';

class ApiConfig {
  ApiConfig._();

  // Override in CI/prod with:
  // --dart-define=SUPABASE_FUNCTIONS_URL=https://<project-ref>.supabase.co/functions/v1
  static const String functionBaseUrl = String.fromEnvironment(
    'SUPABASE_FUNCTIONS_URL',
    defaultValue: '${SupabaseConfig.url}/functions/v1',
  );

  // Add other API configuration constants here
  static const int timeoutSeconds = 30;
  static const String apiVersion = 'v1';
}
