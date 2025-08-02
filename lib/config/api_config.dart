class ApiConfig {
  ApiConfig._();

  // Current Firebase Functions URL
  static const String functionBaseUrl =
      'https://europe-west3-kviktime-9ee5f.cloudfunctions.net/api';

  // Future Custom Domain URL (after DNS setup)
  // static const String functionBaseUrl = 'https://api.kviktime.se';

  // Add other API configuration constants here
  static const int timeoutSeconds = 30;
  static const String apiVersion = 'v1';
}
