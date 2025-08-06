import 'package:flutter/material.dart';

class AppTheme {
  // Modern Color Palette
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueLight = Color(0xFF3B82F6);
  static const Color primaryBlueDark = Color(0xFF1D4ED8);

  static const Color secondaryTeal = Color(0xFF0D9488);
  static const Color secondaryTealLight = Color(0xFF14B8A6);
  static const Color secondaryTealDark = Color(0xFF0F766E);

  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentOrangeLight = Color(0xFFFBBF24);
  static const Color accentOrangeDark = Color(0xFFD97706);

  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningYellow = Color(0xFFF59E0B);

  // Neutral Colors
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      primaryContainer: Color(0xFFDBEAFE),
      secondary: secondaryTeal,
      secondaryContainer: Color(0xFFCCFBF1),
      tertiary: accentOrange,
      tertiaryContainer: Color(0xFFFEF3C7),
      surface: Colors.white,
      background: neutral50,
      error: errorRed,
      errorContainer: Color(0xFFFEE2E2),
      onPrimary: Colors.white,
      onPrimaryContainer: primaryBlueDark,
      onSecondary: Colors.white,
      onSecondaryContainer: secondaryTealDark,
      onTertiary: Colors.white,
      onTertiaryContainer: accentOrangeDark,
      onSurface: neutral900,
      onSurfaceVariant: neutral700,
      onBackground: neutral900,
      onError: Colors.white,
      onErrorContainer: errorRed,
      outline: neutral300,
      outlineVariant: neutral200,
      shadow: Color(0x1A000000),
      scrim: Color(0x52000000),
      inverseSurface: neutral800,
      inversePrimary: primaryBlueLight,
      surfaceTint: primaryBlue,
    ),
    textTheme: _buildTextTheme(neutral900),
    elevatedButtonTheme: _buildElevatedButtonTheme(),
    outlinedButtonTheme: _buildOutlinedButtonTheme(),
    textButtonTheme: _buildTextButtonTheme(),
    cardTheme: _buildCardTheme(),
    inputDecorationTheme: _buildInputDecorationTheme(),
    appBarTheme: _buildAppBarTheme(),
    bottomNavigationBarTheme: _buildBottomNavigationBarTheme(),
    floatingActionButtonTheme: _buildFloatingActionButtonTheme(),
    dialogTheme: _buildDialogTheme(),
    snackBarTheme: _buildSnackBarTheme(),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlueLight,
      primaryContainer: Color(0xFF1E3A8A),
      secondary: secondaryTealLight,
      secondaryContainer: Color(0xFF134E4A),
      tertiary: accentOrangeLight,
      tertiaryContainer: Color(0xFF92400E),
      surface: neutral900,
      background: neutral900,
      error: Color(0xFFF87171),
      errorContainer: Color(0xFF7F1D1D),
      onPrimary: neutral900,
      onPrimaryContainer: primaryBlueLight,
      onSecondary: neutral900,
      onSecondaryContainer: secondaryTealLight,
      onTertiary: neutral900,
      onTertiaryContainer: accentOrangeLight,
      onSurface: neutral100,
      onSurfaceVariant: neutral200,
      onBackground: neutral100,
      onError: neutral900,
      onErrorContainer: Color(0xFFFCA5A5),
      outline: neutral600,
      outlineVariant: neutral700,
      shadow: Color(0x1A000000),
      scrim: Color(0x52000000),
      inverseSurface: neutral100,
      inversePrimary: primaryBlueDark,
      surfaceTint: primaryBlueLight,
    ),
    textTheme: _buildTextTheme(neutral100),
    elevatedButtonTheme: _buildElevatedButtonTheme(),
    outlinedButtonTheme: _buildOutlinedButtonTheme(),
    textButtonTheme: _buildTextButtonTheme(),
    cardTheme: _buildCardTheme(),
    inputDecorationTheme: _buildInputDecorationTheme(),
    appBarTheme: _buildAppBarTheme(),
    bottomNavigationBarTheme: _buildBottomNavigationBarTheme(),
    floatingActionButtonTheme: _buildFloatingActionButtonTheme(),
    dialogTheme: _buildDialogTheme(),
    snackBarTheme: _buildSnackBarTheme(),
  );

  // Text Theme
  static TextTheme _buildTextTheme(Color onSurface) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: onSurface,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: onSurface,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: onSurface,
      ),
    );
  }

  // Elevated Button Theme
  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        shadowColor: const Color(0x1A000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  // Outlined Button Theme
  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        side: const BorderSide(width: 1.5),
      ),
    );
  }

  // Text Button Theme
  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  // Card Theme
  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      elevation: 4,
      shadowColor: const Color(0x1A000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    );
  }

  // Input Decoration Theme
  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
      ),
    );
  }

  // App Bar Theme
  static AppBarTheme _buildAppBarTheme() {
    return const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    );
  }

  // Bottom Navigation Bar Theme
  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme() {
    return const BottomNavigationBarThemeData(
      elevation: 8,
      backgroundColor: Colors.transparent,
      selectedItemColor: Colors.transparent,
      unselectedItemColor: Colors.transparent,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    );
  }

  // Floating Action Button Theme
  static FloatingActionButtonThemeData _buildFloatingActionButtonTheme() {
    return const FloatingActionButtonThemeData(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    );
  }

  // Dialog Theme
  static DialogThemeData _buildDialogTheme() {
    return DialogThemeData(
      elevation: 24,
      shadowColor: const Color(0x52000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  // Snack Bar Theme
  static SnackBarThemeData _buildSnackBarTheme() {
    return SnackBarThemeData(
      elevation: 6,
      backgroundColor: Colors.transparent,
      contentTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.25,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    );
  }
}
