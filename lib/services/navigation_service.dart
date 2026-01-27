// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_router.dart';
import '../services/auth_service.dart'; // Added import for AuthService

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  /// Navigate to home screen
  static void goHome(BuildContext context) {
    context.go(AppRouter.homePath);
  }

  /// Navigate to travel entries screen
  static void goToTravelEntries(BuildContext context) {
    context.go(AppRouter.reportsPath); // Use reports for now
  }

  /// Navigate to locations screen
  static void goToLocations(BuildContext context) {
    context.go(AppRouter.settingsPath); // Use settings for now
  }

  /// Navigate to reports screen
  static void goToReports(BuildContext context) {
    context.go(AppRouter.reportsPath);
  }

  /// Navigate to settings screen
  static void goToSettings(BuildContext context) {
    context.go(AppRouter.settingsPath);
  }

  /// Navigate to edit entry screen
  static void goToEditEntry(BuildContext context, String entryId) {
    context.go(
        '${AppRouter.reportsPath}/edit/$entryId'); // Use reports path for now
  }

  /// Go back to previous screen
  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      // If can't pop, go to home
      context.go(AppRouter.homePath);
    }
  }

  /// Push a new route onto the navigation stack
  static void push(BuildContext context, String route) {
    context.push(route);
  }

  /// Replace current route
  static void replace(BuildContext context, String route) {
    context.pushReplacement(route);
  }

  /// Get current route name
  static String? getCurrentRoute(BuildContext context) {
    final router = GoRouter.of(context);
    return router.routerDelegate.currentConfiguration.uri.path;
  }

  /// Check if we can go back
  static bool canGoBack(BuildContext context) {
    return context.canPop();
  }

  /// Navigate with parameters
  static void goWithParams(
      BuildContext context, String route, Map<String, String> params) {
    final uri = Uri(path: route, queryParameters: params);
    context.go(uri.toString());
  }

  /// Show confirmation dialog before navigation
  static Future<void> goWithConfirmation(
    BuildContext context,
    String route, {
    String title = 'Navigate Away?',
    String message = 'Are you sure you want to leave this page?',
  }) async {
    final shouldNavigate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (shouldNavigate == true) {
      context.go(route);
    }
  }

  /// Navigate to a screen and clear the navigation stack
  static void goAndClearStack(BuildContext context, String route) {
    // In go_router, we use go() which replaces the current route
    context.go(route);
  }

  /// Show bottom sheet with navigation options
  static void showNavigationSheet(BuildContext context) {
    final authService = context.read<AuthService>();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                goHome(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('Travel Entries'),
              onTap: () {
                Navigator.pop(context);
                goToTravelEntries(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Locations'),
              onTap: () {
                Navigator.pop(context);
                goToLocations(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Reports'),
              onTap: () {
                Navigator.pop(context);
                goToReports(context);
              },
            ),
            // Admin-only analytics option
            FutureBuilder<bool>(
              future: authService.isAdmin(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Analytics Dashboard'),
                    subtitle: const Text('Admin Only'),
                    onTap: () {
                      Navigator.pop(context);
                      AppRouter.goToAnalytics(context);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                goToSettings(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension methods for easier navigation
extension NavigationExtension on BuildContext {
  /// Navigate to home
  void goHome() => NavigationService.goHome(this);

  /// Navigate to travel entries
  void goToTravelEntries() => NavigationService.goToTravelEntries(this);

  /// Navigate to locations
  void goToLocations() => NavigationService.goToLocations(this);

  /// Navigate to reports
  void goToReports() => NavigationService.goToReports(this);

  /// Navigate to settings
  void goToSettings() => NavigationService.goToSettings(this);

  /// Navigate to edit entry
  void goToEditEntry(String entryId) =>
      NavigationService.goToEditEntry(this, entryId);

  /// Go back
  void goBack() => NavigationService.goBack(this);

  /// Get current route
  String? get currentRoute => NavigationService.getCurrentRoute(this);

  /// Check if can go back
  bool get canGoBack => NavigationService.canGoBack(this);

  /// Show navigation sheet
  void showNavigationSheet() => NavigationService.showNavigationSheet(this);
}

/// Navigation breadcrumb widget
class NavigationBreadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const NavigationBreadcrumb({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == items.length - 1;

        return Row(
          children: [
            GestureDetector(
              onTap: item.onTap,
              child: Text(
                item.title,
                style: TextStyle(
                  color: isLast ? Theme.of(context).primaryColor : Colors.grey,
                  fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (!isLast) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 8),
            ],
          ],
        );
      }).toList(),
    );
  }
}

class BreadcrumbItem {
  final String title;
  final VoidCallback? onTap;

  BreadcrumbItem({required this.title, this.onTap});
}

/// Navigation state manager
class NavigationState extends ChangeNotifier {
  String _currentRoute = AppRouter.homePath;
  final List<String> _navigationHistory = [];

  String get currentRoute => _currentRoute;
  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);

  void updateRoute(String route) {
    if (_currentRoute != route) {
      _navigationHistory.add(_currentRoute);
      _currentRoute = route;
      notifyListeners();
    }
  }

  void clearHistory() {
    _navigationHistory.clear();
    notifyListeners();
  }

  String? getPreviousRoute() {
    return _navigationHistory.isNotEmpty ? _navigationHistory.last : null;
  }
}
