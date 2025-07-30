import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../config/app_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.read<AuthService>().currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profile'),
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
          // Error message if any
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

          // Profile Picture
          Center(
            child: Column(
              children: [
                FutureBuilder<String?>(
                  future: context.read<StorageService>().getProfilePictureUrl(
                    user.uid,
                  ),
                  builder: (context, snapshot) {
                    return Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundImage: snapshot.data != null
                              ? NetworkImage(snapshot.data!)
                              : null,
                          child: snapshot.data == null
                              ? Icon(
                                  Icons.person_outline,
                                  size: 48,
                                  color: theme.colorScheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                        if (_isLoading)
                          Positioned.fill(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _handleChangePhoto,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Change Photo'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // User Info Section
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            user.displayName ?? '—',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
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
        ],
      ),
    );
  }

  Future<void> _handleChangePhoto() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Pick image
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Upload image
      final file = File(pickedFile.path);
      await context.read<StorageService>().uploadProfilePicture(user.uid, file);

      // Refresh UI
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to update profile picture: $e';
        });
      }
    }
  }

  Future<void> _showEditNameDialog(BuildContext context, user) async {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: user.displayName);

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter your name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              try {
                await user.updateDisplayName(newName);
                if (mounted) {
                  setState(() {}); // Refresh UI
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name updated successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update name: $e'),
                      backgroundColor: theme.colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
