import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Updated to use unified Entry model instead of TravelTimeEntry
import '../models/entry.dart';
// Existing screens (updated to work with unified Entry model)
import '../screens/home_screen.dart';
import '../screens/travel_entries_screen.dart';
import '../screens/locations_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
// Future unified screens (to be implemented)
// import '../screens/unified_home_screen.dart';
// import '../screens/history_screen.dart';

class AppRouter {
  // Route paths
  static const String home = '/';
  static const String travelEntries = '/travel-entries';
  static const String history = '/history';
  static const String locations = '/locations';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String editEntry = '/edit-entry';
  
  // Route names (for named navigation)
  static const String homeName = 'home';
  static const String travelEntriesName = 'travel-entries';
  static const String historyName = 'history';
  static const String locationsName = 'locations';
  static const String reportsName = 'reports';
  static const String settingsName = 'settings';
  static const String editEntryName = 'edit-entry';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    debugLogDiagnostics: true,
    routes: [
      // Main home screen (currently HomeScreen, will be UnifiedHomeScreen in future)
      GoRoute(
        path: home,
        name: homeName,
        builder: (context, state) => const HomeScreen(),
        // Add back button behavior for nested navigation
        redirect: (context, state) {
          // Add any authentication or initialization checks here
          return null; // No redirect needed
        },
      ),
      
      // Travel entries screen (updated to work with unified Entry model)
      GoRoute(
        path: travelEntries,
        name: travelEntriesName,
        builder: (context, state) => const TravelEntriesScreen(),
      ),
      
      // History screen (alias for travel entries, will be separate HistoryScreen in future)
      GoRoute(
        path: history,
        name: historyName,
        builder: (context, state) => const TravelEntriesScreen(), // Temporary: use TravelEntriesScreen
        // TODO: Replace with HistoryScreen when implemented
        // builder: (context, state) => const HistoryScreen(),
      ),
      
      // Locations management screen
      GoRoute(
        path: locations,
        name: locationsName,
        builder: (context, state) => const LocationsScreen(),
      ),
      
      // Reports and analytics screen
      GoRoute(
        path: reports,
        name: reportsName,
        builder: (context, state) => const ReportsScreen(),
      ),
      
      // Settings screen (updated to work with unified architecture)
      GoRoute(
        path: settings,
        name: settingsName,
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // Edit entry screen (updated to work with unified Entry model)
      GoRoute(
        path: '$editEntry/:entryId',
        name: editEntryName,
        builder: (context, state) {
          final entryId = state.pathParameters['entryId']!;
          final entryType = state.uri.queryParameters['type'] ?? 'travel';
          return EditEntryScreen(
            entryId: entryId,
            entryType: entryType,
          );
        },
      ),
    ],
    
    // Enhanced error handling
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
    
    // Add redirect logic for handling deep links and authentication
    redirect: (context, state) {
      // Add global redirect logic here if needed
      // For example, redirect to login if not authenticated
      return null; // No global redirect needed currently
    },
  );
  
  // Helper methods for programmatic navigation
  
  /// Navigate to home screen
  static void goHome(BuildContext context) {
    context.goNamed(homeName);
  }
  
  /// Navigate to travel entries screen
  static void goToTravelEntries(BuildContext context) {
    context.goNamed(travelEntriesName);
  }
  
  /// Navigate to history screen
  static void goToHistory(BuildContext context) {
    context.goNamed(historyName);
  }
  
  /// Navigate to locations screen
  static void goToLocations(BuildContext context) {
    context.goNamed(locationsName);
  }
  
  /// Navigate to reports screen
  static void goToReports(BuildContext context) {
    context.goNamed(reportsName);
  }
  
  /// Navigate to settings screen
  static void goToSettings(BuildContext context) {
    context.goNamed(settingsName);
  }
  
  /// Navigate to edit entry screen
  static void goToEditEntry(BuildContext context, String entryId, {String entryType = 'travel'}) {
    context.goNamed(
      editEntryName,
      pathParameters: {'entryId': entryId},
      queryParameters: {'type': entryType},
    );
  }
  
  /// Go back with fallback to home
  static void goBackOrHome(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      goHome(context);
    }
  }
}

class ErrorScreen extends StatelessWidget {
  final GoException? error;

  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRouter.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditEntryScreen extends StatelessWidget {
  final String entryId;
  final String entryType;

  const EditEntryScreen({
    super.key, 
    required this.entryId,
    this.entryType = 'travel',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${_getEntryTypeDisplayName(entryType)} Entry'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.goBackOrHome(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // TODO: Implement save functionality with unified Entry model
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Save functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEntryTypeIcon(entryType),
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Editing ${_getEntryTypeDisplayName(entryType)} Entry',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Entry ID: $entryId',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'This screen will be updated to work with the unified Entry model.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => AppRouter.goBackOrHome(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
                OutlinedButton.icon(
                  onPressed: () => AppRouter.goHome(context),
                  icon: const Icon(Icons.home),
                  label: const Text('Home'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getEntryTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'travel':
        return 'Travel';
      case 'work':
        return 'Work';
      default:
        return 'Unknown';
    }
  }
  
  IconData _getEntryTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'travel':
        return Icons.directions_car;
      case 'work':
        return Icons.work;
      default:
        return Icons.edit;
    }
  }
}