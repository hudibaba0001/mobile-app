import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Theme state holder.
///
/// Single source of truth for theme mode and text scaling preferences.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  double _textScaleFactor = 1.0;

  ThemeMode get themeMode => _themeMode;
  double get textScaleFactor => _textScaleFactor;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _updateSystemUI();
    notifyListeners();
  }

  void setTextScaleFactor(double factor) {
    final clamped = factor.clamp(0.9, 1.2);
    if (_textScaleFactor == clamped) return;
    _textScaleFactor = clamped;
    notifyListeners();
  }

  void resetToDefaults() {
    _themeMode = ThemeMode.system;
    _textScaleFactor = 1.0;
    _updateSystemUI();
    notifyListeners();
  }

  String get themeModeDisplayName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _updateSystemUI() {
    final brightness = _themeMode == ThemeMode.dark
        ? Brightness.dark
        : _themeMode == ThemeMode.light
            ? Brightness.light
            : WidgetsBinding.instance.platformDispatcher.platformBrightness;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}
