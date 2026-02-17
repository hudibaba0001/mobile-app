import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
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
import '../services/reminder_service.dart';
import '../services/crash_reporting_service.dart';
import '../widgets/add_red_day_dialog.dart';
import '../models/user_red_day.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _enableCrashlyticsTestActions = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS_TEST_ACTIONS',
    defaultValue: false,
  );

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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.neutral50,
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

  Future<void> _openPersonalRedDayDateDialog(
    BuildContext context, {
    DateTime? initialDate,
  }) async {
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
    final targetInitialDate = initialDate ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: targetInitialDate,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 2),
    );

    if (picked == null) return;
    if (!context.mounted) return;

    await holidayService.loadPersonalRedDays(picked.year);
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

  Future<void> _openPersonalRedDayManagerDialog(BuildContext context) async {
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

    final currentYear = DateTime.now().year;
    await holidayService.loadPersonalRedDays(currentYear);
    if (!context.mounted) return;

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(localeTag);
    List<UserRedDay> redDays = List<UserRedDay>.from(
      holidayService.getPersonalRedDays(currentYear),
    )..sort((a, b) => a.date.compareTo(b.date));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool isBusy = false;

        Future<void> refreshRedDays(StateSetter setDialogState) async {
          await holidayService.loadPersonalRedDays(currentYear);
          redDays = List<UserRedDay>.from(
            holidayService.getPersonalRedDays(currentYear),
          )..sort((a, b) => a.date.compareTo(b.date));
          setDialogState(() {});
        }

        Future<void> handleEdit(
          UserRedDay redDay,
          StateSetter setDialogState,
        ) async {
          final result = await showDialog<bool>(
            context: dialogContext,
            builder: (editContext) => AddRedDayDialog(
              date: redDay.date,
              holidayService: holidayService,
              userId: userId,
              existingRedDay: redDay,
            ),
          );

          if (result == true && dialogContext.mounted) {
            setDialogState(() => isBusy = true);
            await refreshRedDays(setDialogState);
            if (dialogContext.mounted) {
              setDialogState(() => isBusy = false);
            }
          }
        }

        Future<void> handleDelete(
          UserRedDay redDay,
          StateSetter setDialogState,
        ) async {
          final confirmed = await showDialog<bool>(
            context: dialogContext,
            builder: (confirmContext) => AlertDialog(
              title: Text(t.redDay_removeTitle),
              content: Text(t.redDay_removeMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(confirmContext).pop(false),
                  child: Text(t.common_cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(confirmContext).pop(true),
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.error),
                  child: Text(t.redDay_remove),
                ),
              ],
            ),
          );

          if (confirmed != true || !dialogContext.mounted) return;

          setDialogState(() => isBusy = true);
          try {
            await holidayService.deletePersonalRedDay(redDay.date);
            await refreshRedDays(setDialogState);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.redDay_removed),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.redDay_errorRemoving(e.toString())),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          } finally {
            if (dialogContext.mounted) {
              setDialogState(() => isBusy = false);
            }
          }
        }

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final theme = Theme.of(dialogContext);
            final maxListHeight =
                MediaQuery.sizeOf(dialogContext).height * 0.42;
            final calculatedListHeight =
                (redDays.length * 116.0).clamp(120.0, maxListHeight);
            final listHeight =
                redDays.isEmpty ? 120.0 : calculatedListHeight.toDouble();

            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(child: Text(t.redDay_editPersonal)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.redDay_currentPersonalDays,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: listHeight,
                      child: redDays.isEmpty
                          ? Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              alignment: Alignment.center,
                              child: Text(
                                t.redDay_noPersonalDaysYet,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              itemCount: redDays.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (itemContext, index) {
                                final redDay = redDays[index];
                                final kindLabel = redDay.kind == RedDayKind.full
                                    ? t.redDay_fullDay
                                    : (redDay.half == HalfDay.am
                                        ? t.redDay_morningAM
                                        : t.redDay_afternoonPM);
                                final reason = redDay.reason?.trim();

                                return Container(
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.35),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.event_busy_outlined,
                                            size: AppIconSize.sm,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Text(
                                              dateFormat.format(redDay.date),
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: AppSpacing.xs,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                AppRadius.sm,
                                              ),
                                            ),
                                            child: Text(
                                              kindLabel,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (reason != null &&
                                          reason.isNotEmpty) ...[
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          reason,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ],
                                      const SizedBox(height: AppSpacing.sm),
                                      Wrap(
                                        spacing: AppSpacing.sm,
                                        runSpacing: AppSpacing.xs,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: isBusy
                                                ? null
                                                : () => handleEdit(
                                                      redDay,
                                                      setDialogState,
                                                    ),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 16,
                                            ),
                                            label: Text(t.common_edit),
                                          ),
                                          TextButton.icon(
                                            onPressed: isBusy
                                                ? null
                                                : () => handleDelete(
                                                      redDay,
                                                      setDialogState,
                                                    ),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 16,
                                            ),
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppColors.error,
                                            ),
                                            label: Text(t.common_delete),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isBusy ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(t.common_close),
                ),
                FilledButton.icon(
                  onPressed: isBusy
                      ? null
                      : () async {
                          setDialogState(() => isBusy = true);
                          await _openPersonalRedDayDateDialog(dialogContext);
                          if (dialogContext.mounted) {
                            await refreshRedDays(setDialogState);
                            setDialogState(() => isBusy = false);
                          }
                        },
                  icon: const Icon(Icons.add),
                  label: Text(t.common_add),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatReminderTime(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    final time = TimeOfDay(
      hour: settingsProvider.dailyReminderHour,
      minute: settingsProvider.dailyReminderMinute,
    );
    final alwaysUse24Hour =
        MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
    return MaterialLocalizations.of(context).formatTimeOfDay(
      time,
      alwaysUse24HourFormat: alwaysUse24Hour,
    );
  }

  Future<void> _syncReminderSchedule(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final settingsProvider = context.read<SettingsProvider>();
    final reminderService = context.read<ReminderService>();

    if (settingsProvider.isDailyReminderEnabled) {
      final granted = await reminderService.requestPermissions();
      if (!granted) {
        await settingsProvider.setDailyReminderEnabled(false);
        await reminderService.cancelDailyReminder();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.settings_dailyReminderPermissionDenied)),
          );
        }
        return;
      }
    }

    await reminderService.applySettings(settingsProvider);
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settingsProvider.dailyReminderHour,
        minute: settingsProvider.dailyReminderMinute,
      ),
    );

    if (picked == null) return;
    await settingsProvider.setDailyReminderTime(
      hour: picked.hour,
      minute: picked.minute,
    );

    if (context.mounted) {
      await _syncReminderSchedule(context);
    }
  }

  Future<void> _editReminderText(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    final t = AppLocalizations.of(context);
    final controller =
        TextEditingController(text: settingsProvider.dailyReminderText);

    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.settings_dailyReminderText),
        content: TextField(
          controller: controller,
          maxLength: 120,
          autofocus: true,
          decoration: InputDecoration(
            hintText: t.settings_dailyReminderTextHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common_cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(t.common_save),
          ),
        ],
      ),
    );

    if (text == null) return;
    await settingsProvider.setDailyReminderText(text);

    if (context.mounted) {
      await _syncReminderSchedule(context);
    }
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
    final showCrashlyticsTestActions =
        !kReleaseMode || _enableCrashlyticsTestActions;

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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
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
                    const SizedBox(width: AppSpacing.lg),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.settings_theme,
                            style: theme.textTheme.bodyLarge),
                        const SizedBox(height: AppSpacing.xs),
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
                const SizedBox(height: AppSpacing.md),
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
            onTap: () => _openPersonalRedDayManagerDialog(context),
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
            title: Text(t.settings_timeBalanceTracking),
            subtitle: Text(
              t.settings_timeBalanceTrackingDesc,
            ),
            trailing: Switch(
              value: settingsProvider.isTimeBalanceEnabled,
              onChanged: settingsProvider.setTimeBalanceEnabled,
            ),
          ),

          // Daily reminder (user-defined time and custom text)
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(t.settings_dailyReminder),
            subtitle: Text(t.settings_dailyReminderDesc),
            trailing: Switch(
              value: settingsProvider.isDailyReminderEnabled,
              onChanged: (value) async {
                await settingsProvider.setDailyReminderEnabled(value);
                if (context.mounted) {
                  await _syncReminderSchedule(context);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: Text(t.settings_dailyReminderTime),
            subtitle: Text(_formatReminderTime(context, settingsProvider)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickReminderTime(context, settingsProvider),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(t.settings_dailyReminderText),
            subtitle: Text(
              settingsProvider.dailyReminderText.trim().isEmpty
                  ? t.settings_dailyReminderDefaultText
                  : settingsProvider.dailyReminderText.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editReminderText(context, settingsProvider),
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

          if (showCrashlyticsTestActions) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Crashlytics test (non-fatal)'),
              subtitle: const Text('Send a non-fatal test event to Firebase'),
              onTap: () async {
                if (!CrashReportingService.isEnabled) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Crashlytics is disabled for this build.',
                        ),
                      ),
                    );
                  }
                  return;
                }

                await CrashReportingService.sendTestNonFatal();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Crashlytics non-fatal event sent.'),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_outlined),
              title: const Text('Crashlytics test (fatal crash)'),
              subtitle: const Text('Force app crash to verify Crashlytics'),
              onTap: () {
                if (!CrashReportingService.isEnabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Crashlytics is disabled for this build.',
                      ),
                    ),
                  );
                  return;
                }
                CrashReportingService.crashForTest();
              },
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),
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
