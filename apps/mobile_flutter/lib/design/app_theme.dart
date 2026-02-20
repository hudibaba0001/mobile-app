import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const List<FontFeature> _tabularFigures = [FontFeature.tabularFigures()];
final String? _headerFontFamily = GoogleFonts.dmSans().fontFamily;

/// Design System - Single Source of Truth
///
/// This file defines the core design tokens and theme data for the app.
/// All UI components should reference these values for consistency.

// =============================================================================
// DESIGN TOKENS
// =============================================================================

/// Spacing tokens for consistent padding/margins throughout the app.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  /// Standard page padding
  static const EdgeInsets pagePadding = EdgeInsets.all(lg);

  /// List tile padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );

  /// Sheet padding
  static const EdgeInsets sheetPadding = EdgeInsets.fromLTRB(
    lg,
    md,
    lg,
    lg,
  );

  /// Dialog padding
  static const EdgeInsets dialogPadding = EdgeInsets.all(lg);

  /// Card internal padding
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  /// Section spacing (between cards/sections)
  static const double sectionGap = xl;

  /// Standard list tile height
  static const double tileHeight = 72.0;
}

/// Border radius tokens for consistent rounded corners.
class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;

  static BorderRadius get cardRadius => BorderRadius.circular(lg);
  static BorderRadius get buttonRadius => BorderRadius.circular(md);
  static BorderRadius get chipRadius => BorderRadius.circular(sm);
  static BorderRadius get pillRadius => BorderRadius.circular(xl);
}

/// Icon size tokens for consistent iconography.
class AppIconSize {
  AppIconSize._();

  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
}

/// Semantic colors for Flexsaldo display (muted for field worker readability).
class FlexsaldoColors {
  FlexsaldoColors._();

  /// Positive balance (worked more than target) - muted green
  static const Color positive = Color(0xFF22C55E);
  static const Color positiveLight = Color(0xFFDCFCE7);
  static const Color positiveDark = Color(0xFF16A34A);

  /// Negative balance (worked less than target) - muted amber/orange
  static const Color negative = Color(0xFFF59E0B);
  static const Color negativeLight = Color(0xFFFEF3C7);
  static const Color negativeDark = Color(0xFFD97706);

  /// Neutral (exactly on target)
  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralLight = Color(0xFFF3F4F6);
}

/// Absence type colors (single source for leave UI)
class AbsenceColors {
  AbsenceColors._();

  static const Color paidVacation = AppColors.primary;
  static const Color sickLeave = AppColors.error;
  static const Color vab = AppColors.accent;
  static const Color unpaid = AppColors.neutral500;
}

/// Entry type colors (single source for time entry UI)
class EntryColors {
  EntryColors._();

  static const Color travel = AppColors.primary;
  static const Color work = AppColors.secondary;
  static const Color absence = AppColors.accent;
}

// =============================================================================
// COLOR PALETTE
// =============================================================================

class AppColors {
  AppColors._();

  // Light surface base (Warm cream for light mode background)
  static const Color lightSurface = Color(0xFFFAF8F5);

  // Primary (Forest green)
  static const Color primary = Color(0xFF1F6B4E);
  static const Color primaryLight = Color(0xFF2F8C66);
  static const Color primaryDark = Color(0xFF174E39);
  static const Color primaryContainer = Color(0xFFD8ECE2);

  // Secondary (Deep teal-green)
  static const Color secondary = Color(0xFF1F7A67);
  static const Color secondaryLight = Color(0xFF2A927C);
  static const Color secondaryDark = Color(0xFF145746);
  static const Color secondaryContainer = Color(0xFFD8F1EA);

  // Accent (Orange)
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentContainer = Color(0xFFFEF3C7);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);
  // Slightly darker red for AA contrast on light surfaces.
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);

  // Neutrals (Gray scale)
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  // Dark-mode variant of neutral500 with WCAG AA contrast on darkSurface.
  // Contrast against #121212: ~4.97:1
  static const Color neutral500Dark = Color(0xFF7C8491);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);

  // Dark mode surface colors
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceVariant = Color(0xFF1E1E1E);
  static const Color darkSurfaceElevated = Color(0xFF2D2D2D);

  // Gradient colors (Login/Auth screens)
  static const Color gradientStart = Color(0xFF1F6B4E);
  static const Color gradientMid = Color(0xFF1A4F3B);
  static const Color gradientEnd = Color(0xFF2F8C66);

  static Color mutedForeground(Brightness brightness) =>
      brightness == Brightness.dark ? neutral500Dark : neutral500;
}

// =============================================================================
// TYPOGRAPHY
// =============================================================================

class AppTypography {
  AppTypography._();

  /// Large hero numbers (Flexsaldo value)
  static TextStyle headline(Color color) => TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: color,
        height: 1.15,
        fontFeatures: _tabularFigures,
        fontFamily: _headerFontFamily,
      );

  /// Section titles
  static TextStyle sectionTitle(Color color) => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: color,
        height: 1.3,
        fontFamily: _headerFontFamily,
      );

  /// Card titles
  static TextStyle cardTitle(Color color) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color,
        height: 1.35,
        fontFamily: _headerFontFamily,
      );

  /// Body text
  static TextStyle body(Color color) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: color,
        height: 1.5,
      );

  /// Small caption text
  static TextStyle caption(Color color) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: color,
        height: 1.4,
      );

  /// Button text
  static TextStyle button(Color color) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: color,
        height: 1.0,
      );

  /// Metric value (numbers in cards)
  static TextStyle metricValue(Color color) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: color,
        height: 1.2,
        fontFeatures: _tabularFigures,
        fontFamily: _headerFontFamily,
      );

  /// Metric label (description under metric)
  static TextStyle metricLabel(Color color) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: color,
        height: 1.3,
      );
}

// =============================================================================
// THEME DATA
// =============================================================================

class AppThemeData {
  AppThemeData._();

  /// Light theme
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryContainer,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.secondaryContainer,
      tertiary: AppColors.accent,
      tertiaryContainer: AppColors.accentContainer,
      surface: AppColors.lightSurface,
      error: AppColors.error,
      errorContainer: AppColors.errorContainer,
      onPrimary: Colors.white,
      onPrimaryContainer: AppColors.primaryDark,
      onSecondary: Colors.white,
      onSecondaryContainer: AppColors.secondaryDark,
      onTertiary: Colors.white,
      onTertiaryContainer: AppColors.accentDark,
      onSurface: AppColors.neutral900,
      onSurfaceVariant: AppColors.neutral700,
      onError: Colors.white,
      onErrorContainer: AppColors.error,
      outline: AppColors.neutral300,
      outlineVariant: AppColors.neutral200,
      shadow: Color(0x1A000000),
      scrim: Color(0x52000000),
      inverseSurface: AppColors.neutral800,
      inversePrimary: AppColors.primaryLight,
      surfaceTint: AppColors.primary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.lightSurface,
      visualDensity: VisualDensity.standard,
      textTheme: _buildTextTheme(AppColors.neutral900),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      cardTheme: _buildCardTheme(scheme),
      inputDecorationTheme: _buildInputDecorationTheme(scheme),
      appBarTheme: _buildAppBarTheme(scheme.onSurface),
      bottomNavigationBarTheme:
          _buildBottomNavigationBarTheme(Brightness.light),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(),
      dialogTheme: _buildDialogTheme(),
      timePickerTheme: _buildTimePickerTheme(),
      snackBarTheme: _buildSnackBarTheme(),
      chipTheme: _buildChipTheme(),
      listTileTheme: _buildListTileTheme(AppColors.neutral700),
      dividerTheme: _buildDividerTheme(AppColors.neutral200),
      segmentedButtonTheme: _buildSegmentedButtonTheme(),
      navigationBarTheme: _buildNavigationBarTheme(),
      bottomSheetTheme: _buildBottomSheetTheme(),
    );
  }

  /// Dark theme (primary focus for field workers)
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.primaryLight,
      primaryContainer: Color(0xFF123629),
      secondary: AppColors.secondaryLight,
      secondaryContainer: Color(0xFF123A32),
      tertiary: AppColors.accentLight,
      tertiaryContainer: Color(0xFF92400E),
      surface: AppColors.darkSurface,
      error: Color(0xFFF87171),
      errorContainer: Color(0xFF7F1D1D),
      onPrimary: Colors.white,
      onPrimaryContainer: AppColors.primaryLight,
      onSecondary: Colors.white,
      onSecondaryContainer: AppColors.secondaryLight,
      onTertiary: AppColors.neutral900,
      onTertiaryContainer: AppColors.accentLight,
      onSurface: AppColors.neutral100,
      onSurfaceVariant: AppColors.neutral200,
      onError: AppColors.neutral900,
      onErrorContainer: Color(0xFFFCA5A5),
      outline: AppColors.neutral600,
      outlineVariant: AppColors.neutral700,
      shadow: Color(0x1A000000),
      scrim: Color(0x52000000),
      inverseSurface: AppColors.neutral100,
      inversePrimary: AppColors.primaryDark,
      surfaceTint: AppColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkSurface,
      visualDensity: VisualDensity.standard,
      textTheme: _buildTextTheme(AppColors.neutral100),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      cardTheme: _buildCardTheme(scheme),
      inputDecorationTheme: _buildInputDecorationTheme(scheme),
      appBarTheme: _buildAppBarTheme(scheme.onSurface),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(Brightness.dark),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(),
      dialogTheme: _buildDialogTheme(),
      timePickerTheme: _buildTimePickerTheme(),
      snackBarTheme: _buildSnackBarTheme(),
      chipTheme: _buildChipTheme(),
      listTileTheme: _buildListTileTheme(AppColors.neutral200),
      dividerTheme: _buildDividerTheme(AppColors.neutral700),
      segmentedButtonTheme: _buildSegmentedButtonTheme(),
      navigationBarTheme: _buildNavigationBarTheme(),
      bottomSheetTheme: _buildBottomSheetTheme(),
    );
  }

  // ---------------------------------------------------------------------------
  // Private theme builders
  // ---------------------------------------------------------------------------

  static TextTheme _buildTextTheme(Color onSurface) {
    TextStyle style({
      required double size,
      required FontWeight weight,
      required double height,
      double letterSpacing = 0,
      String? fontFamily,
    }) {
      return TextStyle(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: onSurface,
        fontFeatures: _tabularFigures,
        fontFamily: fontFamily,
      );
    }

    return TextTheme(
      displayLarge: style(
          size: 34,
          weight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -0.2,
          fontFamily: _headerFontFamily),
      displayMedium: style(
          size: 28,
          weight: FontWeight.w700,
          height: 1.15,
          letterSpacing: -0.1,
          fontFamily: _headerFontFamily),
      displaySmall: style(
          size: 24,
          weight: FontWeight.w600,
          height: 1.2,
          letterSpacing: -0.1,
          fontFamily: _headerFontFamily),
      headlineLarge: style(
          size: 22,
          weight: FontWeight.w600,
          height: 1.2,
          fontFamily: _headerFontFamily),
      headlineMedium: style(
          size: 20,
          weight: FontWeight.w600,
          height: 1.25,
          fontFamily: _headerFontFamily),
      headlineSmall: style(
          size: 18,
          weight: FontWeight.w600,
          height: 1.3,
          fontFamily: _headerFontFamily),
      titleLarge: style(
          size: 17,
          weight: FontWeight.w600,
          height: 1.35,
          fontFamily: _headerFontFamily),
      titleMedium: style(
          size: 15,
          weight: FontWeight.w600,
          height: 1.35,
          letterSpacing: 0.1,
          fontFamily: _headerFontFamily),
      titleSmall: style(
          size: 13,
          weight: FontWeight.w600,
          height: 1.35,
          letterSpacing: 0.1,
          fontFamily: _headerFontFamily),
      bodyLarge: style(
          size: 15, weight: FontWeight.w400, height: 1.5, letterSpacing: 0.2),
      bodyMedium: style(
          size: 14, weight: FontWeight.w400, height: 1.5, letterSpacing: 0.2),
      bodySmall: style(
          size: 12, weight: FontWeight.w400, height: 1.4, letterSpacing: 0.2),
      labelLarge: style(
          size: 13, weight: FontWeight.w600, height: 1.2, letterSpacing: 0.3),
      labelMedium: style(
          size: 12, weight: FontWeight.w600, height: 1.2, letterSpacing: 0.3),
      labelSmall: style(
          size: 11, weight: FontWeight.w600, height: 1.2, letterSpacing: 0.3),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        side: const BorderSide(width: 1),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  static CardThemeData _buildCardTheme(ColorScheme scheme) {
    return CardThemeData(
      color: scheme.surface,
      elevation: 0,
      shadowColor: scheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
        side: BorderSide(
          color: scheme.outlineVariant,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.lg,
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(ColorScheme scheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      isDense: true,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: BorderSide(width: 1, color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: BorderSide(width: 1, color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: BorderSide(width: 1.5, color: scheme.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: BorderSide(width: 1, color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide: BorderSide(width: 1.5, color: scheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      hintStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: scheme.onSurfaceVariant,
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: scheme.onSurfaceVariant,
      ),
      errorStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: scheme.error,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(Color foregroundColor) {
    return AppBarTheme(
      elevation: 0,
      centerTitle: false,
      titleSpacing: AppSpacing.lg,
      toolbarHeight: 56,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: foregroundColor,
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: foregroundColor,
      surfaceTintColor: Colors.transparent,
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme(
      Brightness brightness) {
    return BottomNavigationBarThemeData(
      elevation: 8,
      backgroundColor: Colors.transparent,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.mutedForeground(brightness),
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );
  }

  static FloatingActionButtonThemeData _buildFloatingActionButtonTheme() {
    return FloatingActionButtonThemeData(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
      ),
    );
  }

  static DialogThemeData _buildDialogTheme() {
    return DialogThemeData(
      elevation: 24,
      shadowColor: const Color(0x52000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    );
  }

  static TimePickerThemeData _buildTimePickerTheme() {
    const pickerTextStyle = TextStyle(
      fontSize: 52,
      fontWeight: FontWeight.w500,
      height: 1.0,
      letterSpacing: 0,
      fontFeatures: _tabularFigures,
    );

    return const TimePickerThemeData(
      hourMinuteTextStyle: pickerTextStyle,
      dayPeriodTextStyle: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 1.0,
        letterSpacing: 0,
      ),
      timeSelectorSeparatorTextStyle: WidgetStatePropertyAll(pickerTextStyle),
    );
  }

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
        borderRadius: AppRadius.buttonRadius,
      ),
      behavior: SnackBarBehavior.floating,
    );
  }

  static ChipThemeData _buildChipTheme() {
    return ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.chipRadius,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static ListTileThemeData _buildListTileTheme(Color iconColor) {
    return ListTileThemeData(
      contentPadding: AppSpacing.listItemPadding,
      minVerticalPadding: AppSpacing.sm,
      horizontalTitleGap: AppSpacing.md,
      iconColor: iconColor,
    );
  }

  static DividerThemeData _buildDividerTheme(Color color) {
    return DividerThemeData(
      color: color,
      thickness: 1,
      space: AppSpacing.lg,
    );
  }

  static SegmentedButtonThemeData _buildSegmentedButtonTheme() {
    return SegmentedButtonThemeData(
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
        ),
      ),
    );
  }

  static NavigationBarThemeData _buildNavigationBarTheme() {
    return NavigationBarThemeData(
      height: 68,
      indicatorColor: AppColors.primaryContainer,
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
    );
  }

  static BottomSheetThemeData _buildBottomSheetTheme() {
    return const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
    );
  }
}
