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
    final theme = Theme.of(context);

    return Scaffold(
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
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(String currentPath) {
    if (currentPath.startsWith(AppRouter.historyPath)) return 1;
    if (currentPath.startsWith(AppRouter.settingsPath)) return 2;
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
        context.go(AppRouter.settingsPath);
        break;
    }
  }
}
