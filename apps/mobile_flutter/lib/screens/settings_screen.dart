import 'package:flutter/material.dart';
import '../design/design.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/locale_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/holiday_service.dart';
import '../config/app_router.dart';
import '../widgets/standard_app_bar.dart';
import '../services/supabase_auth_service.dart';
import '../widgets/add_red_day_dialog.dart';

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

  void _showHolidayInfoDialog(BuildContext context) {
    final t = AppLocalizations.of(context);
    final holidayService = context.read<HolidayService>();
    final holidays =
        holidayService.getHolidaysWithNamesForYear(DateTime.now().year);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.event_available,
                color: Theme.of(dialogContext).colorScheme.primary),
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
                        style: Theme.of(dialogContext)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  Theme.of(dialogContext).colorScheme.primary,
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

  Future<void> _openPersonalRedDayDialog(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final authService = context.read<SupabaseAuthService>();
    final holidayService = context.read<HolidayService>();
    final userId = authService.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.error_signInRequired)),
      );
      return;
    }

    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 2),
    );

    if (picked == null) return;
    if (!context.mounted) return;

    final existing = holidayService.getPersonalRedDay(picked);
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AddRedDayDialog(
        date: picked,
        holidayService: holidayService,
        userId: userId,
        existingRedDay: existing,
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
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
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
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.settings_theme,
                            style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 4),
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
            subtitle:
                Text(LocaleProvider.getDisplayName(localeProvider.locale)),
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
                  child: Text(
                      AppLocalizations.of(context).settings_languageEnglish),
                ),
                DropdownMenuItem<Locale>(
                  value: const Locale('sv'),
                  child: Text(
                      AppLocalizations.of(context).settings_languageSwedish),
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

          // Personal red days
          ListTile(
            leading: const Icon(Icons.event_note_outlined),
            title: Text(t.redDay_addPersonal),
            subtitle: Text(t.redDay_personalNotice),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openPersonalRedDayDialog(context),
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

          // Travel Logging Setting
          ListTile(
            leading: const Icon(Icons.directions_car_outlined),
            title: Text(t.settings_travelLogging),
            subtitle: Text(t.settings_travelLoggingDesc),
            trailing: Switch(
              value: settingsProvider.isTravelLoggingEnabled,
              onChanged: settingsProvider.setTravelLoggingEnabled,
            ),
          ),

          // Time Balance Tracking Setting
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Time balance tracking'),
            subtitle: const Text(
              'Turn off if you only want to log hours without comparing against a target.',
            ),
            trailing: Switch(
              value: settingsProvider.isTimeBalanceEnabled,
              onChanged: settingsProvider.setTimeBalanceEnabled,
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

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ThemeOption {
  final ThemeMode mode;
  final IconData icon;

  const _ThemeOption(this.mode, this.icon);
}
