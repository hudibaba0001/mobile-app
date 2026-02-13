// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../design/design.dart';
import '../services/supabase_auth_service.dart';
import '../config/app_router.dart';
import '../config/external_links.dart';
import '../l10n/generated/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _error;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = context.read<SupabaseAuthService>().currentUser;
    if (user != null) {
      _nameController.text =
          user.userMetadata?['full_name'] ?? user.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final authService = context.watch<SupabaseAuthService>();
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(body: Center(child: Text(t.profile_notSignedIn)));
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(t.profile_title),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.goBackOrHome(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

          // Profile Icon
          Center(
            child: Icon(
              Icons.account_circle_outlined,
              size: 96,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 24),

          // User Info Card
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              user.userMetadata?['full_name'] ??
                                  user.email ??
                                  '—',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditNameDialog(context, user),
                        tooltip: 'Edit Name',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Email
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(user.email ?? '—', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Change Password
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(t.settings_changePassword),
            subtitle: Text(t.settings_changePasswordDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final email = authService.currentUserEmail;
              if (email == null) return;
              try {
                await authService.sendPasswordResetEmail(email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.settings_changePasswordSent)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${t.common_error}: $e'),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              }
            },
          ),

          // Manage Subscription
          ListTile(
            leading: const Icon(Icons.payment_outlined),
            title: Text(t.settings_manageSubscription),
            subtitle: Text(t.settings_subscriptionDesc),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(
              Uri.parse(ExternalLinks.manageSubscriptionUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),

          const Divider(),

          // Privacy Policy
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(t.settings_privacy),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(
              Uri.parse(ExternalLinks.privacyUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),

          // Terms of Service
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(t.settings_terms),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(
              Uri.parse(ExternalLinks.termsUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),

          // Contact Support
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(t.settings_contactSupport),
            subtitle: Text(t.settings_contactSupportDesc),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(
              Uri.parse('mailto:${ExternalLinks.supportEmail}'),
            ),
          ),

          // About / Version
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData
                  ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                  : '...';
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(t.settings_about),
                subtitle: Text(t.settings_version(version)),
              );
            },
          ),

          const Divider(),

          // Sign Out
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.onSurfaceVariant),
            title: Text(t.profile_signOut),
            onTap: _handleSignOut,
          ),

          // Delete Account
          ListTile(
            leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
            title: Text(
              t.settings_deleteAccount,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: Text(t.settings_deleteAccountDesc),
            onTap: () => _showDeleteAccountDialog(context, authService, t),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    try {
      final authService = context.read<SupabaseAuthService>();
      await authService.signOutWithCleanup(() async {});
      if (mounted) {
        AppRouter.goToLogin(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to sign out: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _showEditNameDialog(BuildContext context, User user) async {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = TextEditingController(
        text: user.userMetadata?['full_name'] ?? user.email ?? '');

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.profile_editName),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common_cancel),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              try {
                final authService = context.read<SupabaseAuthService>();
                await authService.updateUserProfile(displayName: newName);
                if (mounted) {
                  setState(() {}); // Refresh UI
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.profile_nameUpdated),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.profile_nameUpdateFailed(e.toString())),
                      backgroundColor: theme.colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(t.common_save),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(
    BuildContext context,
    SupabaseAuthService authService,
    AppLocalizations t,
  ) async {
    String confirmationText = '';
    bool isDeleting = false;
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(t.settings_deleteAccountConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.settings_deleteAccountConfirmBody,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                t.settings_deleteAccountConfirmHint,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                onChanged: (value) {
                  setState(() => confirmationText = value);
                },
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  border: const OutlineInputBorder(),
                  enabled: !isDeleting,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.of(context).pop(false),
              child: Text(t.common_cancel),
            ),
            FilledButton(
              onPressed: isDeleting || confirmationText != 'DELETE'
                  ? null
                  : () async {
                      setState(() => isDeleting = true);
                      try {
                        await authService.deleteAccount();
                        if (!context.mounted) return;
                        Navigator.of(context).pop(true);
                      } catch (e) {
                        if (!context.mounted) return;
                        setState(() => isDeleting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t.settings_deleteAccountError(e.toString())),
                            backgroundColor: theme.colorScheme.error,
                          ),
                        );
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: isDeleting
                  ? SizedBox(
                      width: AppIconSize.sm,
                      height: AppIconSize.sm,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onError),
                      ),
                    )
                  : Text(t.settings_deleteAccount),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await authService.signOut();
      if (context.mounted) {
        context.go(AppRouter.loginPath);
      }
    }
  }
}
