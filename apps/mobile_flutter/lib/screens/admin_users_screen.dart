// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_user.dart';
import '../services/admin_api_service.dart';
import '../viewmodels/admin_users_view_model.dart';
import '../design/app_theme.dart';
import '../design/components/components.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/standard_app_bar.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AdminUsersViewModel(context.read<AdminApiService>()),
      child: const _AdminUsersScreenContent(),
    );
  }
}

class _AdminUsersScreenContent extends StatefulWidget {
  const _AdminUsersScreenContent();

  @override
  State<_AdminUsersScreenContent> createState() =>
      _AdminUsersScreenContentState();
}

class _AdminUsersScreenContentState extends State<_AdminUsersScreenContent> {
  @override
  void initState() {
    super.initState();
    // Fetch users when the screen is mounted
    Future.microtask(() {
      if (mounted) {
        context.read<AdminUsersViewModel>().fetchUsers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = AppLocalizations.of(context);
    final viewModel = context.watch<AdminUsersViewModel>();

    return Scaffold(
      appBar: StandardAppBar(
        title: t.adminUsers_title,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                // Search Field
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    hintText: t.adminUsers_searchHint,
                    prefixIcon: const Icon(Icons.search),
                    onChanged: viewModel.setSearchQuery,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // Filter Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: viewModel.filterRole,
                    decoration: appInputDecoration(
                      context,
                      labelText: t.adminUsers_filterByRole,
                    ),
                    items: [
                      DropdownMenuItem(
                          value: 'All', child: Text(t.adminUsers_roleAll)),
                      DropdownMenuItem(
                          value: 'Admin', child: Text(t.adminUsers_roleAdmin)),
                      DropdownMenuItem(
                          value: 'User', child: Text(t.adminUsers_roleUser)),
                    ],
                    onChanged: (value) =>
                        viewModel.setFilterRole(value ?? 'All'),
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: Builder(
              builder: (context) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.error != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: AppIconSize.xl,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          t.adminUsers_failedLoadUsers,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          viewModel.error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          onPressed: viewModel.fetchUsers,
                          icon: const Icon(Icons.refresh),
                          label: Text(t.common_retry),
                        ),
                      ],
                    ),
                  );
                }

                final filteredUsers = viewModel.filteredUsers;

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Text(
                      viewModel.searchQuery != null
                          ? t.adminUsers_noUsersFoundQuery(
                              viewModel.searchQuery!)
                          : t.adminUsers_noUsersFound,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return ListTile(
                      leading: const Icon(Icons.account_circle_outlined),
                      title: Text(user.displayName ?? t.adminUsers_noName),
                      subtitle: Text(user.email ?? t.adminUsers_noEmail),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => user.disabled
                                ? _enableUser(context, user, viewModel)
                                : _disableUser(context, user, viewModel),
                            icon: Icon(
                              user.disabled
                                  ? Icons.check_circle_outline
                                  : Icons.block,
                              color: user.disabled
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                            ),
                            tooltip: user.disabled
                                ? t.adminUsers_enable
                                : t.adminUsers_disable,
                          ),
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined),
                            tooltip: t.adminUsers_tooltipDetails,
                            onPressed: () => _showUserDetails(context, user),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_forever,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      t.common_delete,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'delete') {
                                _showDeleteConfirmation(
                                    context, user, viewModel);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context, AdminUser user) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.adminUsers_userDetails),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t.adminUsers_labelUid}: ${user.uid}'),
            Text(
                '${t.adminUsers_labelEmail}: ${user.email ?? t.adminUsers_none}'),
            Text(
                '${t.adminUsers_labelName}: ${user.displayName ?? t.adminUsers_none}'),
            Text(
                '${t.adminUsers_labelStatus}: ${user.disabled ? t.adminUsers_statusDisabled : t.adminUsers_statusActive}'),
            Text('${t.adminUsers_labelCreated}: ${user.createdAt}'),
            Text('${t.adminUsers_labelUpdated}: ${user.updatedAt}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.common_close),
          ),
        ],
      ),
    );
  }

  Future<void> _disableUser(BuildContext context, AdminUser user,
      AdminUsersViewModel viewModel) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(t.adminUsers_disableUserTitle),
            content: Text(
              t.adminUsers_disableUserConfirm(
                  user.displayName ?? t.adminUsers_thisUser),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(t.common_cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(t.adminUsers_disable),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final success = await viewModel.disableUser(user);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? t.adminUsers_userDisabledSuccess : viewModel.error!,
        ),
        backgroundColor: success ? null : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _enableUser(BuildContext context, AdminUser user,
      AdminUsersViewModel viewModel) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(t.adminUsers_enableUserTitle),
            content: Text(
              t.adminUsers_enableUserConfirm(
                  user.displayName ?? t.adminUsers_thisUser),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(t.common_cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(t.adminUsers_enable),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final success = await viewModel.enableUser(user);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? t.adminUsers_userEnabledSuccess : viewModel.error!,
        ),
        backgroundColor: success ? null : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, AdminUser user,
      AdminUsersViewModel viewModel) async {
    final t = AppLocalizations.of(context);
    final deleteKeyword = t.common_delete.toUpperCase();
    String confirmationText = '';
    bool isLoading = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(t.adminUsers_confirmPermanentDeletion),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.adminUsers_deleteWarning,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                t.adminUsers_typeDeleteToConfirm
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
                hintText:
                    t.adminUsers_typeDeleteHere.replaceAll('DELETE', deleteKeyword),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isLoading ? null : () => Navigator.of(context).pop(false),
              child: Text(t.common_cancel),
            ),
            FilledButton(
              onPressed: isLoading ||
                      confirmationText.trim().toUpperCase() != deleteKeyword
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      final success = await viewModel.deleteUser(user);
                      if (!context.mounted) return;
                      Navigator.of(context).pop(success);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: isLoading
                  ? SizedBox(
                      width: AppIconSize.sm,
                      height: AppIconSize.sm,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onError),
                      ),
                    )
                  : Text(t.common_confirmDelete),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) return;

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.adminUsers_userDeletedSuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (viewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.adminUsers_failedDeleteUser(viewModel.error!)),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
