class ApiConfig {
  ApiConfig._();

  // Current API URL (update with your Supabase Edge Functions URL if needed)
  static const String functionBaseUrl =
      'https://your-project-id.supabase.co/functions/v1';

  // Future Custom Domain URL (after DNS setup)
  // static const String functionBaseUrl = 'https://api.kviktime.se';

  // Add other API configuration constants here
  static const int timeoutSeconds = 30;
  static const String apiVersion = 'v1';
}
