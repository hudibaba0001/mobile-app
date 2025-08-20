class AppConfig {
  /// Example: https://europe-west3-<PROJECT_ID>.cloudfunctions.net
  /// Leave empty to keep using local analytics only.
  static const String apiBase =
      String.fromEnvironment('KVIKTIME_API_BASE', defaultValue: '');
}
