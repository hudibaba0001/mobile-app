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
      // Home screen route - now using UnifiedHomeScreen
      GoRoute(
        path: homePath,
        name: homeName,
        builder: (context, state) => const UnifiedHomeScreen(),
      ),
      
      // History screen route - now using HistoryScreen
      GoRoute(
        path: historyPath,
        name: historyName,
        builder: (context, state) => const HistoryScreen(),
      ),
      
      // Settings screen route - using real SettingsScreen
      GoRoute(
        path: settingsPath,
        name: settingsName,
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // Contract Settings screen route - new route
      GoRoute(
        path: contractSettingsPath,
        name: contractSettingsName,
        builder: (context, state) => const ContractSettingsScreen(),
      ),
      
      // Edit entry screen route with entry type support - now using real EditEntryScreen
      GoRoute(
        path: editEntryPath,
        name: editEntryName,
        builder: (context, state) {
          final entryId = state.pathParameters['entryId']!;
          final entryType = state.uri.queryParameters['type'];
          return EditEntryScreen(entryId: entryId, entryType: entryType);
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
  
  /// Navigate to contract settings screen
  static void goToContractSettings(BuildContext context) {
    context.goNamed(contractSettingsName);
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

/// Error screen for navigation errors
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