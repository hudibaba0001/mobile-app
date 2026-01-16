import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
      final previousYearAbsences = absenceProvider.absencesForYear(currentYear - 1);
      
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
    final currentYearAbsences = _allAbsences.where((a) => a.date.year == currentYear).toList();
    final summary = _calculateSummary(currentYearAbsences);

    return RefreshIndicator(
      onRefresh: _loadAbsences,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Leave Summary Section
          _buildSummarySection(theme, colorScheme, summary, currentYear),
          
          const SizedBox(height: 24),
          
          // Recent Leaves Section
          _buildRecentLeavesSection(theme, colorScheme),
        ],
      ),
    );
  }

  Map<AbsenceType, _LeaveSummary> _calculateSummary(List<AbsenceEntry> absences) {
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
          totalMinutes: existing.totalMinutes + 480, // Assume 8h day for full days
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
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.leave_summary(year),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Summary grid
            _buildSummaryRow(
              theme, colorScheme,
              icon: Icons.beach_access,
              iconColor: Colors.blue,
              label: 'Paid Vacation',
              value: summary[AbsenceType.vacationPaid]!,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              theme, colorScheme,
              icon: Icons.local_hospital,
              iconColor: Colors.red,
              label: 'Sick Leave',
              value: summary[AbsenceType.sickPaid]!,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              theme, colorScheme,
              icon: Icons.child_care,
              iconColor: Colors.orange,
              label: 'VAB (Child Care)',
              value: summary[AbsenceType.vabPaid]!,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              theme, colorScheme,
              icon: Icons.event_busy,
              iconColor: Colors.grey,
              label: 'Unpaid Leave',
              value: summary[AbsenceType.unpaid]!,
            ),
            
            const Divider(height: 24),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.leave_totalLeaveDays,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDays(_getTotalDays(summary)),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          _formatDays(value.days),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDays(double days) {
    if (days == 0) return '0 days';
    if (days == 1) return '1 day';
    if (days == days.truncate()) {
      return '${days.truncate()} days';
    }
    return '${days.toStringAsFixed(1)} days';
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
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.leave_recentLeaves,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (recentAbsences.isEmpty)
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.leave_noLeavesRecorded,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.leave_noLeavesDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...recentAbsences.map((absence) => _buildAbsenceCard(theme, colorScheme, absence)),
      ],
    );
  }

  Widget _buildAbsenceCard(ThemeData theme, ColorScheme colorScheme, AbsenceEntry absence) {
    final typeInfo = _getTypeInfo(absence.type);
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: typeInfo.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(typeInfo.icon, color: typeInfo.color, size: 24),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: typeInfo.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                absence.minutes == 0 
                    ? AppLocalizations.of(context)!.leave_fullDay
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

  _TypeInfo _getTypeInfo(AbsenceType type) {
    switch (type) {
      case AbsenceType.vacationPaid:
        return _TypeInfo(
          icon: Icons.beach_access,
          color: Colors.blue,
          label: 'Paid Vacation',
        );
      case AbsenceType.sickPaid:
        return _TypeInfo(
          icon: Icons.local_hospital,
          color: Colors.red,
          label: 'Sick Leave',
        );
      case AbsenceType.vabPaid:
        return _TypeInfo(
          icon: Icons.child_care,
          color: Colors.orange,
          label: 'VAB (Child Care)',
        );
      case AbsenceType.unpaid:
        return _TypeInfo(
          icon: Icons.event_busy,
          color: Colors.grey,
          label: 'Unpaid Leave',
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

  const _TypeInfo({required this.icon, required this.color, required this.label});
}
