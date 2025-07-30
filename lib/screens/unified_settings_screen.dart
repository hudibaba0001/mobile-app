import 'package:flutter/material.dart';

class UnifiedSettingsScreen extends StatefulWidget {
  const UnifiedSettingsScreen({Key? key}) : super(key: key);

  @override
  State<UnifiedSettingsScreen> createState() => _UnifiedSettingsScreenState();
}

class _UnifiedSettingsScreenState extends State<UnifiedSettingsScreen> {
  bool isDarkMode = false;
  bool isDailyReminderEnabled = true;
  bool isWeeklySummaryEnabled = false;
  TimeOfDay reminderTime = const TimeOfDay(hour: 9, minute: 0);
  String selectedLanguage = 'English';
  Color selectedAccentColor = const Color(0xFF6750A4);

  final List<Color> accentColors = [
    const Color(0xFF6750A4), // Purple
    const Color(0xFF03DAC6), // Teal
    const Color(0xFF1976D2), // Blue
    const Color(0xFFFF9800), // Orange
    const Color(0xFF4CAF50), // Green
  ];

  final List<String> languages = ['English', 'Svenska'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurface,
          ),
        ),
        title: Text(
          'Settings',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Section
            _buildSectionHeader(context, 'Theme'),
            _buildSettingsCard(
              context,
              children: [
                _buildSwitchTile(
                  context,
                  title: 'Dark Mode',
                  subtitle: 'Switch between light and dark themes',
                  icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  value: isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      isDarkMode = value;
                    });
                  },
                ),
                const Divider(height: 1),
                _buildAccentColorPicker(context),
              ],
            ),

            const SizedBox(height: 24),

            // Data Export Section
            _buildSectionHeader(context, 'Data Export'),
            _buildSettingsCard(
              context,
              children: [
                _buildActionTile(
                  context,
                  title: 'Export as CSV',
                  subtitle: 'Download all entries in CSV format',
                  icon: Icons.download_rounded,
                  onTap: () => _exportData(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Localization Section
            _buildSectionHeader(context, 'Localization'),
            _buildSettingsCard(
              context,
              children: [
                _buildLanguageSelector(context),
              ],
            ),

            const SizedBox(height: 24),

            // Reminders Section
            _buildSectionHeader(context, 'Reminders'),
            _buildSettingsCard(
              context,
              children: [
                _buildSwitchTile(
                  context,
                  title: 'Daily Reminder',
                  subtitle: 'Get reminded to log your entries',
                  icon: Icons.notifications_rounded,
                  value: isDailyReminderEnabled,
                  onChanged: (value) {
                    setState(() {
                      isDailyReminderEnabled = value;
                    });
                  },
                ),
                if (isDailyReminderEnabled) ...[
                  const Divider(height: 1),
                  _buildTimePicker(context),
                ],
                const Divider(height: 1),
                _buildSwitchTile(
                  context,
                  title: 'Weekly Summary',
                  subtitle: 'Receive weekly activity reports',
                  icon: Icons.calendar_today_rounded,
                  value: isWeeklySummaryEnabled,
                  onChanged: (value) {
                    setState(() {
                      isWeeklySummaryEnabled = value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Help & Feedback Section
            _buildSectionHeader(context, 'Help & Feedback'),
            _buildSettingsCard(
              context,
              children: [
                _buildActionTile(
                  context,
                  title: 'Send Feedback',
                  subtitle: 'Share your thoughts and suggestions',
                  icon: Icons.mail_outline_rounded,
                  onTap: () => _sendFeedback(context),
                ),
                const Divider(height: 1),
                _buildActionTile(
                  context,
                  title: 'Rate the App',
                  subtitle: 'Help us improve with your rating',
                  icon: Icons.star_outline_rounded,
                  onTap: () => _rateApp(context),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // App Version
            _buildAppVersion(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shadowColor: colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: colorScheme.primary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: colorScheme.primary,
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: colorScheme.secondary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  Widget _buildAccentColorPicker(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.palette_rounded,
          color: colorScheme.tertiary,
          size: 24,
        ),
      ),
      title: Text(
        'Accent Color',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Choose your preferred accent color',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: SizedBox(
        width: 120,
        height: 32,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: accentColors.map((color) {
            final isSelected = color == selectedAccentColor;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedAccentColor = color;
                });
              },
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: colorScheme.outline, width: 2)
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.language_rounded,
          color: colorScheme.primary,
          size: 24,
        ),
      ),
      title: Text(
        'Language',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Select your preferred language',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: DropdownButton<String>(
        value: selectedLanguage,
        underline: const SizedBox(),
        items: languages.map((String language) {
          return DropdownMenuItem<String>(
            value: language,
            child: Text(language),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              selectedLanguage = newValue;
            });
          }
        },
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const SizedBox(width: 48), // Spacer to align with other items
      title: Text(
        'Reminder Time',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: TextButton(
        onPressed: () => _selectTime(context),
        child: Text(
          reminderTime.format(context),
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAppVersion(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        children: [
          Text(
            'Travel Time Tracker',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: reminderTime,
    );
    if (picked != null && picked != reminderTime) {
      setState(() {
        reminderTime = picked;
      });
    }
  }

  void _exportData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting data as CSV...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _sendFeedback(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening feedback form...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _rateApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening app store...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
