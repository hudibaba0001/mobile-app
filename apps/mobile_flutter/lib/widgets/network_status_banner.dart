import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/network_status_provider.dart';
import '../providers/entry_provider.dart';

/// A banner that shows network status and pending sync operations
/// Automatically appears when offline or when there are pending syncs
class NetworkStatusBanner extends StatelessWidget {
  final Widget child;

  const NetworkStatusBanner({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<NetworkStatusProvider, EntryProvider>(
      builder: (context, networkStatus, entryProvider, _) {
        final isOffline = networkStatus.isOffline;
        final hasPendingSync = entryProvider.hasPendingSync;
        final isSyncing = entryProvider.isSyncing;
        final syncError = entryProvider.syncError;

        // Show banner if offline, has pending sync, is syncing, or has sync error
        final showBanner = isOffline || hasPendingSync || isSyncing || syncError != null;

        return Column(
          children: [
            if (showBanner)
              _NetworkBannerContent(
                isOffline: isOffline,
                hasPendingSync: hasPendingSync,
                pendingCount: entryProvider.pendingSyncCount,
                isSyncing: isSyncing,
                syncError: syncError,
                onRetry: () async {
                  await entryProvider.processPendingSync();
                },
                onDismissError: () {
                  entryProvider.clearSyncError();
                },
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _NetworkBannerContent extends StatelessWidget {
  final bool isOffline;
  final bool hasPendingSync;
  final int pendingCount;
  final bool isSyncing;
  final String? syncError;
  final VoidCallback onRetry;
  final VoidCallback onDismissError;

  const _NetworkBannerContent({
    required this.isOffline,
    required this.hasPendingSync,
    required this.pendingCount,
    required this.isSyncing,
    required this.syncError,
    required this.onRetry,
    required this.onDismissError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine banner color and content based on state
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;
    Widget? trailing;

    if (syncError != null) {
      // Sync error state
      backgroundColor = colorScheme.errorContainer;
      textColor = colorScheme.onErrorContainer;
      icon = Icons.sync_problem;
      message = syncError!;
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: onRetry,
            child: Text('Retry', style: TextStyle(color: textColor)),
          ),
          IconButton(
            icon: Icon(Icons.close, color: textColor, size: 18),
            onPressed: onDismissError,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
    } else if (isOffline) {
      // Offline state
      backgroundColor = colorScheme.tertiaryContainer;
      textColor = colorScheme.onTertiaryContainer;
      icon = Icons.cloud_off;
      message = hasPendingSync
          ? 'Offline - $pendingCount changes pending'
          : 'You are offline';
      trailing = null;
    } else if (isSyncing) {
      // Syncing state
      backgroundColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
      icon = Icons.sync;
      message = 'Syncing changes...';
      trailing = SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: textColor,
        ),
      );
    } else if (hasPendingSync) {
      // Online with pending sync
      backgroundColor = colorScheme.secondaryContainer;
      textColor = colorScheme.onSecondaryContainer;
      icon = Icons.cloud_upload;
      message = '$pendingCount changes ready to sync';
      trailing = TextButton(
        onPressed: onRetry,
        child: Text('Sync Now', style: TextStyle(color: textColor)),
      );
    } else {
      // This shouldn't happen given the showBanner logic, but just in case
      return const SizedBox.shrink();
    }

    return Material(
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A simpler inline indicator for showing sync status in specific locations
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NetworkStatusProvider, EntryProvider>(
      builder: (context, networkStatus, entryProvider, _) {
        if (networkStatus.isOffline) {
          return _buildIndicator(
            context,
            icon: Icons.cloud_off,
            tooltip: 'Offline',
            color: Theme.of(context).colorScheme.tertiary,
          );
        }

        if (entryProvider.isSyncing) {
          return SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (entryProvider.hasPendingSync) {
          return _buildIndicator(
            context,
            icon: Icons.cloud_upload,
            tooltip: '${entryProvider.pendingSyncCount} pending',
            color: Theme.of(context).colorScheme.secondary,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildIndicator(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 20, color: color),
    );
  }
}

/// Snackbar helper for showing network-related messages
class NetworkSnackbar {
  static void showOffline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('You are offline. Changes will sync when connected.'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showOnline(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.cloud_done, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Back online'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showSyncComplete(BuildContext context, int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_done, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Synced $count changes'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showSyncFailed(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.sync_problem, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text('Sync failed: $error')),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            context.read<EntryProvider>().processPendingSync();
          },
        ),
      ),
    );
  }

  static void showNetworkError(BuildContext context, {String? message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message ?? 'Network error. Please try again.')),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
