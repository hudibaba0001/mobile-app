// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_user.dart';
import '../services/admin_api_service.dart';
import '../viewmodels/admin_users_view_model.dart';

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
  State<_AdminUsersScreenContent> createState() => _AdminUsersScreenContentState();
}

class _AdminUsersScreenContentState extends State<_AdminUsersScreenContent> {
  @override
  void initState() {
    super.initState();
    // Fetch users when the screen is mounted
    Future.microtask(() => context.read<AdminUsersViewModel>().fetchUsers());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewModel = context.watch<AdminUsersViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search Field
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: viewModel.setSearchQuery,
                  ),
                ),
                const SizedBox(width: 16),
                // Filter Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: viewModel.filterRole,
                    decoration: InputDecoration(
                      labelText: 'Filter by Role',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'User', child: Text('User')),
                    ],
                    onChanged: (value) => viewModel.setFilterRole(value ?? 'All'),
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
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load users',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          viewModel.error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: viewModel.fetchUsers,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
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
                          ? 'No users found matching "${viewModel.searchQuery}"'
                          : 'No users found',
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
                      title: Text(user.displayName ?? 'No name'),
                      subtitle: Text(user.email ?? 'No email'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton(
                            onPressed: () => user.disabled
                                ? _enableUser(context, user, viewModel)
                                : _disableUser(context, user, viewModel),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: user.disabled
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                            ),
                            child: Text(user.disabled ? 'Enable' : 'Disable'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('Details'),
                            onPressed: () => _showUserDetails(context, user),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_forever,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'delete') {
                                _showDeleteConfirmation(context, user, viewModel);
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UID: ${user.uid}'),
            Text('Email: ${user.email ?? 'None'}'),
            Text('Name: ${user.displayName ?? 'None'}'),
            Text('Status: ${user.disabled ? 'Disabled' : 'Active'}'),
            Text('Created: ${user.createdAt}'),
            Text('Updated: ${user.updatedAt}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _disableUser(BuildContext context, AdminUser user, AdminUsersViewModel viewModel) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Disable User'),
            content: Text(
              'Are you sure you want to disable ${user.displayName ?? 'this user'}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Disable'),
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
          success ? 'User disabled successfully' : viewModel.error!,
        ),
        backgroundColor: success ? null : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _enableUser(BuildContext context, AdminUser user, AdminUsersViewModel viewModel) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enable User'),
            content: Text(
              'Are you sure you want to enable ${user.displayName ?? 'this user'}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Enable'),
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
          success ? 'User enabled successfully' : viewModel.error!,
        ),
        backgroundColor: success ? null : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, AdminUser user, AdminUsersViewModel viewModel) async {
    String confirmationText = '';
    bool isLoading = false;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Confirm Permanent Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Warning: This action cannot be undone. All user data will be permanently deleted.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              const Text(
                'Type DELETE to confirm:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (value) {
                  setState(() => confirmationText = value);
                },
                decoration: const InputDecoration(
                  hintText: 'Type DELETE here',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isLoading || confirmationText != 'DELETE'
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
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Confirm Delete'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) return;

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User deleted successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (viewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete user: ${viewModel.error}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
