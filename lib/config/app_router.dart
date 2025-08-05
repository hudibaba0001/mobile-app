import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/unified_home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/admin_users_screen.dart';
import '../screens/contract_settings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/analytics_screen.dart';

class AppRouter {
  static const String loginPath = '/login';
  static const String homePath = '/';
  static const String settingsPath = '/settings';
  static const String reportsPath = '/reports';
  static const String adminUsersPath = '/admin/users';
  static const String analyticsPath = '/analytics';
  static const String contractSettingsPath = '/settings/contract';
  static const String profilePath = '/profile';

  static const String loginName = 'login';
  static const String homeName = 'home';
  static const String settingsName = 'settings';
  static const String reportsName = 'reports';
  static const String adminUsersName = 'admin-users';
  static const String analyticsName = 'analytics';
  static const String contractSettingsName = 'contract-settings';
  static const String profileName = 'profile';

  static final router = GoRouter(
    initialLocation: homePath,
    redirect: (context, state) async {
      final authService = context.read<AuthService>();
      final isAuthenticated = authService.isAuthenticated;
      final isInitialized = authService.isInitialized;
      final isLoggingIn = state.matchedLocation == loginPath;
      final isAnalyticsRoute = state.matchedLocation == analyticsPath;

      // Wait for AuthService to be initialized
      if (!isInitialized) {
        return null; // Don't redirect yet
      }

      // Protect analytics route - require authentication AND admin privileges
      if (isAnalyticsRoute) {
        if (!isAuthenticated) {
          return loginPath;
        }
        // Check if user is admin
        final isAdmin = await authService.isAdmin();
        if (!isAdmin) {
          // Redirect non-admin users to home page
          return homePath;
        }
      }

      if (!isAuthenticated && !isLoggingIn) {
        return loginPath;
      }

      if (isAuthenticated && isLoggingIn) {
        return homePath;
      }
      return null;
    },
    routes: [
      // Login route (outside shell)
      GoRoute(
        path: loginPath,
        name: loginName,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return LoginScreen(initialEmail: email);
        },
      ),
      // Analytics route (outside shell - admin only)
      GoRoute(
        path: analyticsPath,
        name: analyticsName,
        builder: (context, state) => const AnalyticsScreen(),
      ),
      // Main app shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          // This will be the shell that contains the bottom navigation
          // For now, we'll use the UnifiedHomeScreen as the shell
          return child;
        },
        routes: [
          GoRoute(
            path: homePath,
            name: homeName,
            builder: (context, state) => const UnifiedHomeScreen(),
          ),
          GoRoute(
            path: settingsPath,
            name: settingsName,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: reportsPath,
            name: reportsName,
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: contractSettingsPath,
            name: contractSettingsName,
            builder: (context, state) => const ContractSettingsScreen(),
          ),
          GoRoute(
            path: profilePath,
            name: profileName,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: adminUsersPath,
            name: adminUsersName,
            builder: (context, state) => const AdminUsersScreen(),
          ),
        ],
      ),
    ],
  );

  static void goToLogin(BuildContext context, {String? email}) {
    if (email != null) {
      context.goNamed(loginName, queryParameters: {'email': email});
    } else {
      context.goNamed(loginName);
    }
  }

  static void goToHome(BuildContext context) => context.goNamed(homeName);
  static void goToSettings(BuildContext context) =>
      context.goNamed(settingsName);
  static void goToReports(BuildContext context) => context.goNamed(reportsName);
  static void goToAdminUsers(BuildContext context) =>
      context.goNamed(adminUsersName);
  static void goToAnalytics(BuildContext context) =>
      context.goNamed(analyticsName);
  static void goToContractSettings(BuildContext context) =>
      context.goNamed(contractSettingsName);
  static void goToProfile(BuildContext context) => context.goNamed(profileName);

  // Additional navigation methods
  static String getCurrentRouteName(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == homePath) return homeName;
    if (location == loginPath) return loginName;
    if (location == settingsPath) return settingsName;
    if (location == reportsPath) return reportsName;
    if (location == adminUsersPath) return adminUsersName;
    if (location == analyticsPath) return analyticsName;
    if (location == contractSettingsPath) return contractSettingsName;
    if (location == profilePath) return profileName;
    return homeName;
  }

  static void goToHistory(BuildContext context) => context.goNamed(reportsName);
  static void goToEditEntry(BuildContext context,
      {required String entryId, required String entryType}) {
    // For now, just go to reports since edit entry screen was removed
    context.goNamed(reportsName);
  }

  static void goBackOrHome(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(homeName);
    }
  }

  static const String historyName = 'history';
}
