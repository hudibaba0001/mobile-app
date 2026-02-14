import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app locale (language) settings.
/// Supports System default, English, and Swedish.
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'locale_code';
  static const String _systemLocaleValue = 'system';
  static const Locale _defaultLocale = Locale('sv');

  Locale? _locale; // null = system default
  bool _isInitialized = false;

  /// Current locale. Null means use system default.
  Locale? get locale => _locale;

  /// Whether initialization is complete
  bool get isInitialized => _isInitialized;

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('sv'), // Swedish
  ];

  /// Get display name for a locale
  static String getDisplayName(Locale? locale) {
    if (locale == null) return 'System default';
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'sv':
        return 'Svenska';
      default:
        return locale.languageCode;
    }
  }

  /// Initialize from SharedPreferences.
  /// Defaults to Swedish unless user has explicitly selected another locale.
  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getString(_localeKey);

    if (storedValue == _systemLocaleValue) {
      _locale = null;
    } else if (storedValue != null && storedValue.isNotEmpty) {
      final storedLocale = Locale(storedValue);
      if (_isSupported(storedLocale)) {
        _locale = storedLocale;
      } else {
        _locale = _defaultLocale;
        await prefs.setString(_localeKey, _defaultLocale.languageCode);
      }
    } else {
      _locale = _defaultLocale;
      await prefs.setString(_localeKey, _defaultLocale.languageCode);
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Check if a locale is in the supported list
  bool _isSupported(Locale locale) {
    return supportedLocales.any((l) => l.languageCode == locale.languageCode);
  }

  /// Set locale and persist
  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.setString(_localeKey, _systemLocaleValue);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
  }

  /// Check if using system locale
  bool get isSystemDefault => _locale == null;

  /// Get current locale code (or null for system)
  String? get localeCode => _locale?.languageCode;
}
