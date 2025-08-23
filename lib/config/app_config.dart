import 'package:flutter/foundation.dart';

class AppConfig {
  /// Example: https://europe-west3-<PROJECT_ID>.cloudfunctions.net
  /// Leave empty to keep using local analytics only.
  static String _apiBase =
      const String.fromEnvironment('KVIKTIME_API_BASE', defaultValue: '');

  static String get apiBase => _apiBase;

  @visibleForTesting
  static void setApiBase(String value) {
    _apiBase = value;
  }
}
