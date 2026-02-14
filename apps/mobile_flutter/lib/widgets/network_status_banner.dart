import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/network_status_provider.dart';
import '../providers/entry_provider.dart';
import '../l10n/generated/app_localizations.dart';

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
        final showBanner =
            isOffline || hasPendingSync || isSyncing || syncError != null;

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
    final t = AppLocalizations.of(context);

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
            child: Text(t.common_retry, style: TextStyle(color: textColor)),
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
          ? t.network_offlinePending(pendingCount)
          : t.network_youAreOffline;
      trailing = null;
    } else if (isSyncing) {
      // Syncing state
      backgroundColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
      icon = Icons.sync;
      message = t.network_syncingChanges;
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
      message = t.network_readyToSync(pendingCount);
      trailing = TextButton(
        onPressed: onRetry,
        child: Text(t.network_syncNow, style: TextStyle(color: textColor)),
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
    final t = AppLocalizations.of(context);
    return Consumer2<NetworkStatusProvider, EntryProvider>(
      builder: (context, networkStatus, entryProvider, _) {
        if (networkStatus.isOffline) {
          return _buildIndicator(
            context,
            icon: Icons.cloud_off,
            tooltip: t.network_offlineTooltip,
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
            tooltip: t.network_pendingTooltip(entryProvider.pendingSyncCount),
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
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(t.network_offlineSnackbar),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showOnline(BuildContext context) {
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_done, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(t.network_backOnline),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showSyncComplete(BuildContext context, int count) {
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_done, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(t.network_syncedChanges(count)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showSyncFailed(BuildContext context, String error) {
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.sync_problem, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(t.network_syncFailed(error))),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: t.common_retry,
          textColor: Colors.white,
          onPressed: () {
            context.read<EntryProvider>().processPendingSync();
          },
        ),
      ),
    );
  }

  static void showNetworkError(BuildContext context, {String? message}) {
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(message ?? t.network_networkErrorTryAgain)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
