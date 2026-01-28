// ignore_for_file: use_build_context_synchronously
// ignore_for_file: avoid_print
// ignore_for_file: unused_element

import '../design/design.dart';
import '../widgets/unified_entry_form.dart';
import '../widgets/entry_detail_sheet.dart';
import '../widgets/flexsaldo_card.dart';
import '../widgets/absence_entry_dialog.dart';
import 'dart:async';
import '../models/entry.dart';
import '../models/absence.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_router.dart';
import '../models/autocomplete_suggestion.dart';
// EntryProvider is the only write path
import '../providers/entry_provider.dart';
import '../providers/absence_provider.dart';
import '../providers/location_provider.dart';
import '../providers/settings_provider.dart';
import '../services/supabase_auth_service.dart';
import '../l10n/generated/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    // Always sync with Supabase on startup, then load recent entries
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final entryProvider = context.read<EntryProvider>();
      final absenceProvider = context.read<AbsenceProvider>();
      
      // Load absences for current year
      absenceProvider.loadAbsences(year: DateTime.now().year);
      
      if (!entryProvider.isLoading) {
        // Always load/sync with Supabase on login
        entryProvider.loadEntries().then((_) {
          // Reload recent entries after Supabase sync completes
          _loadRecentEntries();
        });
      } else {
        _loadRecentEntries();
      }
    });
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
      final entryProvider = context.read<EntryProvider>();
      final absenceProvider = context.read<AbsenceProvider>();
      final settingsProvider = context.read<SettingsProvider>();
      final authService = context.read<SupabaseAuthService>();
      final userId = authService.currentUser?.id;
      final travelEnabled = settingsProvider.isTravelLoggingEnabled;

      if (userId == null) {
        setState(() {
          _recentEntries = [];
        });
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
      final travelEntries = sortedEntries.where((e) => e.type == EntryType.travel).take(5);
      for (final entry in travelEntries) {
        final fromText = entry.from ?? '';
        final toText = entry.to ?? '';
        final minutes = entry.travelMinutes ?? 0;
        allEntries.add(_EntryData(
          id: entry.id,
          type: 'travel',
          title: 'Travel: $fromText → $toText',
          subtitle:
              '${entry.date.toString().split(' ')[0]} • ${entry.notes?.isNotEmpty == true ? entry.notes : AppLocalizations.of(context).home_noRemarks}',
          duration: '${minutes ~/ 60}h ${minutes % 60}m',
          icon: Icons.directions_car,
          date: entry.date,
        ));
      }
      }

      // Convert work entries
      final workEntries = sortedEntries.where((e) => e.type == EntryType.work).take(5);
      for (final entry in workEntries) {
        // Show shift time range + location (and worked minutes)
        final shift = entry.atomicShift ?? entry.shifts?.first;
        final workedMinutes = entry.totalWorkDuration?.inMinutes ?? 0;
        String title = AppLocalizations.of(context).home_workSession;
        String subtitle = entry.date.toString().split(' ')[0];
        
        if (shift != null) {
          final startTime = TimeOfDay.fromDateTime(shift.start);
          final endTime = TimeOfDay.fromDateTime(shift.end);
          title = '${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)}';
          if (shift.location != null && shift.location!.isNotEmpty) {
            subtitle += ' • ${shift.location}';
          }
        }
        
        if (entry.notes?.isNotEmpty == true) {
          subtitle += ' • ${entry.notes}';
        } else {
          subtitle += ' • ${AppLocalizations.of(context).home_noRemarks}';
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
      debugPrint('Found ${absences.length} absence entries for year $currentYear');
      
      for (final absence in absences.take(5)) {
        final typeLabel = _getAbsenceTypeLabel(absence.type);
        final durationText = absence.minutes == 0
            ? 'Full day'
            : '${absence.minutes ~/ 60}h ${absence.minutes % 60}m';
        
        allEntries.add(_EntryData(
          id: absence.id ?? 'absence_${absence.date.millisecondsSinceEpoch}',
          type: 'absence',
          title: typeLabel,
          subtitle: absence.date.toString().split(' ')[0],
          duration: durationText,
          icon: _getAbsenceIcon(absence.type),
          date: absence.date,
        ));
      }

      // Sort by real date (most recent first)
      allEntries.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _recentEntries = allEntries.take(10).toList();
      });
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

    return Scaffold(
      key: const Key('screen_home'),
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.timer_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.home_title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  t.home_subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            onPressed: () => AppRouter.goToProfile(context),
            tooltip: t.common_profile,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.settings_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            onPressed: () => AppRouter.goToSettings(context),
            tooltip: t.nav_settings,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Flexsaldo MTD Card (prominent at top)
            const FlexsaldoCard(),
            const SizedBox(height: 16),
            
            // Today's Total Card
            Consumer<EntryProvider>(
              builder: (context, entryProvider, _) =>
                  _buildTotalCard(theme, entryProvider, t, travelEnabled),
            ),
            const SizedBox(height: 16),

            // Stats Section
            Consumer<EntryProvider>(
              builder: (context, entryProvider, _) =>
                  _buildStatsSection(theme, entryProvider, t, travelEnabled),
            ),
            const SizedBox(height: 16),

            // Recent Entries
            _buildRecentEntries(theme, t),
            const SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showQuickEntry,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.add, size: 28),
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
    // Calculate today's totals
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todayEntries = entryProvider.entries.where((entry) {
      return entry.date.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          entry.date.isBefore(todayEnd);
    }).toList();

    // Calculate totals
    Duration totalDuration = Duration.zero;
    Duration travelDuration = Duration.zero;
    Duration workDuration = Duration.zero;

    for (final entry in todayEntries) {
      if (entry.type == EntryType.work) {
        workDuration += entry.totalDuration;
        totalDuration += entry.totalDuration;
      } else if (entry.type == EntryType.travel && travelEnabled) {
        travelDuration += entry.totalDuration;
        totalDuration += entry.totalDuration;
      }
    }

    // Format durations
    String formatDuration(Duration duration) {
      if (duration.inMinutes == 0) return '0m';
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (hours > 0) {
        return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
      }
      return '${minutes}m';
    }

    final totalText = formatDuration(totalDuration);
    final travelText = formatDuration(travelDuration);
    final workText = formatDuration(workDuration);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
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
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalText,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Breakdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (travelEnabled) ...[
                  Icon(Icons.directions_car_rounded,
                      color: Colors.white.withValues(alpha: 0.9), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    travelText,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Icon(Icons.work_rounded,
                    color: Colors.white.withValues(alpha: 0.9), size: 16),
                const SizedBox(width: 4),
                Text(
                  workText,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
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

  Widget _buildStatsSection(
    ThemeData theme,
    EntryProvider entryProvider,
    AppLocalizations t,
    bool travelEnabled,
  ) {
    // Calculate this week's totals
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEndDate = weekStartDate.add(const Duration(days: 7));

    final weekEntries = entryProvider.entries.where((entry) {
      return entry.date.isAfter(weekStartDate.subtract(const Duration(seconds: 1))) &&
          entry.date.isBefore(weekEndDate);
    }).toList();

    // Calculate totals
    Duration travelDuration = Duration.zero;
    Duration workDuration = Duration.zero;

    for (final entry in weekEntries) {
      if (entry.type == EntryType.travel && travelEnabled) {
        travelDuration += entry.totalDuration;
      } else if (entry.type == EntryType.work) {
        workDuration += entry.totalDuration;
      }
    }

    // Format hours
    String formatHours(Duration duration) {
      final hours = duration.inHours;
      final mins = duration.inMinutes % 60;
      if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
      if (hours > 0) return '${hours}h';
      return '${mins}m';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                t.common_thisWeek,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (travelEnabled) ...[
                Expanded(
                  child: _buildCompactStat(
                    theme,
                    icon: Icons.directions_car_rounded,
                    value: formatHours(travelDuration),
                    label: t.entry_travel,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ],
              Expanded(
                child: _buildCompactStat(
                  theme,
                  icon: Icons.work_rounded,
                  value: formatHours(workDuration),
                  label: t.entry_work,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(
    ThemeData theme, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
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

  Widget _buildRecentEntries(ThemeData theme, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              t.home_recentEntries,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => AppRouter.goToHistory(context),
              child: Text(
                t.home_viewAllArrow,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentEntries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 36,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  t.home_noEntriesYet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ...(_recentEntries
              .take(5)
              .map((entry) => _buildRecentEntryCard(theme, entry))),
      ],
    );
  }

  Widget _buildRecentEntryCard(ThemeData theme, _EntryData entry) {
    Color color;
    switch (entry.type) {
      case 'travel':
        color = theme.colorScheme.primary;
        break;
      case 'work':
        color = theme.colorScheme.secondary;
        break;
      case 'absence':
        color = Colors.orange;
        break;
      default:
        color = theme.colorScheme.tertiary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _openQuickView(entry),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(entry.icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    entry.duration,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: EntryDetailSheet(
              entry: full!,
              onEdit: () => _editEntry(summary),
              onDelete: () => _deleteEntry(context, summary),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                    Navigator.pop(sheetContext);
                    _startTravelEntry();
                  },
                ),
              ListTile(
                leading: Icon(Icons.work, color: colorScheme.secondary),
                title: Text(t.home_logWork),
                subtitle: Text(t.home_quickWorkEntry),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _startWorkEntry();
                },
              ),
              ListTile(
                leading: Icon(Icons.event_busy, color: colorScheme.tertiary),
                title: Text(t.absence_addAbsence),
                subtitle: Text(t.settings_absencesDesc),
                onTap: () {
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
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 200,
                maxWidth: size.width - 48,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(width: 12),
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
        return Colors.amber;
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
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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
          final suggestions =
              locationProvider.getAutocompleteSuggestions('');

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

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
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
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).home_logTravelEntry,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track your journey details',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
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
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).home_tripDetails,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // List of trips
                    ..._trips.asMap().entries.map((entry) {
                      final index = entry.key;
                      final trip = entry.value;

                      return Column(
                        children: [
                          if (index > 0) ...[
                            const SizedBox(height: 16),
                            Container(
                              height: 1,
                              color: Colors.grey[200],
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildTripRow(theme, index, trip),
                        ],
                      );
                    }),

                    // Add trip button
                    const SizedBox(height: 16),
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
                          AppLocalizations.of(context).home_addAnotherTrip,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Total duration
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 20,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total Duration',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _totalHoursController,
                                  keyboardType: TextInputType.number,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).entry_minutes,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _totalMinutesController,
                                  keyboardType: TextInputType.number,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Add details about your travel...',
                        prefixIcon: Icon(
                          Icons.note,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Entry will be logged for ${DateTime.now().toString().split(' ')[0]}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('travel_save_button'),
                      onPressed: _isValid()
                          ? () async {
                              if (!mounted) return;
                              try {

                                // Use EntryProvider instead of legacy repository
                                final entryProvider = context.read<EntryProvider>();
                                final authService = context.read<SupabaseAuthService>();
                                final userId = authService.currentUser?.id;
                                if (userId == null) return;

                                // Create atomic entries for all trips (one Entry per trip)
                                final entryDate = DateTime.now();
                                final dayNotes = _notesController.text.trim().isEmpty 
                                    ? null 
                                    : _notesController.text.trim();
                                
                                final travelEntries = _trips.map((trip) {
                                  return Entry.makeTravelAtomicFromLeg(
                                    userId: userId,
                                    date: entryDate,
                                    from: trip.fromController.text.trim(),
                                    to: trip.toController.text.trim(),
                                    minutes: trip.totalMinutes,
                                    dayNotes: dayNotes, // Same notes for all trips on same day
                                  );
                                }).toList();

                                print(
                                    'Created ${travelEntries.length} travel entry/entries via EntryProvider');
                                
                                // Save all entries via EntryProvider (the ONLY write path)
                                // Use batch save for efficiency
                                print('Saving via EntryProvider (batch)...');
                                await entryProvider.addEntries(travelEntries);
                                print('Successfully saved ${travelEntries.length} entry/entries via EntryProvider!');

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
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                            'Travel entry logged successfully!'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
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
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                            'Error saving entry: ${e.toString()}'),
                                      ],
                                    ),
                                    backgroundColor: Colors.red[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).home_logEntry,
                            style: TextStyle(
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_car,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Trip ${index + 1}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (_trips.length > 1)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _removeTrip(index),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red[600],
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // From field
          _buildLocationField(
            theme,
            controller: trip.fromController,
            label: 'From',
            hint: 'Enter starting location',
            icon: Icons.location_on_outlined,
            iconColor: theme.colorScheme.primary,
            fieldKey: Key('travel_from_$index'),
          ),
          const SizedBox(height: 12),

          // To field
          _buildLocationField(
            theme,
            controller: trip.toController,
            label: 'To',
            hint: 'Enter destination',
            icon: Icons.location_on,
            iconColor: theme.colorScheme.secondary,
            fieldKey: Key('travel_to_$index'),
          ),
          const SizedBox(height: 12),

          // Duration fields
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hours',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minutes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 200,
                maxWidth: size.width - 48,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(width: 12),
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
        return Colors.amber;
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
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
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
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.work,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).home_logWorkEntry,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track your work shifts',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
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
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).home_workShifts,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // List of shifts
                    ..._shifts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final shift = entry.value;

                      return Column(
                        children: [
                          if (index > 0) ...[
                            const SizedBox(height: 16),
                            Container(
                              height: 1,
                              color: Colors.grey[200],
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildShiftRow(theme, index, shift),
                        ],
                      );
                    }),

                    // Add shift button
                    const SizedBox(height: 16),
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
                          AppLocalizations.of(context).home_addAnotherShift,
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Total duration
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 20,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total Duration',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _totalHoursController,
                                  keyboardType: TextInputType.number,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).entry_minutes,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _totalMinutesController,
                                  keyboardType: TextInputType.number,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Add details about your work...',
                        prefixIcon: Icon(
                          Icons.note,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.secondary,
                            width: 2,
                          ),
                        ),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Entry will be logged for ${DateTime.now().toString().split(' ')[0]}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('work_save_button'),
                      onPressed: _isValid()
                          ? () async {
                              if (!mounted) return;
                              try {
                                print('=== WORK ENTRY SAVE ATTEMPT ===');

                                // Use EntryProvider instead of legacy repository
                                final entryProvider = context.read<EntryProvider>();
                                final authService = context.read<SupabaseAuthService>();
                                final userId = authService.currentUser?.id;
                                if (userId == null) return;

                                final dayNotes = _notesController.text.trim().isEmpty
                                    ? null
                                    : _notesController.text.trim();
                                final now = DateTime.now();
                                final entries = <Entry>[];

                                for (final shift in _shifts) {
                                  final startTod =
                                      shift._parseTimeOfDay(shift.startTimeController.text);
                                  final endTod =
                                      shift._parseTimeOfDay(shift.endTimeController.text);

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
                                    endDateTime = endDateTime.add(const Duration(days: 1));
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
                                  throw StateError('No valid shifts to save');
                                }

                                print('Saving ${entries.length} atomic work entries via EntryProvider...');
                                await entryProvider.addEntries(entries);
                                print('Successfully saved ${entries.length} entry/entries via EntryProvider!');

                                Navigator.of(context).pop();

                                // Refresh recent entries by calling the parent's method
                                if (context.mounted) {
                                  final parent =
                                      context.findAncestorStateOfType<
                                          _UnifiedHomeScreenState>();
                                  parent?._loadRecentEntries();
                                }
                                final successText = entries.length > 1
                                    ? 'Work entries logged successfully!'
                                    : 'Work entry logged successfully!';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(successText),
                                      ],
                                    ),
                                    backgroundColor: Colors.green[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
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
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                            'Error saving entry: ${e.toString()}'),
                                      ],
                                    ),
                                    backgroundColor: Colors.red[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).home_logEntry,
                            style: TextStyle(
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Shift ${index + 1}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const Spacer(),
              if (_shifts.length > 1)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _removeShift(index),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red[600],
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Time fields
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).home_startTime,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!widget.enableSuggestions)
                      TextField(
                        key: Key('work_start_$index'),
                        controller: shift.startTimeController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).home_timeExample,
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
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  shift.startTimeController.text.isEmpty
                                      ? AppLocalizations.of(context).home_selectTime
                                      : shift.startTimeController.text,
                                  style: TextStyle(
                                    color:
                                        shift.startTimeController.text.isEmpty
                                            ? Colors.grey[500]
                                            : Colors.grey[700],
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).home_endTime,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!widget.enableSuggestions)
                      TextField(
                        key: Key('work_end_$index'),
                        controller: shift.endTimeController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 5:30 PM',
                          border: OutlineInputBorder(),
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
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  shift.endTimeController.text.isEmpty
                                      ? AppLocalizations.of(context).home_selectTime
                                      : shift.endTimeController.text,
                                  style: TextStyle(
                                    color: shift.endTimeController.text.isEmpty
                                        ? Colors.grey[500]
                                        : Colors.grey[700],
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

          const SizedBox(height: 12),

          // Duration display
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Duration: ${shift.formattedDuration}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[700],
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
        return Localizations.override(
          context: context,
          locale: const Locale('en', 'US'),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      controller.text = picked.format(context);
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
    try {
      final parts = timeString.split(' ');
      if (parts.length != 2) return null;

      final timePart = parts[0];
      final period = parts[1];

      final timeParts = timePart.split(':');
      if (timeParts.length != 2) return null;

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }
}
