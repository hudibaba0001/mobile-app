import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../config/app_router.dart';
import '../widgets/standard_app_bar.dart';
import '../providers/entry_provider.dart';
import '../models/entry.dart';
import '../models/travel_entry.dart';
import '../models/work_entry.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _addSampleData(BuildContext context) async {
    final entryProvider = context.read<EntryProvider>();
    final now = DateTime.now();

    // Sample locations
    const locations = [
      ('Home', '123 Home Street'),
      ('Office', '456 Business Ave'),
      ('Client Site A', '789 Client Road'),
      ('Gym', '321 Fitness Lane'),
      ('Coffee Shop', '654 Cafe Street'),
    ];

    // Sample work entries from the last week
    final workEntries = [
      WorkEntry(
        id: 'sample_work_1',
        userId: 'current_user',
        workMinutes: 480, // 8 hours
        date: now.subtract(const Duration(days: 1)),
        remarks: 'Regular work day',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      WorkEntry(
        id: 'sample_work_2',
        userId: 'current_user',
        workMinutes: 540, // 9 hours
        date: now.subtract(const Duration(days: 3)),
        remarks: 'Extended day - project deadline',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      WorkEntry(
        id: 'sample_work_3',
        userId: 'current_user',
        workMinutes: 420, // 7 hours
        date: now.subtract(const Duration(days: 5)),
        remarks: 'Short day - doctor appointment',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    // Sample travel entries from the last week
    final travelEntries = [
      TravelEntry(
        id: 'sample_travel_1',
        userId: 'current_user',
        fromLocation: locations[0].$1, // Home
        toLocation: locations[1].$1, // Office
        travelMinutes: 45,
        date: now.subtract(const Duration(days: 2)),
        remarks: 'Morning commute',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      TravelEntry(
        id: 'sample_travel_2',
        userId: 'current_user',
        fromLocation: locations[1].$1, // Office
        toLocation: locations[2].$1, // Client Site
        travelMinutes: 30,
        date: now.subtract(const Duration(days: 4)),
        remarks: 'Client meeting',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
      TravelEntry(
        id: 'sample_travel_3',
        userId: 'current_user',
        fromLocation: locations[2].$1, // Client Site
        toLocation: locations[0].$1, // Home
        travelMinutes: 60,
        date: now.subtract(const Duration(days: 4)),
        remarks: 'Return from client meeting',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
      TravelEntry(
        id: 'sample_travel_4',
        userId: 'current_user',
        fromLocation: locations[0].$1, // Home
        toLocation: locations[3].$1, // Gym
        travelMinutes: 20,
        date: now.subtract(const Duration(days: 6)),
        remarks: 'Morning workout',
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 6)),
      ),
    ];

    try {
      // Add work entries
      for (final entry in workEntries) {
        await entryProvider.addEntry(Entry(
          id: entry.id,
          userId: entry.userId,
          type: EntryType.work,
          shifts: [
            Shift(
              start: entry.date,
              end: entry.date.add(Duration(minutes: entry.workMinutes)),
              description: entry.remarks,
              location: 'Office',
            ),
          ],
          date: entry.date,
          notes: entry.remarks,
          createdAt: entry.createdAt,
          updatedAt: entry.updatedAt,
        ));
      }

      // Add travel entries
      for (final entry in travelEntries) {
        await entryProvider.addEntry(Entry(
          id: entry.id,
          userId: entry.userId,
          type: EntryType.travel,
          from: entry.fromLocation,
          to: entry.toLocation,
          travelMinutes: entry.travelMinutes,
          date: entry.date,
          notes: entry.remarks,
          createdAt: entry.createdAt,
          updatedAt: entry.updatedAt,
        ));
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sample data added successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add sample data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: const StandardAppBar(title: 'Settings'),
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

          const Divider(),

          // Manage Locations
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Manage Locations'),
            subtitle: const Text('Add and edit your frequent locations'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AppRouter.goToManageLocations(context),
          ),

          // Developer Options (only in debug mode)
          if (kDebugMode) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Developer Options',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.data_array),
              title: const Text('Add Sample Data'),
              subtitle: const Text('Create test entries from the last week'),
              onTap: () => _addSampleData(context),
            ),
          ],
        ],
      ),
    );
  }
}
