import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_router.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const AppScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final canPop = router.canPop();
    final isOnHomeTab = _isOnMainTab(currentPath);

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
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _calculateSelectedIndex(currentPath),
          onDestinationSelected: (index) => _onItemTapped(index, context),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
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
