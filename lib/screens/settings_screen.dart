import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../models/travel_time_entry.dart';
import '../models/location.dart';
import '../utils/constants.dart';
import '../config/app_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box<TravelTimeEntry> _travelEntriesBox;
  late Box<Location> _locationsBox;

  @override
  void initState() {
    super.initState();
    _travelEntriesBox = Hive.box<TravelTimeEntry>(AppConstants.travelEntriesBox);
    _locationsBox = Hive.box<Location>(AppConstants.locationsBox);
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your travel entries and locations. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _travelEntriesBox.clear();
              await _locationsBox.clear();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data cleared'),
                  backgroundColor: Colors.orange,
                ),
              );
              setState(() {});
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Travel Time Logger',
      applicationVersion: '2.0.0',
      applicationIcon: const Icon(Icons.directions_car, size: 48),
      children: [
        const Text('A simple and efficient way to track your travel times.'),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Log travel entries with locations and times'),
        const Text('• Manage frequently used locations'),
        const Text('• View detailed reports and analytics'),
        const Text('• Export data for record keeping'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final travelEntriesCount = _travelEntriesBox.length;
    final locationsCount = _locationsBox.length;
    final totalMinutes = _travelEntriesBox.values.fold(0, (sum, entry) => sum + entry.minutes);
    final totalHours = (totalMinutes / 60).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          // Data Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Overview',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  _DataRow(
                    icon: Icons.trip_origin,
                    label: 'Travel Entries',
                    value: travelEntriesCount.toString(),
                  ),
                  _DataRow(
                    icon: Icons.location_on,
                    label: 'Saved Locations',
                    value: locationsCount.toString(),
                  ),
                  _DataRow(
                    icon: Icons.access_time,
                    label: 'Total Travel Time',
                    value: '${totalHours}h',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // Navigation
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Reports & Analytics'),
                  subtitle: const Text('View detailed travel statistics'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => context.go(AppRouter.reports),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Manage Locations'),
                  subtitle: const Text('Add, edit, or remove locations'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => context.go(AppRouter.locations),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text('All Travel Entries'),
                  subtitle: const Text('View and manage all entries'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => context.go(AppRouter.travelEntries),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // Data Management
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download, color: Colors.blue),
                  title: const Text('Export Data'),
                  subtitle: const Text('Export your data to CSV or JSON'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Export feature coming soon!'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_upload, color: Colors.green),
                  title: const Text('Import Data'),
                  subtitle: const Text('Import data from CSV or JSON file'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Import feature coming soon!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup, color: Colors.orange),
                  title: const Text('Backup Data'),
                  subtitle: const Text('Create a backup of all your data'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Backup feature coming soon!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // Danger Zone
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Permanently delete all entries and locations'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _clearAllData,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // About
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About'),
                  subtitle: const Text('App version and information'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _showAboutDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  subtitle: const Text('Get help using the app'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Help documentation coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.largePadding),

          // Version Info
          Center(
            child: Text(
              'Travel Time Logger v2.0.0',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.smallPadding),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: AppConstants.defaultPadding),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}