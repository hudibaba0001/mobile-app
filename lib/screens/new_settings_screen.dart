import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/dark_mode_toggle.dart';

// Settings Provider for state management
class SettingsProvider extends ChangeNotifier {
  Color _accentColor = const Color(0xFF6750A4); // Material 3 Purple
  String _language = 'English';
  bool _dailyReminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _weeklySummary = false;

  Color get accentColor => _accentColor;
  String get language => _language;
  bool get dailyReminder => _dailyReminder;
  TimeOfDay get reminderTime => _reminderTime;
  bool get weeklySummary => _weeklySummary;

  void setAccentColor(Color color) {
    _accentColor = color;
    notifyListeners();
  }

  void setLanguage(String language) {
    _language = language;
    notifyListeners();
  }

  void setDailyReminder(bool enabled) {
    _dailyReminder = enabled;
    notifyListeners();
  }

  void setReminderTime(TimeOfDay time) {
    _reminderTime = time;
    notifyListeners();
  }

  void setWeeklySummary(bool enabled) {
    _weeklySummary = enabled;
    notifyListeners();
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
      child: const _SettingsScreenContent(),
    );
  }
}

class _SettingsScreenContent extends StatelessWidget {
  const _SettingsScreenContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Appearance'),
            const SizedBox(height: 8),
            _buildAppearanceSection(context),
            const SizedBox(height: 24),

            _buildSectionHeader(context, 'Data'),
            const SizedBox(height: 8),
            _buildDataSection(context),
            const SizedBox(height: 24),

            _buildSectionHeader(context, 'Localization'),
            const SizedBox(height: 8),
            _buildLocalizationSection(context),
            const SizedBox(height: 24),

            _buildSectionHeader(context, 'Reminders'),
            const SizedBox(height: 8),
            _buildRemindersSection(context),
            const SizedBox(height: 24),

            _buildSectionHeader(context, 'Help & Feedback'),
            const SizedBox(height: 8),
            _buildHelpSection(context),
          ],
        ),
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

  Widget _buildAppearanceSection(BuildContext context) {
    return Column(
      children: [
        // Dark Mode Toggle
        const DarkModeToggle(),
        const SizedBox(height: 8),
        
        // Accent Color Picker
        _buildListTile(
          context,
          icon: Icons.palette,
          title: 'Accent Color',
          subtitle: 'Choose your preferred theme color',
          trailing: null,
          child: _buildColorPicker(context),
        ),
      ],
    );
  }

  Widget _buildColorPicker(BuildContext context) {
    final colors = [
      const Color(0xFF6750A4), // Purple
      const Color(0xFF03DAC6), // Teal
      const Color(0xFFFF9800), // Orange
      const Color(0xFF4CAF50), // Green
      const Color(0xFFF44336), // Red
    ];

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: colors.map((color) {
              final isSelected = settings.accentColor.value == color.value;
              return GestureDetector(
                onTap: () => settings.setAccentColor(color),
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
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return _buildListTile(
      context,
      icon: Icons.download,
      title: 'Export as CSV',
      subtitle: 'Download all entries in CSV format',
      onTap: () => _exportCSV(context),
    );
  }

  Widget _buildLocalizationSection(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return _buildListTile(
          context,
          icon: Icons.language,
          title: 'Language',
          subtitle: 'Select your preferred language',
          trailing: DropdownButton<String>(
            value: settings.language,
            underline: const SizedBox(),
            items: ['English', 'Svenska'].map((String language) {
              return DropdownMenuItem<String>(
                value: language,
                child: Text(language),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                settings.setLanguage(newValue);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildRemindersSection(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          children: [
            // Daily Reminder
            _buildListTile(
              context,
              icon: Icons.notifications,
              title: 'Daily Reminder',
              subtitle: 'Get reminded to log your time',
              trailing: Switch(
                value: settings.dailyReminder,
                onChanged: (value) {
                  settings.setDailyReminder(value);
                  if (value) {
                    _showTimePicker(context, settings);
                  }
                },
              ),
            ),
            
            // Time Setting (visible when daily reminder is on)
            if (settings.dailyReminder) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: _buildListTile(
                  context,
                  icon: Icons.schedule,
                  title: 'Reminder Time',
                  subtitle: 'Set when to receive daily reminders',
                  trailing: GestureDetector(
                    onTap: () => _showTimePicker(context, settings),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Text(
                        settings.reminderTime.format(context),
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
                value: settings.weeklySummary,
                onChanged: settings.setWeeklySummary,
              ),
            ),
          ],
        );
      },
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
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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

  void _exportCSV(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV export started. You will be notified when complete.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showTimePicker(BuildContext context, SettingsProvider settings) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: settings.reminderTime,
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('en', 'US'),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );
    
    if (picked != null) {
      settings.setReminderTime(picked);
    }
  }

  void _sendFeedback(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feedback form would open here'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _rateApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App store rating page would open here'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
