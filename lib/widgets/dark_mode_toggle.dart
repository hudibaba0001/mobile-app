import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// A Material 3 styled Dark Mode toggle component for the Settings screen.
/// 
/// This widget provides a settings list item with:
/// - Leading sun/moon icon that changes based on theme
/// - "Dark Mode" label with subtitle
/// - Right-aligned toggle switch with smooth animations
/// - Proper accessibility support
/// - Material 3 theming integration
class DarkModeToggle extends StatelessWidget {
  const DarkModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDarkMode = themeProvider.isDarkMode;

        return Semantics(
          label: 'Dark mode toggle',
          hint: isDarkMode 
              ? 'Currently enabled. Tap to switch to light mode'
              : 'Currently disabled. Tap to switch to dark mode',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleDarkMode(context, themeProvider),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                constraints: const BoxConstraints(
                  minHeight: 72.0, // Ensures 48px+ tap target with padding
                ),
                child: Row(
                  children: [
                    // Leading Icon Container
                    _buildLeadingIcon(context, isDarkMode),
                    
                    const SizedBox(width: 16.0),
                    
                    // Title and Subtitle
                    Expanded(
                      child: _buildTitleSection(context, isDarkMode),
                    ),
                    
                    const SizedBox(width: 16.0),
                    
                    // Toggle Switch
                    _buildToggleSwitch(context, themeProvider, isDarkMode),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the leading icon container with sun/moon icon
  Widget _buildLeadingIcon(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: 48.0,
      height: 48.0,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: Icon(
          isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          key: ValueKey(isDarkMode),
          color: colorScheme.primary,
          size: 24.0,
          semanticLabel: isDarkMode ? 'Dark mode icon' : 'Light mode icon',
        ),
      ),
    );
  }

  /// Builds the title and subtitle section
  Widget _buildTitleSection(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Dark Mode',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          isDarkMode 
              ? 'Dark theme is active'
              : 'Switch to dark theme',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  /// Builds the toggle switch with Material 3 styling
  Widget _buildToggleSwitch(
    BuildContext context,
    ThemeProvider themeProvider,
    bool isDarkMode,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Dark mode switch',
      hint: 'Double tap to toggle',
      child: Switch.adaptive(
        value: isDarkMode,
        onChanged: (bool value) => _toggleDarkMode(context, themeProvider),
        activeColor: colorScheme.primary,
        activeTrackColor: colorScheme.primary.withOpacity(0.5),
        inactiveThumbColor: colorScheme.outline,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        splashRadius: 24.0,
      ),
    );
  }

  /// Handles the dark mode toggle action
  void _toggleDarkMode(BuildContext context, ThemeProvider themeProvider) {
    final newValue = !themeProvider.isDarkMode;
    
    // Update the theme
    themeProvider.setDarkMode(newValue);
    
    // Provide haptic feedback
    _provideHapticFeedback();
    
    // Show confirmation snackbar
    _showToggleConfirmation(context, newValue);
  }

  /// Provides haptic feedback for the toggle action
  void _provideHapticFeedback() {
    // Note: Import 'package:flutter/services.dart' if using HapticFeedback
    // HapticFeedback.lightImpact();
  }

  /// Shows a brief confirmation message
  void _showToggleConfirmation(BuildContext context, bool isDarkMode) {
    final message = isDarkMode 
        ? 'Dark mode enabled' 
        : 'Light mode enabled';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}

/// Extension methods for ThemeProvider integration
extension DarkModeToggleExtensions on ThemeProvider {
  /// Gets the current dark mode state
  bool get isDarkMode => themeMode == ThemeMode.dark;
  
  /// Sets the dark mode state and persists it
  void setDarkMode(bool isDarkMode) {
    final newThemeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    setThemeMode(newThemeMode);
  }
}
