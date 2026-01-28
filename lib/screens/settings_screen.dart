import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../design/design.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/locale_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/holiday_service.dart';
import '../config/app_router.dart';
import '../config/external_links.dart';
import '../widgets/standard_app_bar.dart';
import '../providers/entry_provider.dart';
import '../providers/travel_provider.dart';
import '../services/supabase_auth_service.dart';
import '../models/entry.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _buildThemeModeSelector(
    BuildContext context,
    ThemeProvider themeProvider,
    AppLocalizations t,
  ) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final useDropdown = screenWidth < 360 || textScale > 1.1;

    final options = const [
      _ThemeOption(ThemeMode.light, Icons.light_mode),
      _ThemeOption(ThemeMode.system, Icons.brightness_auto),
      _ThemeOption(ThemeMode.dark, Icons.dark_mode),
    ];

    if (useDropdown) {
      final labels = [
        t.settings_themeLight,
        t.settings_themeSystem,
        t.settings_themeDark,
      ];
      return DropdownButtonHideUnderline(
        child: DropdownButton<ThemeMode>(
          value: themeProvider.themeMode,
          isDense: true,
          alignment: AlignmentDirectional.centerEnd,
          borderRadius: AppRadius.buttonRadius,
          style: theme.textTheme.labelLarge,
          items: [
            for (int i = 0; i < options.length; i++)
              DropdownMenuItem<ThemeMode>(
                value: options[i].mode,
                child: Row(
                  children: [
                    Icon(options[i].icon, size: AppIconSize.sm),
                    const SizedBox(width: AppSpacing.sm),
                    Text(labels[i]),
                  ],
                ),
              ),
          ],
          selectedItemBuilder: (context) => [
            Text(labels[0], style: theme.textTheme.labelLarge),
            Text(labels[1], style: theme.textTheme.labelLarge),
            Text(labels[2], style: theme.textTheme.labelLarge),
          ],
          onChanged: (value) {
            if (value != null) {
              themeProvider.setThemeMode(value);
            }
          },
        ),
      );
    }

    return SegmentedButton<ThemeMode>(
      segments: [
        ButtonSegment(
          value: ThemeMode.light,
          icon: const Icon(Icons.light_mode, size: 18),
          label: Text(t.settings_themeLight),
        ),
        ButtonSegment(
          value: ThemeMode.system,
          icon: const Icon(Icons.brightness_auto, size: 18),
          label: Text(t.settings_themeSystem),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: const Icon(Icons.dark_mode, size: 18),
          label: Text(t.settings_themeDark),
        ),
      ],
      selected: {themeProvider.themeMode},
      onSelectionChanged: (Set<ThemeMode> selection) {
        themeProvider.setThemeMode(selection.first);
      },
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Future<void> _addSampleData(BuildContext context) async {
    final entryProvider = context.read<EntryProvider>();
    final auth = context.read<SupabaseAuthService>();
    final uid = auth.currentUser?.id;
    if (uid == null) {
      if (context.mounted) {
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.dev_signInRequired)),
        );
      }
      return;
    }
    final now = DateTime.now();

    // Sample locations
    const locations = [
      ('Home', '123 Home Street'),
      ('Office', '456 Business Ave'),
      ('Client Site A', '789 Client Road'),
      ('Gym', '321 Fitness Lane'),
      ('Coffee Shop', '654 Cafe Street'),
    ];

    // Sample work entries from the last week (atomic Entry per shift)
    final workEntries = [
      (
        id: 'sample_work_1',
        minutes: 480,
        date: now.subtract(const Duration(days: 1)),
        notes: 'Regular work day',
      ),
      (
        id: 'sample_work_2',
        minutes: 540,
        date: now.subtract(const Duration(days: 3)),
        notes: 'Extended day - project deadline',
      ),
      (
        id: 'sample_work_3',
        minutes: 420,
        date: now.subtract(const Duration(days: 5)),
        notes: 'Short day - doctor appointment',
      ),
    ];

    // Sample travel entries from the last week (atomic Entry per leg)
    final travelEntries = [
      (
        id: 'sample_travel_1',
        from: locations[0].$1, // Home
        to: locations[1].$1, // Office
        minutes: 45,
        date: now.subtract(const Duration(days: 2)),
        notes: 'Morning commute',
      ),
      (
        id: 'sample_travel_2',
        from: locations[1].$1, // Office
        to: locations[2].$1, // Client Site
        minutes: 30,
        date: now.subtract(const Duration(days: 4)),
        notes: 'Client meeting',
      ),
      (
        id: 'sample_travel_3',
        from: locations[2].$1, // Client Site
        to: locations[0].$1, // Home
        minutes: 60,
        date: now.subtract(const Duration(days: 4)),
        notes: 'Return from client meeting',
      ),
      (
        id: 'sample_travel_4',
        from: locations[0].$1, // Home
        to: locations[3].$1, // Gym
        minutes: 20,
        date: now.subtract(const Duration(days: 6)),
        notes: 'Morning workout',
      ),
    ];

    try {
      // Add work entries
      for (final entry in workEntries) {
        final start = entry.date;
        final end = start.add(Duration(minutes: entry.minutes));
        await entryProvider.addEntry(
          Entry.makeWorkAtomicFromShift(
            userId: uid,
            id: entry.id,
            date: entry.date,
            shift: Shift(
              start: start,
              end: end,
              description: entry.notes,
              location: 'Office',
            ),
            dayNotes: entry.notes,
            createdAt: entry.date,
          ),
        );
      }

      // Add travel entries
      for (final entry in travelEntries) {
        await entryProvider.addEntry(
          Entry.makeTravelAtomicFromLeg(
            userId: uid,
            id: entry.id,
            date: entry.date,
            from: entry.from,
            to: entry.to,
            minutes: entry.minutes,
            source: 'manual',
            dayNotes: entry.notes,
            createdAt: entry.date,
            segmentOrder: 1,
            totalSegments: 1,
          ),
        );
      }

      if (context.mounted) {
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.dev_sampleDataAdded),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.dev_sampleDataFailed(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _clearDemoData(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.settings_clearDemoData),
        content: Text(t.settings_clearDemoDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  Theme.of(dialogContext).colorScheme.tertiary,
              foregroundColor:
                  Theme.of(dialogContext).colorScheme.onTertiary,
            ),
            child: Text(t.settings_clearDemoData),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (confirmed == true) {
      try {
        final entryProvider = context.read<EntryProvider>();
        await entryProvider.clearDemoEntries();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.common_success),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${t.common_error}: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearAllData(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.settings_clearAllData),
        content: Text(t.settings_clearAllDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: Text(t.common_delete),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (confirmed == true) {
      try {
        final entryProvider = context.read<EntryProvider>();
        final travelProvider = context.read<TravelProvider>();
        
        // Clear both providers
        await Future.wait([
          entryProvider.clearAllEntries(),
          travelProvider.clearAllEntries(),
        ]);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.common_success),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${t.common_error}: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _showHolidayInfoDialog(BuildContext context) {
    final t = AppLocalizations.of(context);
    final holidayService = context.read<HolidayService>();
    final holidays = holidayService.getHolidaysWithNamesForYear(DateTime.now().year);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.event_available, color: Theme.of(dialogContext).colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            Flexible(child: Text(t.settings_publicHolidays)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.settings_viewHolidays(DateTime.now().year),
                style: Theme.of(dialogContext).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: holidays.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (itemContext, index) {
                    final holiday = holidays[index];
                    final dateStr = '${holiday.date.day}/${holiday.date.month}';
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(itemContext).colorScheme.error,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          t.redDay_auto,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(holiday.name),
                      trailing: Text(
                        dateStr,
                        style: Theme.of(itemContext).textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: Theme.of(dialogContext)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: AppIconSize.sm,
                      color: Theme.of(dialogContext).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        t.redDay_holidayWorkNotice,
                        style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                          color: Theme.of(dialogContext).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common_close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final holidayService = context.watch<HolidayService>();
    final authService = context.watch<SupabaseAuthService>();
    final user = authService.currentUser;
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: StandardAppBar(title: t.settings_title),
      body: ListView(
        children: [
            // User Info Section
            if (user != null) ...[
              AppCard(
                margin: AppSpacing.pagePadding,
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_circle,
                      size: AppIconSize.xl,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.userMetadata?['full_name'] ??
                                user.email?.split('@').first ??
                                'User',
                            style: AppTypography.cardTitle(
                              theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            user.email ?? '—',
                            style: AppTypography.body(
                              theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => AppRouter.goToProfile(context),
                      tooltip: t.profile_title,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          
          // Theme Settings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.settings_theme, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 2),
                        Text(
                          themeProvider.themeModeDisplayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildThemeModeSelector(context, themeProvider, t),
              ],
            ),
          ),

          // Language Settings
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(t.settings_language),
            subtitle: Text(LocaleProvider.getDisplayName(localeProvider.locale)),
            trailing: DropdownButton<Locale?>(
              value: localeProvider.locale,
              underline: const SizedBox(),
              items: [
                DropdownMenuItem<Locale?>(
                  value: null,
                  child: Text(t.settings_languageSystem),
                ),
                DropdownMenuItem<Locale>(
                  value: const Locale('en'),
                  child: Text(AppLocalizations.of(context).settings_languageEnglish),
                ),
                DropdownMenuItem<Locale>(
                  value: const Locale('sv'),
                  child: Text(AppLocalizations.of(context).settings_languageSwedish),
                ),
              ],
              onChanged: (Locale? locale) {
                localeProvider.setLocale(locale);
              },
            ),
          ),

          const Divider(),

          // Holiday Settings Section
          AppSectionHeader(title: t.settings_publicHolidays),

          // Auto-mark holidays toggle
          ListTile(
            leading: const Icon(Icons.event_available),
            title: Text(t.settings_autoMarkHolidays),
            subtitle: Text(t.redDay_publicHoliday),
            trailing: Switch(
              value: holidayService.autoMarkHolidays,
              onChanged: (value) => holidayService.setAutoMarkHolidays(value),
            ),
          ),

          // Holiday region info
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(t.settings_region),
            subtitle: Text(t.settings_holidayRegion),
            trailing: const Icon(Icons.info_outline),
            onTap: () => _showHolidayInfoDialog(context),
          ),

          const Divider(),

          // First Launch Setting
          ListTile(
            leading: const Icon(Icons.new_releases),
            title: Text(t.settings_welcomeScreen),
            subtitle: Text(t.settings_welcomeScreenDesc),
            trailing: Switch(
              value: settingsProvider.isFirstLaunch,
              onChanged: settingsProvider.setFirstLaunch,
            ),
          ),

          const Divider(),

          // Manage Locations
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(t.settings_manageLocations),
            subtitle: Text(t.settings_manageLocationsDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AppRouter.goToManageLocations(context),
          ),

          // Contract Settings
          ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: Text(t.settings_contractSettings),
            subtitle: Text(t.settings_contractDescription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AppRouter.goToContractSettings(context),
          ),

          // Absence Management
          ListTile(
            leading: const Icon(Icons.event_busy),
            title: Text(t.settings_absences),
            subtitle: Text(t.settings_absencesDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRouter.absenceManagementPath),
          ),

          // Manage Subscription
          ListTile(
            leading: const Icon(Icons.payment_outlined),
            title: Text(t.settings_manageSubscription),
            subtitle: Text(t.settings_subscriptionDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              try {
                final url = Uri.parse(ExternalLinks.manageSubscriptionUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.common_error),
                      backgroundColor: theme.colorScheme.error,
                    ),
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

          // Developer Options (only in debug mode)
          if (kDebugMode) ...[
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            AppSectionHeader(title: 'Developer Options'),
            Builder(builder: (context) {
              final t = AppLocalizations.of(context);
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.data_array),
                    title: Text(t.dev_addSampleData),
                    subtitle: Text(t.dev_addSampleDataDesc),
                    onTap: () => _addSampleData(context),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.cleaning_services,
                      color: theme.colorScheme.tertiary,
                    ),
                    title: Text(
                      t.settings_clearDemoData,
                      style: TextStyle(color: theme.colorScheme.tertiary),
                    ),
                    subtitle: Text(
                      t.settings_clearDemoDataConfirm,
                      style: TextStyle(color: theme.colorScheme.tertiary),
                    ),
                    onTap: () => _clearDemoData(context),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_sweep,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      t.settings_clearAllData,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    subtitle: Text(
                      t.settings_clearAllDataConfirm,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () => _clearAllData(context),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.sync,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      t.dev_syncToSupabase,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                    subtitle: Text(
                      t.dev_syncToSupabaseDesc,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                    onTap: () => _syncToSupabase(context),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _syncToSupabase(BuildContext context) async {
    final entryProvider = context.read<EntryProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Show loading dialog
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(t.dev_syncing),
          ],
        ),
      ),
    );

    try {
      await entryProvider.syncLocalEntriesToSupabase();
      
      // Close dialog safely after frame completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.canPop()) {
          navigator.pop();
        }
        final t = AppLocalizations.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(t.dev_syncSuccess),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      });
    } catch (e) {
      // Close dialog safely after frame completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.canPop()) {
          navigator.pop();
        }
        final t = AppLocalizations.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(t.dev_syncFailed(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }
  }
}

class _ThemeOption {
  final ThemeMode mode;
  final IconData icon;

  const _ThemeOption(this.mode, this.icon);
}
