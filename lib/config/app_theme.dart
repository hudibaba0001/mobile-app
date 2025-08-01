import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Color schemes
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1976D2),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFBBDEFB),
    onPrimaryContainer: Color(0xFF0D47A1),
    secondary: Color(0xFF03DAC6),
    onSecondary: Color(0xFF000000),
    secondaryContainer: Color(0xFFB2DFDB),
    onSecondaryContainer: Color(0xFF004D40),
    tertiary: Color(0xFFFF9800),
    onTertiary: Color(0xFF000000),
    tertiaryContainer: Color(0xFFFFE0B2),
    onTertiaryContainer: Color(0xFFE65100),
    error: Color(0xFFD32F2F),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFCDD2),
    onErrorContainer: Color(0xFFB71C1C),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF212121),
    surfaceContainerHighest: Color(0xFFF5F5F5),
    onSurfaceVariant: Color(0xFF424242),
    outline: Color(0xFF9E9E9E),
    outlineVariant: Color(0xFFE0E0E0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF303030),
    onInverseSurface: Color(0xFFFFFFFF),
    inversePrimary: Color(0xFF90CAF9),
    surfaceTint: Color(0xFF1976D2),
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF90CAF9),
    onPrimary: Color(0xFF0D47A1),
    primaryContainer: Color(0xFF1565C0),
    onPrimaryContainer: Color(0xFFE3F2FD),
    secondary: Color(0xFF80CBC4),
    onSecondary: Color(0xFF004D40),
    secondaryContainer: Color(0xFF00695C),
    onSecondaryContainer: Color(0xFFB2DFDB),
    tertiary: Color(0xFFFFB74D),
    onTertiary: Color(0xFFE65100),
    tertiaryContainer: Color(0xFFFF8F00),
    onTertiaryContainer: Color(0xFFFFF3E0),
    error: Color(0xFFEF5350),
    onError: Color(0xFFB71C1C),
    errorContainer: Color(0xFFC62828),
    onErrorContainer: Color(0xFFFFEBEE),
    surface: Color(0xFF1E1E1E),
    onSurface: Color(0xFFE0E0E0),
    surfaceContainerHighest: Color(0xFF2C2C2C),
    onSurfaceVariant: Color(0xFFBDBDBD),
    outline: Color(0xFF757575),
    outlineVariant: Color(0xFF424242),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE0E0E0),
    onInverseSurface: Color(0xFF303030),
    inversePrimary: Color(0xFF1976D2),
    surfaceTint: Color(0xFF90CAF9),
  );

  // Typography
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.22,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.33,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.50,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      height: 1.50,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
    ),
  );

  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      textTheme: _textTheme,
      appBarTheme: _lightAppBarTheme,
      cardTheme: _lightCardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      floatingActionButtonTheme: _lightFabTheme,
      inputDecorationTheme: _lightInputDecorationTheme,
      chipTheme: _lightChipTheme,
      dividerTheme: _lightDividerTheme,
      listTileTheme: _lightListTileTheme,
      navigationBarTheme: _lightNavigationBarTheme,
      bottomSheetTheme: _lightBottomSheetTheme,
      dialogTheme: _lightDialogTheme,
      snackBarTheme: _lightSnackBarTheme,
      switchTheme: _lightSwitchTheme,
      checkboxTheme: _lightCheckboxTheme,
      radioTheme: _lightRadioTheme,
      sliderTheme: _lightSliderTheme,
      progressIndicatorTheme: _lightProgressIndicatorTheme,
      tabBarTheme: _lightTabBarTheme,
      tooltipTheme: _lightTooltipTheme,
      popupMenuTheme: _lightPopupMenuTheme,
      iconTheme: _lightIconTheme,
      primaryIconTheme: _lightPrimaryIconTheme,
    );
  }

  // Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      textTheme: _textTheme,
      appBarTheme: _darkAppBarTheme,
      cardTheme: _darkCardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      floatingActionButtonTheme: _darkFabTheme,
      inputDecorationTheme: _darkInputDecorationTheme,
      chipTheme: _darkChipTheme,
      dividerTheme: _darkDividerTheme,
      listTileTheme: _darkListTileTheme,
      navigationBarTheme: _darkNavigationBarTheme,
      bottomSheetTheme: _darkBottomSheetTheme,
      dialogTheme: _darkDialogTheme,
      snackBarTheme: _darkSnackBarTheme,
      switchTheme: _darkSwitchTheme,
      checkboxTheme: _darkCheckboxTheme,
      radioTheme: _darkRadioTheme,
      sliderTheme: _darkSliderTheme,
      progressIndicatorTheme: _darkProgressIndicatorTheme,
      tabBarTheme: _darkTabBarTheme,
      tooltipTheme: _darkTooltipTheme,
      popupMenuTheme: _darkPopupMenuTheme,
      iconTheme: _darkIconTheme,
      primaryIconTheme: _darkPrimaryIconTheme,
    );
  }

  // AppBar themes
  static const AppBarTheme _lightAppBarTheme = AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 3,
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFF212121),
    surfaceTintColor: Color(0xFF1976D2),
    titleTextStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: Color(0xFF212121),
    ),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );

  static const AppBarTheme _darkAppBarTheme = AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 3,
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFFE0E0E0),
    surfaceTintColor: Color(0xFF90CAF9),
    titleTextStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: Color(0xFFE0E0E0),
    ),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  );

  // Card themes
  static const CardThemeData _lightCardTheme = CardThemeData(
    elevation: 1,
    shadowColor: Color(0x1F000000),
    surfaceTintColor: Color(0xFF1976D2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    margin: EdgeInsets.all(4),
  );

  static const CardThemeData _darkCardTheme = CardThemeData(
    elevation: 1,
    shadowColor: Color(0x1F000000),
    surfaceTintColor: Color(0xFF90CAF9),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    margin: EdgeInsets.all(4),
  );

  // Button themes
  static final ElevatedButtonThemeData _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 1,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      side: const BorderSide(width: 1),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    ),
  );

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    ),
  );

  // FAB themes
  static const FloatingActionButtonThemeData _lightFabTheme = FloatingActionButtonThemeData(
    elevation: 6,
    highlightElevation: 12,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );

  static const FloatingActionButtonThemeData _darkFabTheme = FloatingActionButtonThemeData(
    elevation: 6,
    highlightElevation: 12,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );

  // Input decoration themes
  static const InputDecorationTheme _lightInputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFF5F5F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFD32F2F)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFD32F2F), width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  static const InputDecorationTheme _darkInputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF2C2C2C),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF424242)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF424242)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF90CAF9), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFEF5350)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFEF5350), width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  // Chip themes
  static const ChipThemeData _lightChipTheme = ChipThemeData(
    backgroundColor: Color(0xFFF5F5F5),
    deleteIconColor: Color(0xFF757575),
    disabledColor: Color(0xFFE0E0E0),
    selectedColor: Color(0xFFBBDEFB),
    secondarySelectedColor: Color(0xFFB2DFDB),
    shadowColor: Color(0x1F000000),
    selectedShadowColor: Color(0x1F000000),
    showCheckmark: true,
    checkmarkColor: Color(0xFF0D47A1),
    labelPadding: EdgeInsets.symmetric(horizontal: 8),
    padding: EdgeInsets.all(4),
    side: BorderSide(color: Color(0xFFE0E0E0)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    labelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    secondaryLabelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    brightness: Brightness.light,
    elevation: 0,
    pressElevation: 1,
  );

  static const ChipThemeData _darkChipTheme = ChipThemeData(
    backgroundColor: Color(0xFF2C2C2C),
    deleteIconColor: Color(0xFFBDBDBD),
    disabledColor: Color(0xFF424242),
    selectedColor: Color(0xFF1565C0),
    secondarySelectedColor: Color(0xFF00695C),
    shadowColor: Color(0x1F000000),
    selectedShadowColor: Color(0x1F000000),
    showCheckmark: true,
    checkmarkColor: Color(0xFFE3F2FD),
    labelPadding: EdgeInsets.symmetric(horizontal: 8),
    padding: EdgeInsets.all(4),
    side: BorderSide(color: Color(0xFF424242)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    labelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    secondaryLabelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    brightness: Brightness.dark,
    elevation: 0,
    pressElevation: 1,
  );

  // Additional component themes
  static const DividerThemeData _lightDividerTheme = DividerThemeData(
    color: Color(0xFFE0E0E0),
    thickness: 1,
    space: 1,
  );

  static const DividerThemeData _darkDividerTheme = DividerThemeData(
    color: Color(0xFF424242),
    thickness: 1,
    space: 1,
  );

  static const ListTileThemeData _lightListTileTheme = ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );

  static const ListTileThemeData _darkListTileTheme = ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  );

  // Navigation themes
  static const NavigationBarThemeData _lightNavigationBarTheme = NavigationBarThemeData(
    elevation: 3,
    backgroundColor: Color(0xFFFFFFFF),
    surfaceTintColor: Color(0xFF1976D2),
    indicatorColor: Color(0xFFBBDEFB),
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  static const NavigationBarThemeData _darkNavigationBarTheme = NavigationBarThemeData(
    elevation: 3,
    backgroundColor: Color(0xFF1E1E1E),
    surfaceTintColor: Color(0xFF90CAF9),
    indicatorColor: Color(0xFF1565C0),
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  // Dialog and sheet themes
  static const BottomSheetThemeData _lightBottomSheetTheme = BottomSheetThemeData(
    backgroundColor: Color(0xFFFFFFFF),
    surfaceTintColor: Color(0xFF1976D2),
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  );

  static const BottomSheetThemeData _darkBottomSheetTheme = BottomSheetThemeData(
    backgroundColor: Color(0xFF1E1E1E),
    surfaceTintColor: Color(0xFF90CAF9),
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  );

  static const DialogThemeData _lightDialogTheme = DialogThemeData(
    backgroundColor: Color(0xFFFFFFFF),
    surfaceTintColor: Color(0xFF1976D2),
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );

  static const DialogThemeData _darkDialogTheme = DialogThemeData(
    backgroundColor: Color(0xFF1E1E1E),
    surfaceTintColor: Color(0xFF90CAF9),
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );

  // SnackBar themes
  static const SnackBarThemeData _lightSnackBarTheme = SnackBarThemeData(
    backgroundColor: Color(0xFF303030),
    contentTextStyle: TextStyle(color: Color(0xFFFFFFFF)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    behavior: SnackBarBehavior.floating,
    elevation: 6,
  );

  static const SnackBarThemeData _darkSnackBarTheme = SnackBarThemeData(
    backgroundColor: Color(0xFF424242),
    contentTextStyle: TextStyle(color: Color(0xFFFFFFFF)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    behavior: SnackBarBehavior.floating,
    elevation: 6,
  );

  // Form control themes
  static final SwitchThemeData _lightSwitchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF1976D2);
      }
      return const Color(0xFFFFFFFF);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFFBBDEFB);
      }
      return const Color(0xFFE0E0E0);
    }),
  );

  static final SwitchThemeData _darkSwitchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF90CAF9);
      }
      return const Color(0xFF424242);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF1565C0);
      }
      return const Color(0xFF757575);
    }),
  );

  static final CheckboxThemeData _lightCheckboxTheme = CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF1976D2);
      }
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(const Color(0xFFFFFFFF)),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
  );

  static final CheckboxThemeData _darkCheckboxTheme = CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF90CAF9);
      }
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(const Color(0xFF0D47A1)),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
  );

  static final RadioThemeData _lightRadioTheme = RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF1976D2);
      }
      return const Color(0xFF757575);
    }),
  );

  static final RadioThemeData _darkRadioTheme = RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF90CAF9);
      }
      return const Color(0xFFBDBDBD);
    }),
  );

  static const SliderThemeData _lightSliderTheme = SliderThemeData(
    activeTrackColor: Color(0xFF1976D2),
    inactiveTrackColor: Color(0xFFE0E0E0),
    thumbColor: Color(0xFF1976D2),
    overlayColor: Color(0x1F1976D2),
    valueIndicatorColor: Color(0xFF1976D2),
    valueIndicatorTextStyle: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  );

  static const SliderThemeData _darkSliderTheme = SliderThemeData(
    activeTrackColor: Color(0xFF90CAF9),
    inactiveTrackColor: Color(0xFF424242),
    thumbColor: Color(0xFF90CAF9),
    overlayColor: Color(0x1F90CAF9),
    valueIndicatorColor: Color(0xFF90CAF9),
    valueIndicatorTextStyle: TextStyle(
      color: Color(0xFF0D47A1),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  );

  static const ProgressIndicatorThemeData _lightProgressIndicatorTheme = ProgressIndicatorThemeData(
    color: Color(0xFF1976D2),
    linearTrackColor: Color(0xFFE0E0E0),
    circularTrackColor: Color(0xFFE0E0E0),
  );

  static const ProgressIndicatorThemeData _darkProgressIndicatorTheme = ProgressIndicatorThemeData(
    color: Color(0xFF90CAF9),
    linearTrackColor: Color(0xFF424242),
    circularTrackColor: Color(0xFF424242),
  );

  // Tab bar themes
  static const TabBarThemeData _lightTabBarTheme = TabBarThemeData(
    labelColor: Color(0xFF1976D2),
    unselectedLabelColor: Color(0xFF757575),
    indicatorColor: Color(0xFF1976D2),
    indicatorSize: TabBarIndicatorSize.label,
    labelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    unselectedLabelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
  );

  static const TabBarThemeData _darkTabBarTheme = TabBarThemeData(
    labelColor: Color(0xFF90CAF9),
    unselectedLabelColor: Color(0xFFBDBDBD),
    indicatorColor: Color(0xFF90CAF9),
    indicatorSize: TabBarIndicatorSize.label,
    labelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    unselectedLabelStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
  );

  // Tooltip themes
  static const TooltipThemeData _lightTooltipTheme = TooltipThemeData(
    decoration: BoxDecoration(
      color: Color(0xFF616161),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    textStyle: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    margin: EdgeInsets.all(8),
  );

  static const TooltipThemeData _darkTooltipTheme = TooltipThemeData(
    decoration: BoxDecoration(
      color: Color(0xFF757575),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    textStyle: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    margin: EdgeInsets.all(8),
  );

  // Popup menu themes
  static const PopupMenuThemeData _lightPopupMenuTheme = PopupMenuThemeData(
    color: Color(0xFFFFFFFF),
    surfaceTintColor: Color(0xFF1976D2),
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    textStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xFF212121),
    ),
  );

  static const PopupMenuThemeData _darkPopupMenuTheme = PopupMenuThemeData(
    color: Color(0xFF2C2C2C),
    surfaceTintColor: Color(0xFF90CAF9),
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    textStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xFFE0E0E0),
    ),
  );

  // Icon themes
  static const IconThemeData _lightIconTheme = IconThemeData(
    color: Color(0xFF757575),
    size: 24,
  );

  static const IconThemeData _darkIconTheme = IconThemeData(
    color: Color(0xFFBDBDBD),
    size: 24,
  );

  static const IconThemeData _lightPrimaryIconTheme = IconThemeData(
    color: Color(0xFF1976D2),
    size: 24,
  );

  static const IconThemeData _darkPrimaryIconTheme = IconThemeData(
    color: Color(0xFF90CAF9),
    size: 24,
  );

  // Utility methods
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static ColorScheme colorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }

  static TextTheme textTheme(BuildContext context) {
    return Theme.of(context).textTheme;
  }
}