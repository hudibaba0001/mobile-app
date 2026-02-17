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
import '../widgets/legal_document_dialog.dart';
import '../widgets/standard_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _error;
  final _nameController = TextEditingController();

  String _friendlyError(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

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

    final rawName = (user.userMetadata?['full_name'] as String?)?.trim();
    final displayName =
        (rawName != null && rawName.isNotEmpty) ? rawName : (user.email ?? '—');
    final email = user.email ?? '—';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: StandardAppBar(
        title: t.profile_title,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        onBack: () => AppRouter.goBackOrHome(context),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                _error!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: theme.colorScheme.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

          _buildHeroHeader(
            theme: theme,
            name: displayName,
            email: email,
          ),
          const SizedBox(height: AppSpacing.xxl + AppSpacing.sm),

          // User Info Card
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
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
                              t.profile_labelName,
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
                        tooltip: t.profile_editName,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Email
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.profile_labelEmail,
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

          const SizedBox(height: AppSpacing.lg),

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
            trailing: const Icon(Icons.chevron_right),
            onTap: () => LegalDocumentDialog.showPrivacy(context),
          ),

          // Terms of Service
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(t.settings_terms),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => LegalDocumentDialog.showTerms(context),
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

          // Admin section (only visible to admins)
          FutureBuilder<bool>(
            future: authService.isAdmin(),
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return Column(
                children: [
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      top: AppSpacing.sm,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Admin',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Manage Users'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => AppRouter.goToAdminUsers(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_document),
                    title: const Text('Content Management'),
                    subtitle: const Text('Legal docs & app messages'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => AppRouter.goToAdminContent(context),
                  ),
                ],
              );
            },
          ),

          const Divider(),

          // Sign Out
          ListTile(
            leading:
                Icon(Icons.logout, color: theme.colorScheme.onSurfaceVariant),
            title: Text(t.profile_signOut),
            onTap: _handleSignOut,
          ),

          // Delete Account
          ListTile(
            leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
            title: Text(
              t.settings_deleteAccount,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
            subtitle: Text(t.settings_deleteAccountDesc),
            onTap: () => _showDeleteAccountDialog(context, authService, t),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildHeroHeader({
    required ThemeData theme,
    required String name,
    required String email,
  }) {
    final firstGlyph = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 140),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientStart.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.neutral50,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutral50.withValues(alpha: 0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -34,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.neutral50, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  firstGlyph,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
        content: AppTextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          hintText: t.profile_editName,
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
    final deleteKeyword = t.common_delete.toUpperCase();

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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: theme.colorScheme.error),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                t.settings_deleteAccountConfirmHint
                    .replaceAll('DELETE', deleteKeyword),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                onChanged: (value) {
                  setState(() => confirmationText = value);
                },
                hintText: deleteKeyword,
                enabled: !isDeleting,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isDeleting ? null : () => Navigator.of(context).pop(false),
              child: Text(t.common_cancel),
            ),
            FilledButton(
              onPressed: isDeleting ||
                      confirmationText.trim().toUpperCase() != deleteKeyword
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
                            content: Text(t.settings_deleteAccountError(
                                _friendlyError(e))),
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
      try {
        await authService.signOut();
      } catch (_) {}
      if (context.mounted) {
        context.go(AppRouter.loginPath);
      }
    }
  }
}
