import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/supabase_auth_service.dart';
import '../widgets/app_scaffold.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/unified_home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/contract_settings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/history_screen.dart';
import '../screens/edit_entry_screen.dart';
import '../screens/manage_locations_screen.dart';
import '../screens/time_balance_screen.dart';
import '../screens/absence_management_screen.dart';
import '../screens/account_status_gate.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static const String loginPath = '/login';
  static const String signupPath = '/signup';
  static const String forgotPasswordPath = '/forgot-password';

  static const String homePath = '/';
  static const String settingsPath = '/settings';
  static const String reportsPath = '/reports';
  static const String historyPath = '/history';
  static const String analyticsPath = '/analytics';
  static const String contractSettingsPath = '/settings/contract';
  static const String profilePath = '/profile';
  static const String editEntryPath = '/edit-entry';
  static const String manageLocationsPath = '/manage-locations';
  static const String timeBalancePath = '/time-balance';
  static const String absenceManagementPath = '/absences';

  static const String loginName = 'login';
  static const String signupName = 'signup';
  static const String forgotPasswordName = 'forgot-password';

  static const String homeName = 'home';
  static const String settingsName = 'settings';
  static const String reportsName = 'reports';
  static const String historyName = 'history';
  static const String analyticsName = 'analytics';
  static const String contractSettingsName = 'contract-settings';
  static const String profileName = 'profile';
  static const String editEntryName = 'editEntry';
  static const String manageLocationsName = 'manage-locations';
  static const String timeBalanceName = 'time-balance';
  static const String absenceManagementName = 'absences';

  // Premium Shared Axis Transition Builder
  static CustomTransitionPage _buildSharedAxisTransitionPage({
    required Widget child,
    required GoRouterState state,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
          child: SlideTransition(
            position: animation.drive(
              Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          ),
        );
      },
    );
  }

  static final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: homePath,
    redirect: (context, state) async {
      final authService = context.read<SupabaseAuthService>();
      final isAuthenticated = authService.isAuthenticated;
      final isInitialized = authService.isInitialized;
      final isLoggingIn = state.matchedLocation == loginPath;
      final isSigningUp = state.matchedLocation == signupPath;
      final isForgotPassword = state.matchedLocation == forgotPasswordPath;
      final isAnalyticsRoute = state.matchedLocation == analyticsPath;

      // Wait for AuthService to be initialized
      if (!isInitialized) {
        return null; // Don't redirect yet
      }

      // Allow access to auth-related screens without authentication
      if (isForgotPassword || isSigningUp) {
        return null;
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

      if (isAuthenticated && (isLoggingIn || isSigningUp)) {
        return homePath;
      }
      return null;
    },
    routes: [
      // Login (outside shell)
      GoRoute(
        path: loginPath,
        name: loginName,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return LoginScreen(initialEmail: email);
        },
      ),

      GoRoute(
        path: signupPath,
        name: signupName,
        builder: (context, state) => const SignupScreen(),
      ),

      GoRoute(
        path: forgotPasswordPath,
        name: forgotPasswordName,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Admin analytics (outside shell)
      GoRoute(
        path: analyticsPath,
        name: analyticsName,
        builder: (context, state) => const AnalyticsScreen(),
      ),

      // Shell with bottom navigation for main tabs
      // Wrapped in AccountStatusGate to check legal/subscription status
      ShellRoute(
        builder: (context, state, child) => AccountStatusGate(
          child: AppScaffold(
            currentPath: state.matchedLocation,
            child: child,
          ),
        ),
        routes: [
          // Home tab and its nested routes
          GoRoute(
            path: homePath,
            name: homeName,
            pageBuilder: (context, state) => _buildSharedAxisTransitionPage(
              child: const UnifiedHomeScreen(),
              state: state,
            ),
            routes: [
              GoRoute(
                path: 'edit-entry',
                name: editEntryName,
                builder: (context, state) {
                  final entryId = state.uri.queryParameters['id'] ?? '';
                  final entryType = state.uri.queryParameters['type'];
                  return EditEntryScreen(
                      entryId: entryId, entryType: entryType);
                },
              ),
              GoRoute(
                path: 'manage-locations',
                name: manageLocationsName,
                builder: (context, state) => const ManageLocationsScreen(),
              ),
              GoRoute(
                path: 'profile',
                name: profileName,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),

          // History tab
          GoRoute(
            path: historyPath,
            name: historyName,
            pageBuilder: (context, state) => _buildSharedAxisTransitionPage(
              child: const HistoryScreen(),
              state: state,
            ),
          ),

          // Reports tab
          GoRoute(
            path: reportsPath,
            name: reportsName,
            pageBuilder: (context, state) => _buildSharedAxisTransitionPage(
              child: const ReportsScreen(),
              state: state,
            ),
          ),

          // Settings tab and nested contract
          GoRoute(
            path: settingsPath,
            name: settingsName,
            pageBuilder: (context, state) => _buildSharedAxisTransitionPage(
              child: const SettingsScreen(),
              state: state,
            ),
            routes: [
              GoRoute(
                path: 'contract',
                name: contractSettingsName,
                builder: (context, state) => const ContractSettingsScreen(),
              ),
            ],
          ),

          // Absence Management screen
          GoRoute(
            path: absenceManagementPath,
            name: absenceManagementName,
            pageBuilder: (context, state) => _buildSharedAxisTransitionPage(
              child: const AbsenceManagementScreen(),
              state: state,
            ),
          ),

          // Time Balance screen
          GoRoute(
            path: timeBalancePath,
            name: timeBalanceName,
            pageBuilder: (context, state) => _buildSharedAxisTransitionPage(
              child: const TimeBalanceScreen(),
              state: state,
            ),
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

  static void goToForgotPassword(BuildContext context) =>
      context.goNamed(forgotPasswordName);
  static void goToSignup(BuildContext context) => context.goNamed(signupName);

  static void goToHome(BuildContext context) => context.goNamed(homeName);
  static void goToSettings(BuildContext context) =>
      context.goNamed(settingsName);
  static void goToReports(BuildContext context) => context.goNamed(reportsName);
  static void goToAnalytics(BuildContext context) =>
      context.goNamed(analyticsName);
  static void goToContractSettings(BuildContext context) =>
      context.goNamed(contractSettingsName);
  static void goToTimeBalance(BuildContext context) =>
      context.goNamed(timeBalanceName);
  static void goToProfile(BuildContext context) => context.goNamed(profileName);

  // Additional navigation methods
  static String getCurrentRouteName(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == homePath) return homeName;
    if (location == loginPath) return loginName;
    if (location == settingsPath) return settingsName;
    if (location == reportsPath) return reportsName;
    if (location == historyPath) return historyName;
    if (location == analyticsPath) return analyticsName;
    if (location == contractSettingsPath) return contractSettingsName;
    if (location == profilePath) return profileName;
    return homeName;
  }

  static void goToHistory(BuildContext context) => context.goNamed(historyName);
  static void goToEditEntry(BuildContext context,
      {required String entryId, required String entryType}) {
    // Use push so the screen can pop back without GoError
    context.pushNamed(editEntryName, queryParameters: {
      'id': entryId,
      'type': entryType,
    });
  }

  static void goBackOrHome(BuildContext context) {
    final currentRoute = getCurrentRouteName(context);

    // If we're on a main tab (home, history, settings), go home instead of exiting
    if ([homeName, historyName, settingsName].contains(currentRoute)) {
      if (currentRoute != homeName) {
        context.goNamed(homeName);
      }
      return;
    }

    // For other screens, try to go back, fallback to home
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(homeName);
    }
  }

  static void goToManageLocations(BuildContext context) {
    // Use push so user can return with back
    context.pushNamed(manageLocationsName);
  }
}
