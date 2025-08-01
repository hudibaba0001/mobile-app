import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme Settings
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle dark/light theme'),
            trailing: Switch(
              value: settingsProvider.isDarkMode,
              onChanged: settingsProvider.setDarkMode,
            ),
          ),

          // First Launch Setting
          ListTile(
            leading: const Icon(Icons.new_releases),
            title: const Text('Show Welcome Screen'),
            subtitle: const Text('Show introduction on next launch'),
            trailing: Switch(
              value: settingsProvider.isFirstLaunch,
              onChanged: settingsProvider.setFirstLaunch,
            ),
          ),
        ],
      ),
    );
  }
}