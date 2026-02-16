import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_router.dart';
import '../providers/entry_provider.dart';
import '../providers/network_status_provider.dart';
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
    final t = AppLocalizations.of(context);
    final isWideLayout = MediaQuery.sizeOf(context).width > 600;
    final selectedIndex = _calculateSelectedIndex(widget.currentPath);

    final bodyWithBanner = Stack(
      children: [
        Positioned.fill(child: widget.child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _ConnectivityBanner(
            messageResolver: (pendingCount, isOffline) {
              if (isOffline && pendingCount > 0) {
                return t.network_offlinePending(pendingCount);
              }
              return t.network_offlineSnackbar;
            },
          ),
        ),
      ],
    );

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
        body: isWideLayout
            ? Row(
                children: [
                  SafeArea(
                    child: NavigationRail(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (index) =>
                          _onItemTapped(index, context),
                      labelType: NavigationRailLabelType.selected,
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.home_outlined),
                          selectedIcon: const Icon(Icons.home),
                          label: Text(t.nav_home),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.history_outlined),
                          selectedIcon: const Icon(Icons.history),
                          label: Text(t.nav_history),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.analytics_outlined),
                          selectedIcon: const Icon(Icons.analytics),
                          label: Text(t.nav_reports),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.settings_outlined),
                          selectedIcon: const Icon(Icons.settings),
                          label: Text(t.nav_settings),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: bodyWithBanner),
                ],
              )
            : bodyWithBanner,
        bottomNavigationBar: isWideLayout
            ? null
            : NavigationBar(
                selectedIndex: selectedIndex,
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

class _ConnectivityBanner extends StatelessWidget {
  final String Function(int pendingCount, bool isOffline) messageResolver;

  const _ConnectivityBanner({required this.messageResolver});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Consumer2<NetworkStatusProvider, EntryProvider>(
        builder: (context, networkStatus, entryProvider, _) {
          final isOffline = networkStatus.isOffline;
          final pendingCount = entryProvider.pendingSyncCount;
          final showBanner = isOffline;

          return IgnorePointer(
            ignoring: !showBanner,
            child: AnimatedSlide(
              offset: showBanner ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: showBanner ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 18,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          messageResolver(pendingCount, isOffline),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
