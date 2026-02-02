import 'package:flutter/material.dart';
import '../design/app_theme.dart';

// Re-export design system for consistent access
export '../design/design.dart';

/// Legacy AppTheme wrapper.
///
/// Keeps existing imports working while delegating to the design system.
class AppTheme {
  static ThemeData get lightTheme => AppThemeData.light();
  static ThemeData get darkTheme => AppThemeData.dark();
}
