import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../utils/go_router_refresh_stream.dart';
import '../services/dummy_auth_service.dart';

// Real implementations now available
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/unified_home_screen.dart';
import '../screens/history_screen.dart';
import '../screens/edit_entry_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/contract_settings_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/firebase_registration_screen.dart';
import '../screens/debug_auth_screen.dart';
import '../screens/reports_screen.dart';

// Fallback screens (for routes not yet implemented)

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
  static const String welcomePath = '/';
  static const String loginPath = '/login';
  static const String homePath = '/home';
  static const String historyPath = '/history';
  static const String settingsPath = '/settings';
  static const String contractSettingsPath = '/contract-settings';
  static const String editEntryPath = '/edit-entry/:entryId/:entryType';
  static const String reportsPath = '/reports';
  static const String forgotPasswordPath = '/forgot-password';
  static const String profilePath = '/profile';
  static const String firebaseRegistrationPath = '/firebase-registration';
  static const String debugAuthPath = '/debug-auth';

  // Route names for named navigation
  static const String welcomeName = 'welcome';
  static const String loginName = 'login';
  static const String homeName = 'home';
  static const String historyName = 'history';
  static const String settingsName = 'settings';
  static const String contractSettingsName = 'contractSettings';
  static const String editEntryName = 'editEntry';
  static const String reportsName = 'reports';
  static const String forgotPasswordName = 'forgotPassword';
  static const String profileName = 'profile';
  static const String firebaseRegistrationName = 'firebaseRegistration';
  static const String debugAuthName = 'debugAuth';

  /// Main GoRouter configuration with authentication
  static GoRouter get router => _router;

  static final _router = GoRouter(
    initialLocation: welcomePath,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges().asBroadcastStream(),
    ),
    routes: [
      // Welcome screen route - entry point for new users
      GoRoute(
        path: welcomePath,
        name: welcomeName,
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Login screen route - accessed via Sign In button
      GoRoute(
        path: loginPath,
        name: loginName,
        builder: (context, state) =>
            LoginScreen(initialEmail: state.uri.queryParameters['email']),
      ),

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

      // Forgot Password screen route
      GoRoute(
        path: forgotPasswordPath,
        name: forgotPasswordName,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Profile screen route
      GoRoute(
        path: profilePath,
        name: profileName,
        builder: (context, state) => const ProfileScreen(),
      ),

      // Edit entry screen route with entry type support - now using real EditEntryScreen
      GoRoute(
        path: editEntryPath,
        name: editEntryName,
        builder: (context, state) {
          final entryId = state.pathParameters['entryId']!;
          final entryType = state.pathParameters['entryType'];
          return EditEntryScreen(entryId: entryId, entryType: entryType);
        },
      ),

      // Reports screen route - analytics and reporting
      GoRoute(
        path: reportsPath,
        name: reportsName,
        builder: (context, state) => const ReportsScreen(),
      ),

      // Firebase Registration screen route - for creating real Firebase accounts
      GoRoute(
        path: firebaseRegistrationPath,
        name: firebaseRegistrationName,
        builder: (context, state) => const FirebaseRegistrationScreen(),
      ),

      // Debug Auth screen route - for switching between dummy users
      GoRoute(
        path: debugAuthPath,
        name: debugAuthName,
        builder: (context, state) => const DebugAuthScreen(),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),

    // Authentication redirect logic
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isLoggingIn =
          state.uri.path == loginPath || state.uri.path == welcomePath;

      // If user is not logged in and not on login/welcome, redirect to welcome
      if (!isLoggedIn && !isLoggingIn) {
        return welcomePath;
      }

      // If user is logged in and on login/welcome, redirect to home
      if (isLoggedIn && isLoggingIn) {
        return homePath;
      }

      // No redirect needed
      return null;
    },
  );

  // Helper methods

  /// Check if user is authenticated (either Firebase or Dummy)
  static bool _isUserAuthenticated(BuildContext context) {
    // Check Firebase Auth first
    if (FirebaseAuth.instance.currentUser != null) {
      return true;
    }

    // Check Dummy Auth as fallback
    try {
      final dummyAuth = Provider.of<DummyAuthService>(context, listen: false);
      return dummyAuth.isAuthenticated;
    } catch (e) {
      // Provider not available, assume not authenticated
      return false;
    }
  }

  // Helper navigation methods

  /// Navigate to the welcome screen (auth not required)
  static void goToWelcome(BuildContext context) {
    context.goNamed(welcomeName);
  }

  /// Navigate to the login screen (auth not required)
  static void goToLogin(BuildContext context, {String? email}) {
    if (email != null) {
      context.goNamed(loginName, queryParameters: {'email': email});
    } else {
      context.goNamed(loginName);
    }
  }

  /// Navigate to the home screen (requires auth)
  /// If user is not authenticated, redirects to welcome screen
  static void goToHome(BuildContext context) {
    if (_isUserAuthenticated(context)) {
      context.goNamed(homeName);
    } else {
      goToWelcome(context);
    }
  }

  /// Navigate to history screen (requires auth)
  /// If user is not authenticated, redirects to welcome screen
  static void goToHistory(BuildContext context) {
    if (_isUserAuthenticated(context)) {
      context.goNamed(historyName);
    } else {
      goToWelcome(context);
    }
  }

  /// Navigate to settings screen (requires auth)
  /// If user is not authenticated, redirects to welcome screen
  static void goToSettings(BuildContext context) {
    if (_isUserAuthenticated(context)) {
      context.goNamed(settingsName);
    } else {
      goToWelcome(context);
    }
  }

  /// Navigate to contract settings screen (requires auth)
  /// If user is not authenticated, redirects to welcome screen
  static void goToContractSettings(BuildContext context) {
    if (_isUserAuthenticated(context)) {
      context.goNamed(contractSettingsName);
    } else {
      goToWelcome(context);
    }
  }

  /// Navigate to reports screen (requires auth)
  /// If user is not authenticated, redirects to welcome screen
  static void goToReports(BuildContext context) {
    if (_isUserAuthenticated(context)) {
      context.goNamed(reportsName);
    } else {
      goToWelcome(context);
    }
  }

  /// Navigate to edit entry screen (requires auth)
  /// If user is not authenticated, redirects to welcome screen
  static void goToEditEntry(
    BuildContext context, {
    String? entryId,
    String? entryType,
  }) {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      final params = <String, String>{};
      if (entryId != null) {
        params['entryId'] = entryId;
      } else {
        params['entryId'] = 'new';
      }
      if (entryType != null) {
        params['entryType'] = entryType;
      }
      context.goNamed(editEntryName, pathParameters: params);
    } else {
      goToWelcome(context);
    }
  }

  /// Smart back navigation with fallback to home
  static void goBackOrHome(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      context.pop();
    } else {
      goToHome(context);
    }
  }

  /// Check if we can navigate back
  static bool canPop(BuildContext context) {
    return GoRouter.of(context).canPop();
  }

  /// Get current route name
  static String? getCurrentRouteName(BuildContext context) {
    final RouteMatch lastMatch = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : GoRouter.of(context).routerDelegate.currentConfiguration;
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
    goToEditEntry(context, entryId: entryId, entryType: 'travel');
  }

  /// Navigate to edit entry for work type (convenience method)
  static void goToEditWorkEntry(BuildContext context, String entryId) {
    goToEditEntry(context, entryId: entryId, entryType: 'work');
  }

  /// Navigate to forgot password screen
  static void goToForgotPassword(BuildContext context) {
    context.goNamed(forgotPasswordName);
  }

  /// Navigate to profile screen
  static void goToProfile(BuildContext context) {
    context.goNamed(profileName);
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
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Oops! Something went wrong.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                error?.toString() ?? 'Unknown navigation error occurred',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
                    onPressed: () => AppRouter.goToHome(context),
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
