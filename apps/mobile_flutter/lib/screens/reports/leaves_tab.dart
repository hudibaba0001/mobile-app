// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../design/app_theme.dart';
import '../../models/absence.dart';
import '../../providers/absence_provider.dart';
import '../../l10n/generated/app_localizations.dart';

class LeavesTab extends StatefulWidget {
  const LeavesTab({super.key});

  @override
  State<LeavesTab> createState() => _LeavesTabState();
}

class _LeavesTabState extends State<LeavesTab> {
  bool _isLoading = true;
  List<AbsenceEntry> _allAbsences = [];

  @override
  void initState() {
    super.initState();
    _loadAbsences();
  }

  Future<void> _loadAbsences() async {
    setState(() => _isLoading = true);

    try {
      final absenceProvider = context.read<AbsenceProvider>();
      final currentYear = DateTime.now().year;

      // Load current year and previous year
      await absenceProvider.loadAbsences(year: currentYear);
      await absenceProvider.loadAbsences(year: currentYear - 1);

      // Get absences from both years
      final currentYearAbsences = absenceProvider.absencesForYear(currentYear);
      final previousYearAbsences =
          absenceProvider.absencesForYear(currentYear - 1);

      // Combine and sort by date (most recent first)
      _allAbsences = [...currentYearAbsences, ...previousYearAbsences];
      _allAbsences.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('LeavesTab: Error loading absences: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Calculate summaries by type for current year
    final currentYear = DateTime.now().year;
    final currentYearAbsences =
        _allAbsences.where((a) => a.date.year == currentYear).toList();
    final summary = _calculateSummary(currentYearAbsences);

    return RefreshIndicator(
      onRefresh: _loadAbsences,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Leave Summary Section
          _buildSummarySection(theme, colorScheme, summary, currentYear),

          const SizedBox(height: AppSpacing.xl),

          // Recent Leaves Section
          _buildRecentLeavesSection(theme, colorScheme),
        ],
      ),
    );
  }

  Map<AbsenceType, _LeaveSummary> _calculateSummary(
      List<AbsenceEntry> absences) {
    final Map<AbsenceType, _LeaveSummary> summary = {};

    for (final type in AbsenceType.values) {
      summary[type] = _LeaveSummary(days: 0, totalMinutes: 0);
    }

    for (final absence in absences) {
      final existing = summary[absence.type]!;
      // Count as 1 day if minutes == 0 (full day) or sum up partial days
      if (absence.minutes == 0) {
        summary[absence.type] = _LeaveSummary(
          days: existing.days + 1,
          totalMinutes:
              existing.totalMinutes + 480, // Assume 8h day for full days
        );
      } else {
        // Partial day - add fraction
        final dayFraction = absence.minutes / 480.0; // 480 min = 8h
        summary[absence.type] = _LeaveSummary(
          days: existing.days + dayFraction,
          totalMinutes: existing.totalMinutes + absence.minutes,
        );
      }
    }

    return summary;
  }

  Widget _buildSummarySection(
    ThemeData theme,
    ColorScheme colorScheme,
    Map<AbsenceType, _LeaveSummary> summary,
    int year,
  ) {
    final t = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_note,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  t.leave_summary(year).toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Summary grid
            _buildSummaryRow(
              theme,
              colorScheme,
              icon: Icons.beach_access,
              iconColor: AppColors.primary,
              label: t.leave_paidVacation,
              value: summary[AbsenceType.vacationPaid]!,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSummaryRow(
              theme,
              colorScheme,
              icon: Icons.local_hospital,
              iconColor: AppColors.error,
              label: t.leave_sickLeave,
              value: summary[AbsenceType.sickPaid]!,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSummaryRow(
              theme,
              colorScheme,
              icon: Icons.child_care,
              iconColor: AppColors.accent,
              label: t.leave_vab,
              value: summary[AbsenceType.vabPaid]!,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSummaryRow(
              theme,
              colorScheme,
              icon: Icons.event_busy,
              iconColor: AppColors.mutedForeground(theme.brightness),
              label: t.leave_unpaid,
              value: summary[AbsenceType.unpaid]!,
            ),

            const Divider(height: 24),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.leave_totalLeaveDays,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDays(context, _getTotalDays(summary)),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getTotalDays(Map<AbsenceType, _LeaveSummary> summary) {
    double total = 0;
    for (final entry in summary.values) {
      total += entry.days;
    }
    return total;
  }

  Widget _buildSummaryRow(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required _LeaveSummary value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          _formatDays(context, value.days),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDays(BuildContext context, double days) {
    final t = AppLocalizations.of(context);
    if (days == 0) return t.leave_daysCount(0);
    if (days == 1) return t.leave_daysCount(1);
    if (days == days.truncate()) {
      return t.leave_daysCount(days.truncate());
    }
    return t.leave_daysDecimal(days.toStringAsFixed(1));
  }

  Widget _buildRecentLeavesSection(ThemeData theme, ColorScheme colorScheme) {
    final recentAbsences = _allAbsences.take(10).toList(); // Show last 10

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history,
              color: colorScheme.secondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppLocalizations.of(context).leave_recentLeaves.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (recentAbsences.isEmpty)
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 48,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppLocalizations.of(context).leave_noLeavesRecorded,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppLocalizations.of(context).leave_noLeavesDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...recentAbsences
              .map((absence) => _buildAbsenceCard(theme, colorScheme, absence)),
      ],
    );
  }

  Widget _buildAbsenceCard(
      ThemeData theme, ColorScheme colorScheme, AbsenceEntry absence) {
    final typeInfo = _getTypeInfo(context, absence.type);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md - 2),
              decoration: BoxDecoration(
                color: typeInfo.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md - 2),
              ),
              child: Icon(typeInfo.icon, color: typeInfo.color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeInfo.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    dateFormat.format(absence.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md - 2,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: typeInfo.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                absence.minutes == 0
                    ? AppLocalizations.of(context).leave_fullDay
                    : '${(absence.minutes / 60).toStringAsFixed(1)}h',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: typeInfo.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _TypeInfo _getTypeInfo(BuildContext context, AbsenceType type) {
    final t = AppLocalizations.of(context);
    switch (type) {
      case AbsenceType.vacationPaid:
        return _TypeInfo(
          icon: Icons.beach_access,
          color: AppColors.primary,
          label: t.leave_paidVacation,
        );
      case AbsenceType.sickPaid:
        return _TypeInfo(
          icon: Icons.local_hospital,
          color: AppColors.error,
          label: t.leave_sickLeave,
        );
      case AbsenceType.vabPaid:
        return _TypeInfo(
          icon: Icons.child_care,
          color: AppColors.accent,
          label: t.leave_vab,
        );
      case AbsenceType.unpaid:
        return _TypeInfo(
          icon: Icons.event_busy,
          color: AppColors.mutedForeground(Theme.of(context).brightness),
          label: t.leave_unpaid,
        );
    }
  }
}

class _LeaveSummary {
  final double days;
  final int totalMinutes;

  const _LeaveSummary({required this.days, required this.totalMinutes});
}

class _TypeInfo {
  final IconData icon;
  final Color color;
  final String label;

  const _TypeInfo(
      {required this.icon, required this.color, required this.label});
}
