class ApiConfig {
  ApiConfig._();

  static const String functionBaseUrl =
      'https://us-central1-travel-time-logger.cloudfunctions.net/api';

  // Add other API configuration constants here
  static const int timeoutSeconds = 30;
  static const String apiVersion = 'v1';
}
