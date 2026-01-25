import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_router.dart';
import '../providers/entry_provider.dart';
import '../services/supabase_auth_service.dart';
import '../l10n/generated/app_localizations.dart';

class AppScaffold extends StatefulWidget {
  final Widget child;
  final String currentPath;

  const AppScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _hasLoadedEntries = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Load entries once when user is authenticated
    if (!_hasLoadedEntries) {
      final authService = context.read<SupabaseAuthService>();
      final entryProvider = context.read<EntryProvider>();

      if (authService.isAuthenticated &&
          entryProvider.entries.isEmpty &&
          !entryProvider.isLoading) {
        _hasLoadedEntries = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          entryProvider.loadEntries();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final canPop = router.canPop();
    final isOnHomeTab = _isOnMainTab(widget.currentPath);

    return PopScope(
      canPop: canPop, // if false (root), intercept back to avoid exit
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (router.canPop()) {
          router.pop();
        } else {
          // At root: stay in app. If not on home tab, go home.
          if (!isOnHomeTab) {
            context.go(AppRouter.homePath);
          }
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: Builder(
          builder: (context) {
            final t = AppLocalizations.of(context);
            return NavigationBar(
              selectedIndex: _calculateSelectedIndex(widget.currentPath),
              onDestinationSelected: (index) => _onItemTapped(index, context),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: t.nav_home,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.history_outlined),
                  selectedIcon: const Icon(Icons.history),
                  label: t.nav_history,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.analytics_outlined),
                  selectedIcon: const Icon(Icons.analytics),
                  label: t.nav_reports,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: t.nav_settings,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  int _calculateSelectedIndex(String currentPath) {
    if (currentPath.startsWith(AppRouter.historyPath)) return 1;
    if (currentPath.startsWith(AppRouter.reportsPath)) return 2;
    if (currentPath.startsWith(AppRouter.settingsPath)) return 3;
    return 0; // Home is default
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRouter.homePath);
        break;
      case 1:
        context.go(AppRouter.historyPath);
        break;
      case 2:
        context.go(AppRouter.reportsPath);
        break;
      case 3:
        context.go(AppRouter.settingsPath);
        break;
    }
  }

  bool _isOnMainTab(String path) {
    return path.startsWith(AppRouter.homePath) ||
        path.startsWith(AppRouter.historyPath) ||
        path.startsWith(AppRouter.reportsPath) ||
        path.startsWith(AppRouter.settingsPath);
  }
}
