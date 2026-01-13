import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../config/app_router.dart';
import '../config/external_links.dart';
import '../widgets/standard_app_bar.dart';
import '../providers/entry_provider.dart';
import '../providers/travel_provider.dart';
import '../services/supabase_auth_service.dart';
import '../models/entry.dart';
import '../models/travel_entry.dart';
import '../models/work_entry.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _addSampleData(BuildContext context) async {
    final entryProvider = context.read<EntryProvider>();
    final auth = context.read<SupabaseAuthService>();
    final uid = auth.currentUser?.id;
    if (uid == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to add sample data.')),
        );
      }
      return;
    }
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
        userId: uid,
        workMinutes: 480, // 8 hours
        date: now.subtract(const Duration(days: 1)),
        remarks: 'Regular work day',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      WorkEntry(
        id: 'sample_work_2',
        userId: uid,
        workMinutes: 540, // 9 hours
        date: now.subtract(const Duration(days: 3)),
        remarks: 'Extended day - project deadline',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      WorkEntry(
        id: 'sample_work_3',
        userId: uid,
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
        userId: uid,
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
        userId: uid,
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
        userId: uid,
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
        userId: uid,
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

  Future<void> _clearDemoData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Demo Data'),
        content: const Text(
          'Are you sure you want to delete all demo/sample entries? This will only remove entries with IDs starting with "sample_".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Demo Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final entryProvider = context.read<EntryProvider>();
        await entryProvider.clearDemoEntries();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demo data cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear demo data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all entries? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final entryProvider = context.read<EntryProvider>();
        final travelProvider = context.read<TravelProvider>();
        
        // Clear both providers
        await Future.wait([
          entryProvider.clearAllEntries(),
          travelProvider.clearAllEntries(),
        ]);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All data cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

          // Contract Settings
          ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: const Text('Contract Settings'),
            subtitle: const Text('Configure your work contract and rates'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AppRouter.goToContractSettings(context),
          ),

          // Absence Management
          ListTile(
            leading: const Icon(Icons.event_busy),
            title: const Text('Absences'),
            subtitle: const Text('Manage vacation, sick leave, and VAB'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRouter.absenceManagementPath),
          ),

          // Manage Subscription
          ListTile(
            leading: const Icon(Icons.payment_outlined),
            title: const Text('Manage Subscription'),
            subtitle: const Text('Update payment method and subscription plan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              try {
                final url = Uri.parse(ExternalLinks.manageSubscriptionUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open subscription page'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to open subscription page: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
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
            ListTile(
              leading: const Icon(Icons.cleaning_services, color: Colors.orange),
              title: const Text('Clear Demo Data', style: TextStyle(color: Colors.orange)),
              subtitle: const Text('Remove sample entries (IDs starting with "sample_")',
                                style: TextStyle(color: Colors.orange)),
              onTap: () => _clearDemoData(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Delete all entries (cannot be undone)', 
                                style: TextStyle(color: Colors.red)),
              onTap: () => _clearAllData(context),
            ),
            ListTile(
              leading: const Icon(Icons.sync, color: Colors.blue),
              title: const Text('Sync to Supabase', style: TextStyle(color: Colors.blue)),
              subtitle: const Text('Manually sync local entries to Supabase cloud',
                                style: TextStyle(color: Colors.blue)),
              onTap: () => _syncToSupabase(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _syncToSupabase(BuildContext context) async {
    final entryProvider = context.read<EntryProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Syncing to Supabase...'),
          ],
        ),
      ),
    );

    try {
      await entryProvider.syncLocalEntriesToSupabase();
      
      // Close dialog safely after frame completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.canPop()) {
          navigator.pop();
        }
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Sync completed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      });
    } catch (e) {
      // Close dialog safely after frame completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.canPop()) {
          navigator.pop();
        }
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('❌ Sync failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }
  }
}
