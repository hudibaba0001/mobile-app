import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/supabase_config.dart';
import '../design/app_theme.dart';

/// Fetches active messages from the server and displays them as banners.
/// Place this widget at the top of your home screen.
class AppMessageBanner extends StatefulWidget {
  const AppMessageBanner({super.key});

  @override
  State<AppMessageBanner> createState() => _AppMessageBannerState();
}

class _AppMessageBannerState extends State<AppMessageBanner> {
  List<Map<String, dynamic>> _messages = [];
  final Set<String> _dismissedIds = {};
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;

      final now = DateTime.now().toUtc().toIso8601String();
      final response = await SupabaseConfig.client
          .from('app_messages')
          .select()
          .eq('is_active', true)
          .lte('starts_at', now)
          .order('created_at', ascending: false);

      if (!mounted) return;

      final messages = (response as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((msg) => _isMessageApplicable(msg))
          .toList();

      setState(() {
        _messages = messages;
      });
    } catch (e) {
      // Silently fail — messages are non-critical
      debugPrint('AppMessageBanner: Failed to load messages: $e');
    }
  }

  bool _isMessageApplicable(Map<String, dynamic> msg) {
    // Check expiry
    final expiresAt = msg['expires_at'] as String?;
    if (expiresAt != null) {
      final expiry = DateTime.tryParse(expiresAt);
      if (expiry != null && DateTime.now().toUtc().isAfter(expiry)) {
        return false;
      }
    }

    // Check min version
    final minVersion = msg['min_app_version'] as String?;
    if (minVersion != null && minVersion.isNotEmpty) {
      if (_compareVersions(_appVersion, minVersion) < 0) {
        return false;
      }
    }

    // Check max version
    final maxVersion = msg['max_app_version'] as String?;
    if (maxVersion != null && maxVersion.isNotEmpty) {
      if (_compareVersions(_appVersion, maxVersion) > 0) {
        return false;
      }
    }

    return true;
  }

  /// Compare two semver strings. Returns negative if a < b, 0 if equal, positive if a > b.
  int _compareVersions(String a, String b) {
    final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final length = aParts.length > bParts.length ? aParts.length : bParts.length;

    for (var i = 0; i < length; i++) {
      final aVal = i < aParts.length ? aParts[i] : 0;
      final bVal = i < bParts.length ? bParts[i] : 0;
      if (aVal != bVal) return aVal.compareTo(bVal);
    }
    return 0;
  }

  Color _bannerColor(String type, ThemeData theme) {
    switch (type) {
      case 'warning':
        return Colors.orange.shade700;
      case 'update':
        return theme.colorScheme.primary;
      case 'maintenance':
        return Colors.red.shade700;
      default:
        return theme.colorScheme.secondary;
    }
  }

  IconData _bannerIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'update':
        return Icons.system_update;
      case 'maintenance':
        return Icons.construction;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleMessages = _messages
        .where((msg) => !_dismissedIds.contains(msg['id'] as String))
        .toList();

    if (visibleMessages.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: visibleMessages.map((msg) {
        final id = msg['id'] as String;
        final title = msg['title'] as String;
        final body = msg['body'] as String;
        final type = msg['type'] as String? ?? 'info';
        final actionUrl = msg['action_url'] as String?;
        final actionLabel = msg['action_label'] as String?;
        final isDismissible = msg['is_dismissible'] as bool? ?? true;
        final color = _bannerColor(type, theme);

        return MaterialBanner(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          backgroundColor: color.withValues(alpha: 0.1),
          leading: Icon(_bannerIcon(type), color: color),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(body, style: theme.textTheme.bodySmall),
            ],
          ),
          actions: [
            if (actionUrl != null && actionUrl.isNotEmpty)
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(actionUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(actionLabel ?? 'Open'),
              ),
            if (isDismissible)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  setState(() {
                    _dismissedIds.add(id);
                  });
                },
              ),
          ],
        );
      }).toList(),
    );
  }
}
