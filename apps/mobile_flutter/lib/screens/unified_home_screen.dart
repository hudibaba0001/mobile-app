// ignore_for_file: use_build_context_synchronously
// ignore_for_file: avoid_print
// ignore_for_file: unused_element

import 'dart:ui';
import 'package:intl/intl.dart';
import '../design/design.dart';
import '../widgets/unified_entry_form.dart';
import '../widgets/entry_detail_sheet.dart';
import '../widgets/entry_compact_tile.dart';
import '../widgets/flexsaldo_card.dart';
import '../widgets/absence_entry_dialog.dart';
import 'dart:async';
import '../models/entry.dart';
import '../models/absence.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../config/app_router.dart';
import '../models/autocomplete_suggestion.dart';
import '../reporting/time_format.dart';
import '../reporting/time_range.dart';
import '../reporting/tracked_time_calculator.dart';
// EntryProvider is the only write path
import '../providers/entry_provider.dart';
import '../providers/absence_provider.dart';
import '../providers/location_provider.dart';
import '../providers/network_status_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/contract_provider.dart';
import '../services/supabase_auth_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/app_message_banner.dart';
import '../widgets/standard_app_bar.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

/// Unified Home screen with navigation integration.
/// Main entry point combining travel and work time tracking.
/// Features: Navigation tabs, today's total, action cards, stats, recent entries.
class UnifiedHomeScreen extends StatefulWidget {
  const UnifiedHomeScreen({super.key});

  @override
  State<UnifiedHomeScreen> createState() => _UnifiedHomeScreenState();
}

class _UnifiedHomeScreenState extends State<UnifiedHomeScreen> {
  List<_EntryData> _recentEntries = [];
  bool _isLoadingRecent = false;
  Timer? _recentLoadDebounce;
  EntryProvider? _entryProvider;
  AbsenceProvider? _absenceProvider;
  bool _trackingStartInitialized = false;
  bool _trackingStartInitInProgress = false;

  @override
  void dispose() {
    _recentLoadDebounce?.cancel();
    _entryProvider?.removeListener(_onProviderDataChanged);
    _absenceProvider?.removeListener(_onProviderDataChanged);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nextEntryProvider = context.read<EntryProvider>();
    if (!identical(_entryProvider, nextEntryProvider)) {
      _entryProvider?.removeListener(_onProviderDataChanged);
      _entryProvider = nextEntryProvider;
      _entryProvider?.addListener(_onProviderDataChanged);
    }

    final nextAbsenceProvider = context.read<AbsenceProvider>();
    if (!identical(_absenceProvider, nextAbsenceProvider)) {
      _absenceProvider?.removeListener(_onProviderDataChanged);
      _absenceProvider = nextAbsenceProvider;
      _absenceProvider?.addListener(_onProviderDataChanged);
    }
  }

  @override
  void initState() {
    super.initState();
    // Start loading data immediately; provider listeners keep recents in sync.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final entryProvider = context.read<EntryProvider>();
      final absenceProvider = context.read<AbsenceProvider>();

      // Load absences for current year
      await absenceProvider.loadAbsences(year: DateTime.now().year);

      if (!entryProvider.isLoading) {
        // Kick off load/sync without blocking the initial render.
        await entryProvider.loadEntries();
      }

      await _ensureTrackingStartDateInitialized();
      _loadRecentEntries();
    });
  }

  void _onProviderDataChanged() {
    if (!mounted) return;
    _ensureTrackingStartDateInitialized();
    _loadRecentEntries();
  }

  Future<void> _ensureTrackingStartDateInitialized() async {
    if (!mounted || _trackingStartInitialized || _trackingStartInitInProgress) {
      return;
    }

    final contractProvider = context.read<ContractProvider>();
    if (contractProvider.hasCustomTrackingStartDate) {
      _trackingStartInitialized = true;
      return;
    }

    _trackingStartInitInProgress = true;
    try {
      final now = DateTime.now();
      final currentYear = now.year;
      final entryProvider = context.read<EntryProvider>();
      final absenceProvider = context.read<AbsenceProvider>();

      if (!entryProvider.isLoading && entryProvider.entries.isEmpty) {
        await entryProvider.loadEntries();
      }

      final entries = List<Entry>.from(entryProvider.entries);
      final years = <int>{
        currentYear,
        ...entries.map((entry) => entry.date.year)
      }..removeWhere((year) => year < 2000 || year > (currentYear + 1));

      for (final year in (years.toList()..sort())) {
        await absenceProvider.loadAbsences(year: year);
      }

      final absences = <AbsenceEntry>[
        for (final year in years) ...absenceProvider.absencesForYear(year),
      ];

      await contractProvider.ensureTrackingStartDateInitialized(
        entryDates: entries.map((entry) => entry.date),
        absenceDates: absences.map((absence) => absence.date),
        now: now,
      );

      _trackingStartInitialized = contractProvider.hasCustomTrackingStartDate;
    } finally {
      _trackingStartInitInProgress = false;
    }
  }

  void _loadRecentEntries() {
    // Debounce frequent triggers to avoid UI stalls
    _recentLoadDebounce?.cancel();
    _recentLoadDebounce = Timer(const Duration(milliseconds: 150), () {
      if (_isLoadingRecent) return;
      _isLoadingRecent = true;
      _loadRecentEntriesInternal();
    });
  }

  void _loadRecentEntriesInternal() {
    debugPrint('=== LOADING RECENT ENTRIES ===');
    try {
      final t = AppLocalizations.of(context);
      final entryProvider = context.read<EntryProvider>();
      final absenceProvider = context.read<AbsenceProvider>();
      final settingsProvider = context.read<SettingsProvider>();
      final authService = context.read<SupabaseAuthService>();
      final userId = authService.currentUser?.id;
      final travelEnabled = settingsProvider.isTravelLoggingEnabled;

      if (userId == null) {
        if (mounted) {
          setState(() {
            _recentEntries = [];
          });
        }
        return;
      }

      debugPrint('Loading entries for user: $userId');

      // Get recent entries from EntryProvider (already loaded on startup)
      final allEntryProviderEntries = entryProvider.entries;

      // Sort by date desc then updatedAt/createdAt desc
      final sortedEntries = List<Entry>.from(allEntryProviderEntries)
        ..sort((a, b) {
          final dateCompare = b.date.compareTo(a.date);
          if (dateCompare != 0) return dateCompare;
          // If same date, sort by updatedAt or createdAt
          final aTime = a.updatedAt ?? a.createdAt;
          final bTime = b.updatedAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });

      debugPrint('Found ${sortedEntries.length} entries from EntryProvider');

      // Combine and sort by date
      final allEntries = <_EntryData>[];

      if (travelEnabled) {
        // Convert travel entries
        final travelEntries =
            sortedEntries.where((e) => e.type == EntryType.travel).take(5);
        for (final entry in travelEntries) {
          final fromText = entry.from ?? '';
          final toText = entry.to ?? '';
          final minutes = entry.travelMinutes ?? 0;
          allEntries.add(_EntryData(
            id: entry.id,
            type: 'travel',
            title: t.home_travelRoute(fromText, toText),
            subtitle:
                '${DateFormat.yMMMd().format(entry.date)} â€¢ ${entry.notes?.isNotEmpty == true ? entry.notes : t.home_noRemarks}',
            duration: '${minutes ~/ 60}h ${minutes % 60}m',
            icon: Icons.directions_car,
            date: entry.date,
          ));
        }
      }

      // Convert work entries
      final workEntries =
          sortedEntries.where((e) => e.type == EntryType.work).take(5);
      for (final entry in workEntries) {
        // Show shift time range + location (and worked minutes)
        final shift = entry.atomicShift ?? entry.shifts?.first;
        final workedMinutes = entry.totalWorkDuration?.inMinutes ?? 0;
        String title = t.home_workSession;
        String subtitle = DateFormat.yMMMd().format(entry.date);

        if (shift != null) {
          final startTime = TimeOfDay.fromDateTime(shift.start);
          final endTime = TimeOfDay.fromDateTime(shift.end);
          title =
              '${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)}';
          if (shift.location != null && shift.location!.isNotEmpty) {
            subtitle += ' â€¢ ${shift.location}';
          }
        }

        if (entry.notes?.isNotEmpty == true) {
          subtitle += ' â€¢ ${entry.notes}';
        } else {
          subtitle += ' â€¢ ${t.home_noRemarks}';
        }

        allEntries.add(_EntryData(
          id: entry.id,
          type: 'work',
          title: title,
          subtitle: subtitle,
          duration: '${workedMinutes ~/ 60}h ${workedMinutes % 60}m',
          icon: Icons.work,
          date: entry.date,
        ));
      }

      // Convert absence entries (load current year)
      final currentYear = DateTime.now().year;
      final absences = absenceProvider.absencesForYear(currentYear);
      debugPrint(
          'Found ${absences.length} absence entries for year $currentYear');

      for (final absence in absences.take(5)) {
        final typeLabel = _getAbsenceTypeLabel(absence.type);
        final durationText = absence.minutes == 0
            ? t.absence_fullDay
            : '${absence.minutes ~/ 60}h ${absence.minutes % 60}m';

        allEntries.add(_EntryData(
          id: absence.id ?? 'absence_${absence.date.millisecondsSinceEpoch}',
          type: 'absence',
          title: typeLabel,
          subtitle: DateFormat.yMMMd().format(absence.date),
          duration: durationText,
          icon: _getAbsenceIcon(absence.type),
          date: absence.date,
        ));
      }

      // Sort by real date (most recent first)
      allEntries.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _recentEntries = allEntries.take(10).toList();
        });
      }
    } catch (e) {
      // If there's an error, keep the mock data
      debugPrint('Error loading recent entries: $e');
    } finally {
      _isLoadingRecent = false;
    }
  }

  String _getAbsenceTypeLabel(AbsenceType type) {
    final t = AppLocalizations.of(context);
    switch (type) {
      case AbsenceType.vacationPaid:
        return t.home_paidLeave;
      case AbsenceType.sickPaid:
        return t.home_sickLeave;
      case AbsenceType.vabPaid:
        return t.home_vab;
      case AbsenceType.unpaid:
        return t.home_unpaidLeave;
    }
  }

  IconData _getAbsenceIcon(AbsenceType type) {
    switch (type) {
      case AbsenceType.vacationPaid:
        return Icons.beach_access;
      case AbsenceType.sickPaid:
        return Icons.local_hospital;
      case AbsenceType.vabPaid:
        return Icons.child_care;
      case AbsenceType.unpaid:
        return Icons.event_busy;
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = AppLocalizations.of(context);
    final travelEnabled =
        context.watch<SettingsProvider>().isTravelLoggingEnabled;
    final timeBalanceEnabled =
        context.watch<SettingsProvider>().isTimeBalanceEnabled;

    return Scaffold(
      key: const Key('screen_home'),
      backgroundColor: colorScheme.surface,
      appBar: StandardAppBar(
        showBackButton: false,
        titleWidget: Builder(
          builder: (context) {
            final user = context.read<SupabaseAuthService>().currentUser;
            final userName = user?.userMetadata?['full_name'] ??
                user?.email?.split('@').first ??
                t.common_user;
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.timer_rounded,
                    color: colorScheme.primary,
                    size: AppIconSize.md,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        t.home_subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: colorScheme.onSurfaceVariant,
                size: AppIconSize.sm,
              ),
            ),
            onPressed: () => AppRouter.goToProfile(context),
            tooltip: t.common_profile,
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: Column(
        children: [
          const AppMessageBanner(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Flexsaldo / Simple summary
                      if (timeBalanceEnabled) ...[
                        FlexsaldoCard()
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.08, end: 0),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Today's Total Card
                      Consumer<EntryProvider>(
                        builder: (context, entryProvider, _) =>
                            _buildTotalCard(
                              theme,
                              entryProvider,
                              t,
                              travelEnabled,
                            ).animate().fadeIn(delay: 50.ms).slideY(
                                  begin: 0.08,
                                  end: 0,
                                  curve: Curves.easeOut,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Stats Section
                      Consumer<EntryProvider>(
                        builder: (context, entryProvider, _) =>
                            _buildStatsSection(
                              theme,
                              entryProvider,
                              t,
                              travelEnabled,
                            ).animate().fadeIn(delay: 100.ms).slideY(
                                  begin: 0.08,
                                  end: 0,
                                  curve: Curves.easeOut,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ]),
                  ),
                ),

                _buildRecentEntriesHeaderSliver(theme, t),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  sliver: _buildRecentEntriesSliver(theme, t),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxxl + AppSpacing.xxl),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg + AppSpacing.xs),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.35),
              blurRadius: AppSpacing.xxl - AppSpacing.xs,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg + AppSpacing.xs),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.55),
                borderRadius:
                    BorderRadius.circular(AppRadius.lg + AppSpacing.xs),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: FloatingActionButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showQuickEntry();
                },
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppRadius.lg + AppSpacing.xs),
                ),
                child:
                    const Icon(Icons.add, size: AppIconSize.lg - AppSpacing.xs),
              ),
            ),
          ),
        ),
      ),
      // bottomNavigationBar removed; global nav from AppScaffold is used
    );
  }

  Widget _buildTotalCard(
    ThemeData theme,
    EntryProvider entryProvider,
    AppLocalizations t,
    bool travelEnabled,
  ) {
    if (entryProvider.isLoading && entryProvider.entries.isEmpty) {
      return _buildLoadingTotalCard(theme);
    }

    final localeCode = Localizations.localeOf(context).toLanguageTag();
    final todaySummary = TrackedTimeCalculator.computeTrackedSummary(
      entries: entryProvider.entries,
      range: TimeRange.today(),
      travelEnabled: travelEnabled,
    );

    final totalText =
        formatMinutes(todaySummary.totalMinutes, localeCode: localeCode);
    final travelText =
        formatMinutes(todaySummary.travelMinutes, localeCode: localeCode);
    final workText =
        formatMinutes(todaySummary.workMinutes, localeCode: localeCode);

    final card = Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          // Today's total
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.common_today,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  totalText,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Breakdown
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
              borderRadius: AppRadius.buttonRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (travelEnabled) ...[
                  Icon(
                    Icons.directions_car_rounded,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    size: AppIconSize.sm,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    travelText,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Icon(
                  Icons.work_rounded,
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                  size: AppIconSize.sm,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  workText,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return card
        .animate(onPlay: (controller) => controller.repeat(period: 5.seconds))
        .shimmer(duration: 1800.ms, color: Colors.white24);
  }

  Widget _buildStatsSection(
    ThemeData theme,
    EntryProvider entryProvider,
    AppLocalizations t,
    bool travelEnabled,
  ) {
    if (entryProvider.isLoading && entryProvider.entries.isEmpty) {
      return _buildLoadingStatsCard(theme);
    }

    final localeCode = Localizations.localeOf(context).toLanguageTag();
    final weekSummary = TrackedTimeCalculator.computeTrackedSummary(
      entries: entryProvider.entries,
      range: TimeRange.thisWeek(),
      travelEnabled: travelEnabled,
    );

    final totalText =
        formatMinutes(weekSummary.totalMinutes, localeCode: localeCode);
    final travelText =
        formatMinutes(weekSummary.travelMinutes, localeCode: localeCode);
    final workText =
        formatMinutes(weekSummary.workMinutes, localeCode: localeCode);

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.common_thisWeek,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  totalText,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
              borderRadius: AppRadius.buttonRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (travelEnabled) ...[
                  Icon(
                    Icons.directions_car_rounded,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    size: AppIconSize.sm,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    travelText,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Icon(
                  Icons.work_rounded,
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                  size: AppIconSize.sm,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  workText,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingTotalCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _ShimmerBox(width: 72, height: 12),
                SizedBox(height: AppSpacing.sm),
                _ShimmerBox(width: 120, height: 34),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
              borderRadius: AppRadius.buttonRadius,
            ),
            child: const Row(
              children: [
                _ShimmerBox(width: 18, height: 18),
                SizedBox(width: AppSpacing.xs),
                _ShimmerBox(width: 42, height: 12),
                SizedBox(width: AppSpacing.sm),
                _ShimmerBox(width: 18, height: 18),
                SizedBox(width: AppSpacing.xs),
                _ShimmerBox(width: 42, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStatsCard(ThemeData theme) {
    // Keep the loading layout identical to the Today/This week card shell.
    return _buildLoadingTotalCard(theme);
  }

  Widget _buildCompactStat(
    ThemeData theme, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEntriesHeaderSliver(ThemeData theme, AppLocalizations t) {
    final entryProvider = context.watch<EntryProvider>();
    final networkStatus = context.watch<NetworkStatusProvider>();
    final hasPendingSync = entryProvider.pendingSyncCount > 0;
    final showCachedBadge = networkStatus.isOffline || hasPendingSync;
    const headerHeight = 64.0;

    final header = ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: theme.colorScheme.surface.withValues(alpha: 0.85),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: SizedBox(
            height: headerHeight - (AppSpacing.sm * 2),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                        theme.colorScheme.primary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    t.home_recentEntries,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (showCachedBadge) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer
                          .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color:
                            theme.colorScheme.tertiary.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 13,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          networkStatus.isOffline
                              ? t.network_offlineTooltip
                              : t.network_pendingTooltip(
                                  entryProvider.pendingSyncCount),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: () => AppRouter.goToHistory(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm - 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppRadius.xl - AppSpacing.xs),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          t.home_viewAllArrow,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
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

    final animatedHeader = header
        .animate()
        .fadeIn(delay: 150.ms, duration: 350.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);

    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedHeaderDelegate(
        height: headerHeight,
        child: animatedHeader,
      ),
    );
  }

  Widget _buildRecentEntriesSliver(ThemeData theme, AppLocalizations t) {
    final entryProvider = context.watch<EntryProvider>();
    final showLoadingState = entryProvider.isLoading && _recentEntries.isEmpty;

    if (showLoadingState) {
      return SliverList(
        delegate: SliverChildListDelegate(
          List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: index == 2 ? 0 : AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: AppRadius.buttonRadius,
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
                child: const Row(
                  children: [
                    _ShimmerBox(width: 48, height: 48, circular: true),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ShimmerBox(height: 14),
                          SizedBox(height: AppSpacing.xs),
                          _ShimmerBox(height: 12, width: 180),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    _ShimmerBox(height: 14, width: 44),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_recentEntries.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xxl, horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 48,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                t.home_noEntriesYet,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = _recentEntries.take(5).toList();
    return SliverList(
      delegate: SliverChildListDelegate(
        List.generate(
          items.length,
          (index) => Padding(
            padding:
                EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 10),
            child: _buildRecentEntryTimelineItem(
              theme: theme,
              entry: items[index],
              fullEntries: entryProvider.entries,
              isFirst: index == 0,
              isLast: index == items.length - 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentEntryCard(
    ThemeData theme,
    _EntryData entry,
    List<Entry> fullEntries,
  ) {
    final fullEntry = _findEntryById(fullEntries, entry.id);
    if ((entry.type == 'work' || entry.type == 'travel') && fullEntry != null) {
      return EntryCompactTile(
        entry: fullEntry,
        onTap: () => _openQuickView(entry),
        onLongPress: () => _openQuickView(entry),
        showDate: true,
        showNote: true,
        dense: true,
        heroTag: 'entry-${fullEntry.id}',
      );
    }

    Color lightColor;

    switch (entry.type) {
      case 'travel':
        lightColor = AppColors.primaryLight;
        break;
      case 'work':
        lightColor = AppColors.success;
        break;
      case 'absence':
        lightColor = AppColors.accent;
        break;
      default:
        lightColor = AppColors.secondaryLight;
    }
    return Container(
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: lightColor.withValues(alpha: 0.18),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: () => _openQuickView(entry),
          onLongPress: () {
            HapticFeedback.lightImpact();
            _openQuickView(entry);
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: lightColor.withValues(alpha: 0.12),
                    ),
                    child: Icon(entry.icon, color: lightColor, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _entryTypeLabel(
                                    entry.type, AppLocalizations.of(context)),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _buildDurationPill(
                              theme,
                              text: entry.duration,
                              tint: lightColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          entry.title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs / 2),
                        Text(
                          entry.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentEntryTimelineItem({
    required ThemeData theme,
    required _EntryData entry,
    required List<Entry> fullEntries,
    required bool isFirst,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppSpacing.lg,
          child: Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            children: [
              if (!isFirst) const SizedBox(height: AppSpacing.xs),
              _buildRecentEntryCard(theme, entry, fullEntries),
              if (!isLast) const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationPill(
    ThemeData theme, {
    required String text,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: tint.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: tint,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Entry? _findEntryById(List<Entry> entries, String id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  String _entryTypeLabel(String type, AppLocalizations t) {
    switch (type) {
      case 'travel':
        return t.entry_travel;
      case 'work':
        return t.entry_work;
      default:
        return type.capitalize();
    }
  }

  void _openQuickView(_EntryData summary) {
    final provider = context.read<EntryProvider>();
    Entry? full;
    try {
      full = provider.entries.firstWhere((e) => e.id == summary.id);
    } catch (_) {}
    Future<void> ensureAndOpen() async {
      if (full == null) {
        await provider.loadEntries();
        try {
          full = provider.entries.firstWhere((e) => e.id == summary.id);
        } catch (_) {}
      }
      if (!mounted || full == null) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        builder: (ctx) {
          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: EntryDetailSheet(
              entry: full!,
              onEdit: () => _editEntry(summary),
              onDelete: () => _deleteEntry(context, summary),
              heroTag: 'entry-${full!.id}',
            ),
          );
        },
      );
    }

    ensureAndOpen();
  }

  void _editEntry(_EntryData entry) {
    final entryProvider = context.read<EntryProvider>();
    Entry? existing;
    try {
      existing = entryProvider.entries.firstWhere((e) => e.id == entry.id);
    } catch (_) {
      existing = null;
    }

    if (existing == null) {
      // Attempt a reload then re-find
      entryProvider.loadEntries().then((_) {
        Entry? refreshed;
        try {
          refreshed = entryProvider.entries.firstWhere((e) => e.id == entry.id);
        } catch (_) {
          refreshed = null;
        }
        if (refreshed != null && mounted) {
          _openEditBottomSheet(refreshed);
        }
      });
    } else {
      _openEditBottomSheet(existing);
    }
  }

  void _openEditBottomSheet(Entry existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: UnifiedEntryForm(
            entryType: existing.type,
            existingEntry: existing,
            onSaved: () {
              _loadRecentEntries();
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteEntry(BuildContext context, _EntryData entry) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.entry_deleteEntry),
        content: Text(t.entry_deleteConfirm(entry.type)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(t.common_delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        final entryProvider = context.read<EntryProvider>();

        // Delete the entry by ID
        await entryProvider.deleteEntry(entry.id);

        // Reload recent entries
        _loadRecentEntries();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.entry_deletedSuccess(entry.type.capitalize())),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.error_deleteFailed(e.toString())),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _startTravelEntry() {
    final travelEnabled =
        context.read<SettingsProvider>().isTravelLoggingEnabled;
    if (!travelEnabled) return;
    // Show a simple dialog instead of navigating to complex screen
    _showQuickEntryDialog('travel');
  }

  void _startWorkEntry() {
    // Show a simple dialog instead of navigating to complex screen
    _showQuickEntryDialog('work');
  }

  void _startAbsenceEntry() {
    showAbsenceEntryDialog(
      context,
      year: DateTime.now().year,
    ).then((saved) {
      if (!mounted) return;
      if (saved == true) {
        _loadRecentEntries();
      }
    });
  }

  void _showQuickEntryDialog(String type) {
    if (type == 'travel') {
      _showTravelEntryDialog();
    } else {
      _showWorkEntryDialog();
    }
  }

  void _showTravelEntryDialog() {
    // Ensure types are available
    // ignore: unused_local_variable
    final _ = EntryType.travel;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl - AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.xl - AppSpacing.xs,
                  AppSpacing.xl - AppSpacing.xs),
              child: UnifiedEntryForm(
                entryType: EntryType.travel,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showWorkEntryDialog() {
    // Ensure types are available
    // ignore: unused_local_variable
    final _ = EntryType.work;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl - AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.xl - AppSpacing.xs,
                  AppSpacing.xl - AppSpacing.xs),
              child: UnifiedEntryForm(
                entryType: EntryType.work,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showQuickEntry() {
    final t = AppLocalizations.of(context);
    final travelEnabled =
        context.read<SettingsProvider>().isTravelLoggingEnabled;
    // Show bottom sheet with quick entry options
    showModalBottomSheet(
      context: context,
      builder: (BuildContext sheetContext) {
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;
        return Container(
          padding: AppSpacing.sheetPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.home_quickEntry,
                style: AppTypography.sectionTitle(colorScheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (travelEnabled)
                ListTile(
                  leading:
                      Icon(Icons.directions_car, color: colorScheme.primary),
                  title: Text(t.home_logTravel),
                  subtitle: Text(t.home_quickTravelEntry),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(sheetContext);
                    _startTravelEntry();
                  },
                ),
              ListTile(
                leading: Icon(Icons.work, color: colorScheme.secondary),
                title: Text(t.home_logWork),
                subtitle: Text(t.home_quickWorkEntry),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(sheetContext);
                  _startWorkEntry();
                },
              ),
              ListTile(
                leading: Icon(Icons.event_busy, color: colorScheme.tertiary),
                title: Text(t.absence_addAbsence),
                subtitle: Text(t.settings_absencesDesc),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(sheetContext);
                  _startAbsenceEntry();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  // Pinned header with blur for Recent Entries.
  // Keeps height constant so the scroll physics stay stable.
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const _PinnedHeaderDelegate({
    required this.height,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}

class _EntryData {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String duration;
  final IconData icon;
  final DateTime date;

  _EntryData({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.icon,
    required this.date,
  });
}

class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final bool circular;

  const _ShimmerBox({
    this.width,
    required this.height,
    this.circular = false,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> {
  double _begin = -1;
  double _end = 1.6;

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withValues(alpha: 0.45);
    final highlightColor =
        Theme.of(context).colorScheme.surface.withValues(alpha: 0.85);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _begin, end: _end),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.linear,
      onEnd: () {
        if (!mounted) return;
        setState(() {
          final previousBegin = _begin;
          _begin = _end;
          _end = previousBegin;
        });
      },
      builder: (context, value, child) {
        return ClipRRect(
          borderRadius: widget.circular
              ? BorderRadius.circular(widget.height / 2)
              : BorderRadius.circular(AppRadius.sm),
          child: ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(-1 + value, 0),
                end: Alignment(value, 0),
                colors: [baseColor, highlightColor, baseColor],
                stops: const [0.1, 0.5, 0.9],
              ).createShader(bounds);
            },
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        color: baseColor,
      ),
    );
  }
}

class _TravelEntryDialog extends StatefulWidget {
  final bool enableSuggestions;

  const _TravelEntryDialog({this.enableSuggestions = true});

  @override
  State<_TravelEntryDialog> createState() => _TravelEntryDialogState();
}

/// Public wrapper to allow tests to construct the dialog with
/// `enableSuggestions: false` without referencing the private class.
class TravelEntryDialog extends StatelessWidget {
  final bool enableSuggestions;
  const TravelEntryDialog({super.key, this.enableSuggestions = true});

  @override
  Widget build(BuildContext context) {
    return _TravelEntryDialog(enableSuggestions: enableSuggestions);
  }
}

class _TravelEntryDialogState extends State<_TravelEntryDialog> {
  final List<_TripData> _trips = [];
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _totalHoursController = TextEditingController();
  final TextEditingController _totalMinutesController = TextEditingController();

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showSuggestions(
    ThemeData theme,
    TextEditingController controller,
    List<AutocompleteSuggestion> suggestions,
  ) {
    _overlayEntry?.remove();

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 48, // Account for dialog padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0.0, 60.0), // Below the text field
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 200,
                maxWidth: size.width - 48,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return InkWell(
                    onTap: () {
                      controller.text = suggestion.text;
                      if (suggestion.location != null) {
                        context
                            .read<LocationProvider>()
                            .incrementUsageCount(suggestion.location!.id);
                      }
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getSuggestionIcon(suggestion.type),
                            size: 20,
                            color: _getSuggestionColor(theme, suggestion.type),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  suggestion.text,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  suggestion.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  IconData _getSuggestionIcon(SuggestionType type) {
    switch (type) {
      case SuggestionType.favorite:
        return Icons.star_rounded;
      case SuggestionType.recent:
        return Icons.history_rounded;
      case SuggestionType.saved:
        return Icons.location_on_rounded;
      case SuggestionType.custom:
        return Icons.add_location_alt_rounded;
    }
  }

  Color _getSuggestionColor(ThemeData theme, SuggestionType type) {
    switch (type) {
      case SuggestionType.favorite:
        return AppColors.accent;
      case SuggestionType.recent:
        return theme.colorScheme.secondary;
      case SuggestionType.saved:
        return theme.colorScheme.primary;
      case SuggestionType.custom:
        return theme.colorScheme.tertiary;
    }
  }

  Widget _buildLocationField(
    ThemeData theme, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    Key? fieldKey,
  }) {
    if (!widget.enableSuggestions) {
      // Suggestions disabled for tests: render a plain TextField without overlay plumbing
      return TextField(
        key: fieldKey,
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: iconColor, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: iconColor, width: 2),
          ),
        ),
        onChanged: (_) => setState(() {}),
      );
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        key: fieldKey,
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: iconColor, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: iconColor, width: 2),
          ),
        ),
        onChanged: (value) {
          final locationProvider = context.read<LocationProvider>();
          final suggestions =
              locationProvider.getAutocompleteSuggestions(value);

          if (suggestions.isNotEmpty) {
            _showSuggestions(theme, controller, suggestions);
          } else {
            _overlayEntry?.remove();
            _overlayEntry = null;
          }
        },
        onTap: () {
          final locationProvider = context.read<LocationProvider>();
          final suggestions = locationProvider.getAutocompleteSuggestions('');

          if (suggestions.isNotEmpty) {
            _showSuggestions(theme, controller, suggestions);
          }
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Add initial trip
    _trips.add(_TripData());
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _notesController.dispose();
    _totalHoursController.dispose();
    _totalMinutesController.dispose();
    for (final trip in _trips) {
      trip.dispose();
    }
    super.dispose();
  }

  void _addTrip() {
    HapticFeedback.lightImpact();
    setState(() {
      // If there are existing trips, use the last destination as the new starting point
      String? lastDestination;
      if (_trips.isNotEmpty) {
        lastDestination = _trips.last.toController.text.trim();
      }
      _trips.add(_TripData(initialFrom: lastDestination));
    });
  }

  void _removeTrip(int index) {
    setState(() {
      _trips.removeAt(index);
      // Ensure we always have at least one trip
      if (_trips.isEmpty) {
        _trips.add(_TripData());
      }
    });
  }

  void _updateTotalDuration() {
    int totalMinutes = 0;
    for (final trip in _trips) {
      totalMinutes += trip.totalMinutes;
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    _totalHoursController.text = hours.toString();
    _totalMinutesController.text = minutes.toString();
  }

  bool _isValid() {
    if (_trips.isEmpty) return false;

    for (final trip in _trips) {
      if (!trip.isValid) return false;
    }

    // Check if total duration is greater than 0
    int totalMinutes = 0;
    for (final trip in _trips) {
      totalMinutes += trip.totalMinutes;
    }
    return totalMinutes > 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final todayLabel = DateFormat.yMMMd(localeTag).format(DateTime.now());

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl - AppSpacing.xs),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.lg + AppSpacing.xs),
                  topRight: Radius.circular(AppRadius.lg + AppSpacing.xs),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: AppColors.neutral50,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.home_logTravelEntry,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.neutral50,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          t.home_trackJourneyDetails,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.neutral50.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: AppColors.neutral50,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trips section
                    Row(
                      children: [
                        Icon(
                          Icons.route,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          t.home_tripDetails,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // List of trips
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Column(
                        children: _trips.asMap().entries.map((entry) {
                          final index = entry.key;
                          final trip = entry.value;

                          return Column(
                            children: [
                              if (index > 0) ...[
                                const SizedBox(height: AppSpacing.lg),
                                Container(
                                  height: 1,
                                  color: AppColors.neutral200,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                              _buildTripRow(theme, index, trip),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    // Add trip button
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const Key('add_trip_button'),
                        onPressed: _addTrip,
                        icon: Icon(
                          Icons.add_circle_outline,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        label: Text(
                          t.home_addAnotherTrip,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                          side: BorderSide(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Total duration
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 20,
                          color: AppColors.neutral700,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          t.home_totalDuration,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.neutral200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).entry_hours,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.neutral700,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                TextField(
                                  controller: _totalHoursController,
                                  keyboardType: TextInputType.number,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.neutral50,
                                    contentPadding:
                                        const EdgeInsets.all(AppSpacing.md),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).entry_minutes,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.neutral700,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                TextField(
                                  controller: _totalMinutesController,
                                  keyboardType: TextInputType.number,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.neutral50,
                                    contentPadding:
                                        const EdgeInsets.all(AppSpacing.md),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl - AppSpacing.xs),

                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: t.form_notesOptional,
                        hintText: t.travel_notesHint,
                        prefixIcon: Icon(
                          Icons.note,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: AppColors.primaryContainer,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              t.home_entryWillBeLoggedFor(todayLabel),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 12,
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.lg + AppSpacing.xs),
                  bottomRight: Radius.circular(AppRadius.lg + AppSpacing.xs),
                ),
              ),
              child: Row(
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('travel_save_button'),
                      onPressed: _isValid()
                          ? () async {
                              if (!mounted) return;
                              HapticFeedback.lightImpact();
                              try {
                                // Use EntryProvider instead of legacy repository
                                final entryProvider =
                                    context.read<EntryProvider>();
                                final authService =
                                    context.read<SupabaseAuthService>();
                                final userId = authService.currentUser?.id;
                                if (userId == null) return;

                                // Create atomic entries for all trips (one Entry per trip)
                                final entryDate = DateTime.now();
                                final dayNotes =
                                    _notesController.text.trim().isEmpty
                                        ? null
                                        : _notesController.text.trim();

                                final travelEntries = _trips.map((trip) {
                                  return Entry.makeTravelAtomicFromLeg(
                                    userId: userId,
                                    date: entryDate,
                                    from: trip.fromController.text.trim(),
                                    to: trip.toController.text.trim(),
                                    minutes: trip.totalMinutes,
                                    dayNotes:
                                        dayNotes, // Same notes for all trips on same day
                                  );
                                }).toList();

                                debugPrint(
                                    'Created ${travelEntries.length} travel entry/entries via EntryProvider');

                                // Save all entries via EntryProvider (the ONLY write path)
                                // Use batch save for efficiency
                                debugPrint(
                                    'Saving via EntryProvider (batch)...');
                                await entryProvider.addEntries(travelEntries);
                                debugPrint(
                                    'Successfully saved ${travelEntries.length} entry/entries via EntryProvider!');

                                Navigator.of(context).pop();

                                // Refresh recent entries by calling the parent's method
                                if (context.mounted) {
                                  final parent =
                                      context.findAncestorStateOfType<
                                          _UnifiedHomeScreenState>();
                                  parent?._loadRecentEntries();
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColors.neutral50,
                                          size: 20,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(t.home_travelEntryLoggedSuccess),
                                      ],
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.error,
                                          color: AppColors.neutral50,
                                          size: 20,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(t.edit_errorSaving(e.toString())),
                                      ],
                                    ),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: AppColors.neutral50,
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            t.home_logEntry,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripRow(ThemeData theme, int index, _TripData trip) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.directions_car,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md - 2),
              Text(
                t.edit_trip(index + 1),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (_trips.length > 1)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: IconButton(
                    onPressed: () => _removeTrip(index),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.sm - 2),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // From field
          _buildLocationField(
            theme,
            controller: trip.fromController,
            label: t.edit_from,
            hint: t.edit_departureHint,
            icon: Icons.location_on_outlined,
            iconColor: theme.colorScheme.primary,
            fieldKey: Key('travel_from_$index'),
          ),
          const SizedBox(height: AppSpacing.md),

          // To field
          _buildLocationField(
            theme,
            controller: trip.toController,
            label: t.edit_to,
            hint: t.edit_destinationHint,
            icon: Icons.location_on,
            iconColor: theme.colorScheme.secondary,
            fieldKey: Key('travel_to_$index'),
          ),
          const SizedBox(height: AppSpacing.md),

          // Duration fields
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.form_hours,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      key: Key('travel_hours_$index'),
                      controller: trip.hoursController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixIcon: Icon(
                          Icons.schedule,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (_) {
                        _updateTotalDuration();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.form_minutes,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      key: Key('travel_minutes_$index'),
                      controller: trip.minutesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixIcon: Icon(
                          Icons.timer,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) {
                        final minutes = int.tryParse(value) ?? 0;
                        if (minutes > 59) {
                          trip.minutesController.text = '59';
                          trip.minutesController.selection =
                              TextSelection.fromPosition(
                            TextPosition(offset: 2),
                          );
                        }
                        _updateTotalDuration();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripData {
  final TextEditingController fromController;
  final TextEditingController toController;
  final TextEditingController hoursController;
  final TextEditingController minutesController;

  _TripData({String? initialFrom})
      : fromController = TextEditingController(text: initialFrom ?? ''),
        toController = TextEditingController(),
        hoursController = TextEditingController(),
        minutesController = TextEditingController();

  void dispose() {
    fromController.dispose();
    toController.dispose();
    hoursController.dispose();
    minutesController.dispose();
  }

  bool get isValid {
    final from = fromController.text.trim();
    final to = toController.text.trim();
    final hours = int.tryParse(hoursController.text) ?? 0;
    final minutes = int.tryParse(minutesController.text) ?? 0;

    return from.isNotEmpty && to.isNotEmpty && (hours > 0 || minutes > 0);
  }

  int get totalMinutes {
    final hours = int.tryParse(hoursController.text) ?? 0;
    final minutes = int.tryParse(minutesController.text) ?? 0;
    return hours * 60 + minutes;
  }
}

class _WorkEntryDialog extends StatefulWidget {
  final bool enableSuggestions;
  const _WorkEntryDialog({this.enableSuggestions = true});

  @override
  State<_WorkEntryDialog> createState() => _WorkEntryDialogState();
}

class WorkEntryDialog extends StatelessWidget {
  final bool enableSuggestions;
  const WorkEntryDialog({super.key, this.enableSuggestions = true});

  @override
  Widget build(BuildContext context) {
    return _WorkEntryDialog(enableSuggestions: enableSuggestions);
  }
}

class _WorkEntryDialogState extends State<_WorkEntryDialog> {
  final List<_ShiftData> _shifts = [];
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _totalHoursController = TextEditingController();
  final TextEditingController _totalMinutesController = TextEditingController();

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    // Add initial shift
    _shifts.add(_ShiftData());
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _notesController.dispose();
    _totalHoursController.dispose();
    _totalMinutesController.dispose();
    for (final shift in _shifts) {
      shift.dispose();
    }
    super.dispose();
  }

  void _showSuggestions(
    ThemeData theme,
    TextEditingController controller,
    List<AutocompleteSuggestion> suggestions,
  ) {
    _overlayEntry?.remove();

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 48, // Account for dialog padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0.0, 60.0), // Below the text field
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 200,
                maxWidth: size.width - 48,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return InkWell(
                    onTap: () {
                      controller.text = suggestion.text;
                      if (suggestion.location != null) {
                        context
                            .read<LocationProvider>()
                            .incrementUsageCount(suggestion.location!.id);
                      }
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getSuggestionIcon(suggestion.type),
                            size: 20,
                            color: _getSuggestionColor(theme, suggestion.type),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  suggestion.text,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  suggestion.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  IconData _getSuggestionIcon(SuggestionType type) {
    switch (type) {
      case SuggestionType.favorite:
        return Icons.star_rounded;
      case SuggestionType.recent:
        return Icons.history_rounded;
      case SuggestionType.saved:
        return Icons.location_on_rounded;
      case SuggestionType.custom:
        return Icons.add_location_alt_rounded;
    }
  }

  Color _getSuggestionColor(ThemeData theme, SuggestionType type) {
    switch (type) {
      case SuggestionType.favorite:
        return AppColors.accent;
      case SuggestionType.recent:
        return theme.colorScheme.secondary;
      case SuggestionType.saved:
        return theme.colorScheme.primary;
      case SuggestionType.custom:
        return theme.colorScheme.tertiary;
    }
  }

  Widget _buildLocationField(
    ThemeData theme, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    if (!widget.enableSuggestions) {
      return TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(
              color: iconColor,
              width: 2,
            ),
          ),
        ),
        onChanged: (_) {
          setState(() {});
        },
      );
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(
              color: iconColor,
              width: 2,
            ),
          ),
        ),
        onChanged: (value) {
          final locationProvider = context.read<LocationProvider>();
          final suggestions =
              locationProvider.getAutocompleteSuggestions(value);

          if (suggestions.isNotEmpty) {
            _showSuggestions(theme, controller, suggestions);
          } else {
            _overlayEntry?.remove();
            _overlayEntry = null;
          }
        },
        onTap: () {
          final locationProvider = context.read<LocationProvider>();
          final suggestions = locationProvider.getAutocompleteSuggestions('');

          if (suggestions.isNotEmpty) {
            _showSuggestions(theme, controller, suggestions);
          }
        },
      ),
    );
  }

  void _addShift() {
    HapticFeedback.lightImpact();
    setState(() {
      _shifts.add(_ShiftData());
    });
  }

  void _removeShift(int index) {
    setState(() {
      _shifts.removeAt(index);
      // Ensure we always have at least one shift
      if (_shifts.isEmpty) {
        _shifts.add(_ShiftData());
      }
    });
  }

  void _updateTotalDuration() {
    int totalMinutes = 0;
    for (final shift in _shifts) {
      totalMinutes += shift.totalMinutes;
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    _totalHoursController.text = hours.toString();
    _totalMinutesController.text = minutes.toString();
  }

  bool _isValid() {
    if (_shifts.isEmpty) return false;

    for (final shift in _shifts) {
      if (!shift.isValid) return false;
    }

    int totalMinutes = 0;
    for (final shift in _shifts) {
      totalMinutes += shift.totalMinutes;
    }
    return totalMinutes > 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final todayLabel = DateFormat.yMMMd(localeTag).format(DateTime.now());

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl - AppSpacing.xs),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.secondary,
                    theme.colorScheme.secondary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.lg + AppSpacing.xs),
                  topRight: Radius.circular(AppRadius.lg + AppSpacing.xs),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.neutral50.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.work,
                      color: AppColors.neutral50,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.home_logWorkEntry,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.neutral50,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          t.home_trackWorkShifts,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.neutral50.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: AppColors.neutral50,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shifts section
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 20,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          t.home_workShifts,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // List of shifts
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: Column(
                        children: _shifts.asMap().entries.map((entry) {
                          final index = entry.key;
                          final shift = entry.value;

                          return Column(
                            children: [
                              if (index > 0) ...[
                                const SizedBox(height: AppSpacing.lg),
                                Container(
                                  height: 1,
                                  color: AppColors.neutral200,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                              _buildShiftRow(theme, index, shift),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    // Add shift button
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const Key('add_shift_button'),
                        onPressed: _addShift,
                        icon: Icon(
                          Icons.add_circle_outline,
                          size: 20,
                          color: theme.colorScheme.secondary,
                        ),
                        label: Text(
                          t.home_addAnotherShift,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                          side: BorderSide(
                            color: theme.colorScheme.secondary
                                .withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Total duration
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 20,
                          color: AppColors.neutral700,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          t.home_totalDuration,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.neutral50,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.neutral200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).entry_hours,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.neutral700,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                TextField(
                                  controller: _totalHoursController,
                                  keyboardType: TextInputType.number,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.neutral50,
                                    contentPadding:
                                        const EdgeInsets.all(AppSpacing.md),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).entry_minutes,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.neutral700,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                TextField(
                                  controller: _totalMinutesController,
                                  keyboardType: TextInputType.number,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.neutral50,
                                    contentPadding:
                                        const EdgeInsets.all(AppSpacing.md),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl - AppSpacing.xs),

                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: t.form_notesOptional,
                        hintText: t.edit_notesHint,
                        prefixIcon: Icon(
                          Icons.note,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(
                            color: theme.colorScheme.secondary,
                            width: 2,
                          ),
                        ),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: AppColors.primaryContainer,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              t.home_entryWillBeLoggedFor(todayLabel),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 12,
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.lg + AppSpacing.xs),
                  bottomRight: Radius.circular(AppRadius.lg + AppSpacing.xs),
                ),
              ),
              child: Row(
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('work_save_button'),
                      onPressed: _isValid()
                          ? () async {
                              if (!mounted) return;
                              HapticFeedback.lightImpact();
                              try {
                                debugPrint('=== WORK ENTRY SAVE ATTEMPT ===');

                                // Use EntryProvider instead of legacy repository
                                final entryProvider =
                                    context.read<EntryProvider>();
                                final authService =
                                    context.read<SupabaseAuthService>();
                                final userId = authService.currentUser?.id;
                                if (userId == null) return;

                                final dayNotes =
                                    _notesController.text.trim().isEmpty
                                        ? null
                                        : _notesController.text.trim();
                                final now = DateTime.now();
                                final entries = <Entry>[];

                                for (final shift in _shifts) {
                                  final startTod = shift._parseTimeOfDay(
                                      shift.startTimeController.text);
                                  final endTod = shift._parseTimeOfDay(
                                      shift.endTimeController.text);

                                  if (startTod == null || endTod == null) {
                                    continue; // _isValid should prevent this
                                  }

                                  final startDateTime = DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                    startTod.hour,
                                    startTod.minute,
                                  );
                                  var endDateTime = DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                    endTod.hour,
                                    endTod.minute,
                                  );

                                  // Handle overnight shifts
                                  if (endDateTime.isBefore(startDateTime)) {
                                    endDateTime = endDateTime
                                        .add(const Duration(days: 1));
                                  }

                                  final shiftModel = Shift(
                                    start: startDateTime,
                                    end: endDateTime,
                                    unpaidBreakMinutes: 0,
                                    notes: dayNotes,
                                  );

                                  entries.add(
                                    Entry.makeWorkAtomicFromShift(
                                      userId: userId,
                                      date: startDateTime,
                                      shift: shiftModel,
                                      dayNotes: dayNotes,
                                    ),
                                  );
                                }

                                if (entries.isEmpty) {
                                  throw StateError(t.error_addAtLeastOneShift);
                                }

                                debugPrint(
                                    'Saving ${entries.length} atomic work entries via EntryProvider...');
                                await entryProvider.addEntries(entries);
                                debugPrint(
                                    'Successfully saved ${entries.length} entry/entries via EntryProvider!');

                                Navigator.of(context).pop();

                                // Refresh recent entries by calling the parent's method
                                if (context.mounted) {
                                  final parent =
                                      context.findAncestorStateOfType<
                                          _UnifiedHomeScreenState>();
                                  parent?._loadRecentEntries();
                                }
                                final successText = entries.length > 1
                                    ? t.home_workEntriesLoggedSuccess
                                    : t.home_workEntryLoggedSuccess;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColors.neutral50,
                                          size: 20,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(successText),
                                      ],
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.error,
                                          color: AppColors.neutral50,
                                          size: 20,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(t.edit_errorSaving(e.toString())),
                                      ],
                                    ),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: AppColors.neutral50,
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            t.home_logEntry,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftRow(ThemeData theme, int index, _ShiftData shift) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.neutral200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md - 2),
              Text(
                t.edit_shift(index + 1),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const Spacer(),
              if (_shifts.length > 1)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: IconButton(
                    onPressed: () => _removeShift(index),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.sm - 2),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Time fields
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).home_startTime,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (!widget.enableSuggestions)
                      TextField(
                        key: Key('work_start_$index'),
                        controller: shift.startTimeController,
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context).home_timeExample,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          _updateTotalDuration();
                          setState(() {});
                        },
                      )
                    else
                      InkWell(
                        onTap: () => _selectTime(
                            context, shift.startTimeController, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.neutral300),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.neutral400
                                    : AppColors.neutral600,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  shift.startTimeController.text.isEmpty
                                      ? AppLocalizations.of(context)
                                          .home_selectTime
                                      : shift.startTimeController.text,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: shift.startTimeController.text
                                                .isEmpty
                                            ? AppColors.mutedForeground(
                                                Theme.of(context).brightness)
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).home_endTime,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (!widget.enableSuggestions)
                      TextField(
                        key: Key('work_end_$index'),
                        controller: shift.endTimeController,
                        decoration: InputDecoration(
                          hintText: t.home_timeExample,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          _updateTotalDuration();
                          setState(() {});
                        },
                      )
                    else
                      InkWell(
                        onTap: () => _selectTime(
                            context, shift.endTimeController, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.neutral300),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.neutral400
                                    : AppColors.neutral600,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  shift.endTimeController.text.isEmpty
                                      ? AppLocalizations.of(context)
                                          .home_selectTime
                                      : shift.endTimeController.text,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: shift
                                                .endTimeController.text.isEmpty
                                            ? AppColors.mutedForeground(
                                                Theme.of(context).brightness)
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Duration display
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.primaryContainer),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${t.entry_duration}: ${shift.formattedDuration}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryDark,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context,
      TextEditingController controller, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return child!;
      },
    );

    if (picked != null) {
      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _updateTotalDuration();
      setState(() {});
    }
  }
}

class _ShiftData {
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;

  _ShiftData()
      : startTimeController = TextEditingController(),
        endTimeController = TextEditingController();

  void dispose() {
    startTimeController.dispose();
    endTimeController.dispose();
  }

  bool get isValid {
    final startTime = startTimeController.text.trim();
    final endTime = endTimeController.text.trim();

    return startTime.isNotEmpty && endTime.isNotEmpty && totalMinutes > 0;
  }

  int get totalMinutes {
    if (startTimeController.text.isEmpty || endTimeController.text.isEmpty) {
      return 0;
    }

    try {
      final startTime = _parseTimeOfDay(startTimeController.text);
      final endTime = _parseTimeOfDay(endTimeController.text);

      if (startTime == null || endTime == null) return 0;

      int startMinutes = startTime.hour * 60 + startTime.minute;
      int endMinutes = endTime.hour * 60 + endTime.minute;

      // Handle overnight shifts
      if (endMinutes < startMinutes) {
        endMinutes += 24 * 60; // Add 24 hours
      }

      return endMinutes - startMinutes;
    } catch (e) {
      return 0;
    }
  }

  String get formattedDuration {
    final minutes = totalMinutes;
    if (minutes <= 0) return '0h 0m';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0 && remainingMinutes > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${remainingMinutes}m';
    }
  }

  TimeOfDay? _parseTimeOfDay(String timeString) {
    final input = timeString.trim();
    if (input.isEmpty) return null;

    // 24h format: "H:mm" / "HH:mm"
    final match24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(input);
    if (match24 != null) {
      final hour = int.tryParse(match24.group(1) ?? '');
      final minute = int.tryParse(match24.group(2) ?? '');
      if (hour != null &&
          minute != null &&
          hour >= 0 &&
          hour <= 23 &&
          minute >= 0 &&
          minute <= 59) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }

    // 12h format: "h:mm AM/PM" (with optional space)
    final match12 =
        RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$').firstMatch(input);
    if (match12 != null) {
      var hour = int.tryParse(match12.group(1) ?? '');
      final minute = int.tryParse(match12.group(2) ?? '');
      final amPm = (match12.group(3) ?? '').toLowerCase();
      if (hour == null || minute == null) return null;
      if (hour < 1 || hour > 12 || minute < 0 || minute > 59) return null;

      if (amPm == 'am') {
        if (hour == 12) hour = 0;
      } else if (amPm == 'pm') {
        if (hour != 12) hour += 12;
      } else {
        return null;
      }
      return TimeOfDay(hour: hour, minute: minute);
    }

    return null;
  }
}
