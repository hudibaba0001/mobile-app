// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design/app_theme.dart';
import '../design/components/components.dart';
import '../models/location.dart';
import '../providers/location_provider.dart';
import '../widgets/standard_app_bar.dart';
import '../widgets/keyboard_aware_form_container.dart';
import '../l10n/generated/app_localizations.dart';

class ManageLocationsScreen extends StatefulWidget {
  const ManageLocationsScreen({super.key});

  @override
  State<ManageLocationsScreen> createState() => _ManageLocationsScreenState();
}

class _ManageLocationsScreenState extends State<ManageLocationsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Load locations when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().refreshLocations();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showAddLocationDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: KeyboardAwareFormContainer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.xl),
                      topRight: Radius.circular(AppRadius.xl),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          Icons.add_location_alt_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.location_addNewLocation,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              t.location_saveFrequentPlace,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.location_details,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextFormField(
                          controller: _nameController,
                            labelText: t.location_name,
                            hintText: t.location_nameHint,
                            prefixIcon: Icon(
                              Icons.place_outlined,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return t.location_enterName;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextFormField(
                          controller: _addressController,
                            labelText: t.location_fullAddress,
                            hintText: t.location_fullAddress,
                            prefixIcon: Icon(
                              Icons.location_on_outlined,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return t.location_enterAddress;
                            }
                            return null;
                          },
                          maxLines: 2,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                ),
                                child: Text(
                                  t.common_cancel,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    final location = Location(
                                      id: DateTime.now().toIso8601String(),
                                      name: _nameController.text.trim(),
                                      address: _addressController.text.trim(),
                                      createdAt: DateTime.now(),
                                    );

                                    await context
                                        .read<LocationProvider>()
                                        .addLocation(location);

                                    if (mounted) {
                                      Navigator.of(context).pop();
                                      _nameController.clear();
                                      _addressController.clear();

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline,
                                                color: colorScheme.onPrimary,
                                              ),
                                              const SizedBox(width: AppSpacing.md),
                                              Text(t.location_addedSuccessfully),
                                            ],
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: colorScheme.primary,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                ),
                                child: Text(AppLocalizations.of(context)
                                    .location_addLocation),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: StandardAppBar(
        title: t.location_manageLocations,
      ),
      body: Consumer<LocationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Text(
                provider.error!,
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              children: [
                Padding(
                  padding: AppSpacing.pagePadding,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 12.0;
                      final columns = constraints.maxWidth < 420 ? 2 : 3;
                      final cardWidth =
                          (constraints.maxWidth - (spacing * (columns - 1))) /
                              columns;
                      final cards = [
                        _buildKPICard(
                          context,
                          t.location_kpiTotal,
                          provider.locations.length.toString(),
                          Icons.location_on_rounded,
                          colorScheme.primary,
                        ),
                        _buildKPICard(
                          context,
                          t.location_kpiFavorites,
                          provider.locations
                              .where((l) => l.isFavorite)
                              .length
                              .toString(),
                          Icons.star_rounded,
                          colorScheme.secondary,
                        ),
                        _buildKPICard(
                          context,
                          t.location_kpiTotalUses,
                          '0', // TODO: Implement usage tracking
                          Icons.history_rounded,
                          colorScheme.tertiary,
                        ),
                      ];

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: cards
                            .map((card) =>
                                SizedBox(width: cardWidth, child: card))
                            .toList(),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: AppTextField(
                    hintText: t.location_searchLocations,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: colorScheme.surface,
                    onChanged: (value) {
                      // TODO: Implement search functionality
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: provider.locations.isEmpty
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    size: 64,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                Text(
                                  t.location_noSavedYet,
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  t.location_addFirstToGetStarted,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                FilledButton.icon(
                                  onPressed: _showAddLocationDialog,
                                  icon: const Icon(Icons.add),
                                  label: Text(AppLocalizations.of(context)
                                      .location_addFirstLocation),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xl,
                                      vertical: AppSpacing.lg,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: provider.locations.length,
                          itemBuilder: (context, index) {
                            final location = provider.locations[index];
                            return _buildLocationListItem(location, theme);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLocationDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildKPICard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationListItem(Location location, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final t = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: location.isFavorite
                ? colorScheme.primary.withValues(alpha: 0.1)
                : colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            location.isFavorite
                ? Icons.star_rounded
                : Icons.location_on_rounded,
            color: location.isFavorite
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          location.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          location.address,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                location.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: location.isFavorite
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                final updatedLocation = location.copyWith(
                  isFavorite: !location.isFavorite,
                );
                context
                    .read<LocationProvider>()
                    .updateLocation(updatedLocation);
              },
              tooltip: location.isFavorite
                  ? t.location_removeFromFavorites
                  : t.location_addToFavorites,
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: colorScheme.onSurfaceVariant,
              ),
              onSelected: (value) async {
                if (value == 'delete') {
                  final t = AppLocalizations.of(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(t.location_deleteLocation),
                      content: Text(t.location_deleteConfirm(location.name)),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: Text(t.common_cancel),
                        ),
                        FilledButton.tonal(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.errorContainer,
                            foregroundColor: colorScheme.onErrorContainer,
                          ),
                          child: Text(t.common_delete),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    await context
                        .read<LocationProvider>()
                        .deleteLocation(location);
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        t.common_delete,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

