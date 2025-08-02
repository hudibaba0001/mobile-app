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

class AppRouter {
  static const String loginPath = '/login';
  static const String homePath = '/';
  static const String settingsPath = '/settings';
  static const String reportsPath = '/reports';
  static const String adminUsersPath = '/admin/users';
  static const String contractSettingsPath = '/settings/contract';
  static const String profilePath = '/profile';

  static const String loginName = 'login';
  static const String homeName = 'home';
  static const String settingsName = 'settings';
  static const String reportsName = 'reports';
  static const String adminUsersName = 'admin-users';
  static const String contractSettingsName = 'contract-settings';
  static const String profileName = 'profile';

  static final router = GoRouter(
    initialLocation: homePath,
    redirect: (context, state) {
      final authService = context.read<AuthService>();
      final isAuthenticated = authService.isAuthenticated;
      final isLoggingIn = state.matchedLocation == loginPath;

      if (!isAuthenticated && !isLoggingIn) {
        return loginPath;
      }

      if (isAuthenticated && isLoggingIn) {
        return homePath;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: loginPath,
        name: loginName,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return LoginScreen(initialEmail: email);
        },
      ),
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
        path: adminUsersPath,
        name: adminUsersName,
        builder: (context, state) => const AdminUsersScreen(),
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
    if (location == contractSettingsPath) return contractSettingsName;
    if (location == profilePath) return profileName;
    return homeName;
  }

  static void goToHistory(BuildContext context) => context.goNamed(reportsName);
  static void goToEditEntry(BuildContext context, {required String entryId, required String entryType}) {
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
