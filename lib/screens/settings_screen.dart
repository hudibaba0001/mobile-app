import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../config/app_router.dart';

/// Settings screen with full SettingsProvider integration
/// Features: Appearance, Data, Localization, Reminders, and Help & Feedback sections
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.goBackOrHome(context),
        ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, 'Appearance'),
                const SizedBox(height: 8),
                _buildAppearanceSection(context, settingsProvider),
                const SizedBox(height: 24),

                _buildSectionHeader(context, 'Data'),
                const SizedBox(height: 8),
                _buildDataSection(context, settingsProvider),
                const SizedBox(height: 24),

                _buildSectionHeader(context, 'Localization'),
                const SizedBox(height: 8),
                _buildLocalizationSection(context, settingsProvider),
                const SizedBox(height: 24),

                _buildSectionHeader(context, 'Reminders'),
                const SizedBox(height: 8),
                _buildRemindersSection(context, settingsProvider),
                const SizedBox(height: 24),

                _buildSectionHeader(context, 'Account'),
                const SizedBox(height: 8),
                _buildAccountSection(context, authService),
                const SizedBox(height: 24),

                _buildSectionHeader(context, 'Contract Settings'),
                const SizedBox(height: 8),
                _buildContractSection(context),
                const SizedBox(height: 24),

                _buildSectionHeader(context, 'Help & Feedback'),
                const SizedBox(height: 8),
                _buildHelpSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return Column(
      children: [
        // Accent Color Picker
        _buildListTile(
          context,
          icon: Icons.palette,
          title: 'Accent Color',
          subtitle: 'Choose your preferred theme color',
          child: _buildColorPicker(context, settingsProvider),
        ),
      ],
    );
  }

  Widget _buildColorPicker(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    final colors = [
      const Color(0xFF6750A4), // Purple
      const Color(0xFF03DAC6), // Teal
      const Color(0xFFFF9800), // Orange
      const Color(0xFF4CAF50), // Green
      const Color(0xFFF44336), // Red
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: colors.map((color) {
          final isSelected = settingsProvider.accentColor.value == color.value;
          return GestureDetector(
            onTap: () => settingsProvider.setAccentColor(color),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 3,
                      )
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDataSection(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return _buildListTile(
      context,
      icon: Icons.download,
      title: 'Export as CSV',
      subtitle: 'Download all entries in CSV format',
      onTap: () => _exportCSV(context, settingsProvider),
    );
  }

  Widget _buildLocalizationSection(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return _buildListTile(
      context,
      icon: Icons.language,
      title: 'Language',
      subtitle: 'Select your preferred language',
      trailing: DropdownButton<String>(
        value: settingsProvider.language,
        underline: const SizedBox(),
        items: ['en', 'sv'].map((String language) {
          return DropdownMenuItem<String>(
            value: language,
            child: Text(language == 'en' ? 'English' : 'Svenska'),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            settingsProvider.setLanguage(newValue);
          }
        },
      ),
    );
  }

  Widget _buildRemindersSection(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return Column(
      children: [
        // Daily Reminder
        _buildListTile(
          context,
          icon: Icons.notifications,
          title: 'Daily Reminder',
          subtitle: 'Get reminded to log your time',
          trailing: Switch(
            value: settingsProvider.dailyReminderEnabled,
            onChanged: (value) {
              settingsProvider.setDailyReminderEnabled(value);
              if (value) {
                _showTimePicker(context, settingsProvider);
              }
            },
          ),
        ),

        // Time Setting (visible when daily reminder is on)
        if (settingsProvider.dailyReminderEnabled) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: _buildListTile(
              context,
              icon: Icons.schedule,
              title: 'Reminder Time',
              subtitle: 'Set when to receive daily reminders',
              trailing: GestureDetector(
                onTap: () => _showTimePicker(context, settingsProvider),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    settingsProvider.getDailyReminderTimeString(context),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 8),

        // Weekly Summary
        _buildListTile(
          context,
          icon: Icons.summarize,
          title: 'Weekly Summary',
          subtitle: 'Receive weekly time tracking summaries',
          trailing: Switch(
            value: settingsProvider.weeklySummaryEnabled,
            onChanged: settingsProvider.setWeeklySummaryEnabled,
          ),
        ),
      ],
    );
  }

  Widget _buildContractSection(BuildContext context) {
    return _buildListTile(
      context,
      icon: Icons.work_outline,
      title: 'Contract Settings',
      subtitle: 'Configure contract percentage and hours',
      onTap: () => AppRouter.goToContractSettings(context),
      trailing: const Icon(Icons.arrow_forward_ios),
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    return Column(
      children: [
        _buildListTile(
          context,
          icon: Icons.mail,
          title: 'Send Feedback',
          subtitle: 'Share your thoughts and suggestions',
          onTap: () => _sendFeedback(context),
        ),
        const SizedBox(height: 8),
        _buildListTile(
          context,
          icon: Icons.star,
          title: 'Rate the App',
          subtitle: 'Help us improve by rating the app',
          onTap: () => _rateApp(context),
        ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    Widget? child,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 16),
                    trailing,
                  ],
                ],
              ),
              if (child != null) child,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportCSV(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Exporting CSV...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final path = await settingsProvider.exportCsv();

      if (path != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV saved to $path'),
            backgroundColor: Colors.green,
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No data to export or export failed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showTimePicker(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: settingsProvider.dailyReminderTime,
    );

    if (picked != null) {
      settingsProvider.setDailyReminderTime(picked);
    }
  }

  void _sendFeedback(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback feature coming soon!')),
    );
  }

  void _rateApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('App rating feature coming soon!')),
    );
  }

  /// Builds the account section with sign out button
  Widget _buildAccountSection(BuildContext context, AuthService authService) {
    return _buildSectionCard(
      context,
      children: [
        ListTile(
          leading: Icon(
            Icons.logout,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            'Sign Out',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () async {
            // Show confirmation dialog
            final shouldSignOut = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );

            // If user confirms, sign out
            if (shouldSignOut == true) {
              try {
                await authService.signOut();
                if (context.mounted) {
                  // Navigate to welcome screen after sign out
                  AppRouter.goToWelcome(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            }
          },
        ),
      ],
    );
  }

  /// Builds a card section with consistent styling
  Widget _buildSectionCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }
}
