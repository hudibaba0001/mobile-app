import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/travel_provider.dart';
import '../providers/location_provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/quick_entry_form.dart';
import '../widgets/travel_entry_card.dart';
import '../models/travel_time_entry.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TravelProvider>(context, listen: false).refreshEntries();
      Provider.of<LocationProvider>(context, listen: false).refreshLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Time Tracker'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/travel-entries'),
            tooltip: 'Search Entries',
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => context.go('/reports'),
            tooltip: 'Reports',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer3<TravelProvider, LocationProvider, AppStateProvider>(
        builder: (context, travelProvider, locationProvider, appStateProvider, _) {
          if (travelProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await travelProvider.refreshEntries();
              await locationProvider.refreshLocations();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dashboard Summary Cards
                  _buildSummarySection(travelProvider, locationProvider),
                  
                  // Quick Entry Section
                  _buildQuickEntrySection(),
                  
                  // Recent Entries Section
                  _buildRecentEntriesSection(travelProvider),
                  
                  // Quick Actions Section
                  _buildQuickActionsSection(),
                  
                  const SizedBox(height: AppConstants.largePadding),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickEntryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
      ),
    );
  }

  Widget _buildSummarySection(TravelProvider travelProvider, LocationProvider locationProvider) {
    final entries = travelProvider.entries;
    final thisWeekEntries = entries.where((entry) {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      return entry.date.isAfter(weekStart);
    }).toList();
    
    final totalMinutesThisWeek = thisWeekEntries.fold<int>(0, (sum, entry) => sum + entry.minutes);
    final avgMinutesThisWeek = thisWeekEntries.isNotEmpty ? totalMinutesThisWeek / thisWeekEntries.length : 0;

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week\'s Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total Trips',
                  thisWeekEntries.length.toString(),
                  Icons.route,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total Time',
                  _formatDuration(totalMinutesThisWeek),
                  Icons.access_time,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Avg Time',
                  _formatDuration(avgMinutesThisWeek.round()),
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Locations',
                  locationProvider.locations.length.toString(),
                  Icons.location_on,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickEntrySection() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Entry',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              QuickEntryForm(
                onSuccess: () {
                  // Refresh the entries list
                  Provider.of<TravelProvider>(context, listen: false).refreshEntries();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentEntriesSection(TravelProvider travelProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Entries',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go('/travel-entries'),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          
          if (travelProvider.entries.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.largePadding),
                child: Column(
                  children: [
                    Icon(
                      Icons.route,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    Text(
                      'No travel entries yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Text(
                      'Use the quick entry form above to log your first trip',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            // Show recent entries (limit to 5)
            ...travelProvider.entries.take(5).map((entry) => 
              TravelEntryCard(
                entry: entry,
                onEdit: () => _editEntry(context, entry),
                onDelete: () => _showDeleteConfirmation(context, entry, travelProvider),
                onTap: () => _showEntryDetails(context, entry),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  'Manage Locations',
                  'View and organize your saved locations',
                  Icons.location_on,
                  Colors.blue,
                  () => context.go('/locations'),
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: _buildActionCard(
                  context,
                  'Export Data',
                  'Export your travel data to CSV',
                  Icons.download,
                  Colors.green,
                  () => context.go('/reports'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes == 0) return '0m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${mins}m';
  }

  void _showQuickEntryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Entry',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              QuickEntryForm(
                onSuccess: () {
                  Navigator.of(context).pop();
                  Provider.of<TravelProvider>(context, listen: false).refreshEntries();
                },
                onCancel: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editEntry(BuildContext context, TravelTimeEntry entry) {
    // Navigate to edit screen or show edit dialog
    // For now, we'll show a simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Entry'),
        content: const Text('Edit functionality will be implemented in the travel entries screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/travel-entries');
            },
            child: const Text('Go to Entries'),
          ),
        ],
      ),
    );
  }

  void _showEntryDetails(BuildContext context, TravelTimeEntry entry) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 400),
          child: TravelEntryCard(
            entry: entry,
            onEdit: () {
              Navigator.of(context).pop();
              _editEntry(context, entry);
            },
            onDelete: () {
              Navigator.of(context).pop();
              _showDeleteConfirmation(context, entry, Provider.of<TravelProvider>(context, listen: false));
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    TravelTimeEntry entry,
    TravelProvider travelProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete the trip from ${entry.departure} to ${entry.arrival}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await travelProvider.deleteEntry(entry.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Entry deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(travelProvider.lastError?.message ?? 'Failed to delete entry'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}