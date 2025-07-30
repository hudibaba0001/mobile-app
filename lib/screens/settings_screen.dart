import 'package:flutter/material.dart';

/// Settings screen placeholder.
/// Will be fleshed out with Appearance, Data, Localization, Reminders, and Help & Feedback sections.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.settings,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Configure your app preferences',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Coming soon:\n• Appearance settings\n• Data management\n• Localization\n• Reminders\n• Help & Feedback',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'SettingsScreen coming soon',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

