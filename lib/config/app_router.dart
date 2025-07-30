import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Real implementations now available
import '../screens/unified_home_screen.dart';
import '../screens/history_screen.dart';
import '../screens/edit_entry_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/contract_settings_screen.dart';

// Fallback screens (for routes not yet implemented)
import '../screens/home_screen.dart';
import '../screens/travel_entries_screen.dart';

/// App Router configuration for unified Entry model architecture
/// 
/// This router is designed to work with the new unified Entry model
/// and provides navigation for both travel and work entry types.
/// 
/// Key Features:
/// - Named routes for consistent navigation
/// - Helper methods for programmatic navigation
/// - Entry type support for edit screens
/// - Error handling and fallback routes
/// - Future-ready for UnifiedHomeScreen and HistoryScreen
class AppRouter {
  // Route paths
  static const String homePath = '/';
  static const String historyPath = '/history';
  static const String settingsPath = '/settings';
  static const String contractSettingsPath = '/contract-settings';
  static const String editEntryPath = '/edit-entry/:entryId';
  
  // Route names for named navigation
  static const String homeName = 'home';
  static const String historyName = 'history';
  static const String settingsName = 'settings';
  static const String contractSettingsName = 'contractSettings';
  static const String editEntryName = 'editEntry';
  
  /// Main GoRouter configuration
  static final GoRouter router = GoRouter(
    initialLocation: homePath,
    debugLogDiagnostics: true,
    routes: [
      // Home screen route
      GoRoute(
        path: homePath,
        name: homeName,
        builder: (context, state) {
          // TODO: Replace with UnifiedHomeScreen when implemented
          // return const UnifiedHomeScreen();
          return const HomeScreen(); // Temporary fallback
        },
      ),
      
      // History screen route
      GoRoute(
        path: historyPath,
        name: historyName,
        builder: (context, state) {
          // TODO: Replace with HistoryScreen when implemented
          // return const HistoryScreen();
          return const TravelEntriesScreen(); // Temporary fallback
        },
      ),
      
      // Settings screen route
      GoRoute(
        path: settingsPath,
        name: settingsName,
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // Edit entry screen route with entry type support
      GoRoute(
        path: editEntryPath,
        name: editEntryName,
        builder: (context, state) {
          final entryId = state.pathParameters['entryId']!;
          final entryType = state.uri.queryParameters['type'];
          
          // TODO: Replace with EditEntryScreen when implemented
          // return EditEntryScreen(entryId: entryId, entryType: entryType);
          return _TemporaryEditEntryScreen(
            entryId: entryId, 
            entryType: entryType,
          ); // Temporary fallback
        },
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
    
    // Global redirect logic (if needed)
    redirect: (context, state) {
      // Add authentication or initialization checks here if needed
      return null; // No redirect needed currently
    },
  );
  
  // Helper navigation methods
  
  /// Navigate to home screen
  static void goHome(BuildContext context) {
    context.goNamed(homeName);
  }
  
  /// Navigate to history screen
  static void goToHistory(BuildContext context) {
    context.goNamed(historyName);
  }
  
  /// Navigate to settings screen
  static void goToSettings(BuildContext context) {
    context.goNamed(settingsName);
  }
  
  /// Navigate to edit entry screen with optional entry type
  static void goToEditEntry(BuildContext context, String entryId, {String? entryType}) {
    final queryParams = entryType != null ? {'type': entryType} : <String, String>{};
    context.goNamed(
      editEntryName,
      pathParameters: {'entryId': entryId},
      queryParameters: queryParams,
    );
  }
  
  /// Smart back navigation with fallback to home
  static void goBackOrHome(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      context.pop();
    } else {
      goHome(context);
    }
  }
  
  /// Check if we can navigate back
  static bool canPop(BuildContext context) {
    return GoRouter.of(context).canPop();
  }
  
  /// Get current route name
  static String? getCurrentRouteName(BuildContext context) {
    final RouteMatch lastMatch = GoRouter.of(context).routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch ? lastMatch.matches : GoRouter.of(context).routerDelegate.currentConfiguration;
    return matchList.last.route.name;
  }
  
  /// Navigate with path (alternative to named navigation)
  static void goToPath(BuildContext context, String path) {
    context.go(path);
  }
  
  /// Replace current route (no back navigation)
  static void replaceWithHome(BuildContext context) {
    context.goNamed(homeName);
  }
  
  /// Navigate to edit entry for travel type (convenience method)
  static void goToEditTravelEntry(BuildContext context, String entryId) {
    goToEditEntry(context, entryId, entryType: 'travel');
  }
  
  /// Navigate to edit entry for work type (convenience method)
  static void goToEditWorkEntry(BuildContext context, String entryId) {
    goToEditEntry(context, entryId, entryType: 'work');
  }
}

/// Temporary error screen until proper error handling is implemented
class _ErrorScreen extends StatelessWidget {
  final GoException? error;

  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                error?.toString() ?? 'Unknown navigation error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
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
      ),
    );
  }
}

/// Temporary edit entry screen until proper EditEntryScreen is implemented
class _TemporaryEditEntryScreen extends StatelessWidget {
  final String entryId;
  final String? entryType;

  const _TemporaryEditEntryScreen({
    required this.entryId,
    this.entryType,
  });

  @override
  Widget build(BuildContext context) {
    final displayType = entryType ?? 'travel';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${_capitalizeFirst(displayType)} Entry'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.goBackOrHome(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Save functionality will be implemented with unified Entry model'),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getEntryTypeIcon(displayType),
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Edit ${_capitalizeFirst(displayType)} Entry',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entry ID: $entryId',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.construction,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This screen will be replaced with a proper EditEntryScreen that works with the unified Entry model.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
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
      ),
    );
  }
  
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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