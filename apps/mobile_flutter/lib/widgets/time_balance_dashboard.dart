import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/generated/app_localizations.dart';

/// Dashboard widget for displaying time balance information
/// Shows current month status and yearly balance with Material 3 styling
class TimeBalanceDashboard extends StatelessWidget {
  final double currentMonthHours;
  final double currentYearHours;
  final double yearNetBalance; // Year-only balance (no opening balance)
  final double? contractBalance; // Optional: lifetime/contract balance with opening
  final double targetHours; // Full month target (for display)
  final double targetYearlyHours; // Full year target (for display)
  final double? targetHoursToDate; // Month target to date (for variance calculations)
  final double? targetYearlyHoursToDate; // Year target to date (for variance calculations)
  final String currentMonthName;
  final int currentYear;
  final double? creditHours; // Optional: paid absence credits for month
  final double? yearCreditHours; // Optional: paid absence credits for year
  final String? openingBalanceFormatted; // e.g., "+12h 30m" for opening balance
  final DateTime? trackingStartDate; // Date from which tracking started
  final double monthlyAdjustmentHours;
  final double yearlyAdjustmentHours;
  final double openingBalanceHours;
  final bool showYearLoggedSince; // Whether to show "Logged since..." for year card
  final bool showMonthLoggedSince; // Whether to show "Logged since..." for month card

  const TimeBalanceDashboard({
    super.key,
    required this.currentMonthHours,
    required this.currentYearHours,
    required this.yearNetBalance,
    required this.targetHours,
    required this.targetYearlyHours,
    required this.currentMonthName,
    required this.currentYear,
    required this.monthlyAdjustmentHours,
    required this.yearlyAdjustmentHours,
    required this.openingBalanceHours,
    this.contractBalance,
    this.targetHoursToDate,
    this.targetYearlyHoursToDate,
    this.creditHours,
    this.yearCreditHours,
    this.openingBalanceFormatted,
    this.trackingStartDate,
    this.showYearLoggedSince = false,
    this.showMonthLoggedSince = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonthlyStatusCard(
          monthName: currentMonthName,
          hoursWorked: currentMonthHours,
          targetHours: targetHours,
          targetHoursToDate: targetHoursToDate,
          creditHours: creditHours,
          adjustmentHours: monthlyAdjustmentHours,
          trackingStartDate: trackingStartDate,
          showLoggedSince: showMonthLoggedSince,
        ),
        const SizedBox(height: 16),
        YearlyBalanceCard(
          year: currentYear,
          hoursWorked: currentYearHours,
          targetHours: targetYearlyHours,
          targetHoursToDate: targetYearlyHoursToDate,
          yearNetBalance: yearNetBalance,
          contractBalance: contractBalance,
          creditHours: yearCreditHours,
          adjustmentHours: yearlyAdjustmentHours,
          openingBalanceHours: openingBalanceHours,
          openingBalanceFormatted: openingBalanceFormatted,
          trackingStartDate: trackingStartDate,
          showLoggedSince: showYearLoggedSince,
        ),
      ],
    );
  }
}

/// Card displaying current week's work hours status
class WeeklyStatusCard extends StatelessWidget {
  final String weekRange;
  final double hoursWorked;
  final double targetHours;

  const WeeklyStatusCard({
    super.key,
    required this.weekRange,
    required this.hoursWorked,
    required this.targetHours,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final variance = hoursWorked - targetHours;
    final isOverTarget = hoursWorked >= targetHours;
    // Guard against division by zero for future weeks
    final progress = targetHours > 0 ? (hoursWorked / targetHours) : 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    // Theme-aware colors
    final positiveColor =
        isDark ? Colors.green.shade300 : Colors.green.shade700;
    final warningColor = isDark ? Colors.amber.shade300 : Colors.amber.shade700;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)
                  .balance_thisWeek(weekRange.toUpperCase()),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).balance_hoursWorked(
                hoursWorked.toStringAsFixed(1),
                targetHours.toStringAsFixed(1),
              ),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isOverTarget
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  size: 20,
                  color: isOverTarget ? positiveColor : warningColor,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).balance_status(
                    '${variance >= 0 ? '+' : ''}${variance.toStringAsFixed(1)}',
                    isOverTarget
                        ? AppLocalizations.of(context).balance_over
                        : AppLocalizations.of(context).balance_under,
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isOverTarget ? positiveColor : warningColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: clampedProgress,
                minHeight: 12,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverTarget ? positiveColor : warningColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)
                  .balance_percentOfTarget((progress * 100).toStringAsFixed(1)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card displaying current month's work hours status
class MonthlyStatusCard extends StatelessWidget {
  final String monthName;
  final double hoursWorked;
  final double targetHours; // Full month target (for display)
  final double? targetHoursToDate; // Target to date (for variance calculations)
  final double adjustmentHours;
  final double? creditHours; // Optional: paid absence credits
  final DateTime? trackingStartDate; // Date from which tracking started
  final bool showLoggedSince; // Whether to show "Logged since..." label

  const MonthlyStatusCard({
    super.key,
    required this.monthName,
    required this.hoursWorked,
    required this.targetHours,
    required this.adjustmentHours,
    this.targetHoursToDate,
    this.creditHours,
    this.trackingStartDate,
    this.showLoggedSince = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Calculate effective hours including credits and adjustments
    final effectiveHours =
        hoursWorked + (creditHours ?? 0.0) + adjustmentHours;
    // Use targetHoursToDate for variance (balance) calculation if available
    final targetForVariance = targetHoursToDate ?? targetHours;
    final variance = effectiveHours - targetForVariance;
    final isOverTarget = variance >= 0;
    // Use full targetHours for progress bar (shows progress toward monthly goal)
    final progress = targetHours > 0 ? (effectiveHours / targetHours) : 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    // Theme-aware colors
    final positiveColor =
        isDark ? Colors.green.shade300 : Colors.green.shade700;
    final negativeColor = isDark ? Colors.red.shade300 : Colors.red.shade700;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title: "This month: February"
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'This month: $monthName',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Line 1 (PRIMARY): Status (to date)
            Row(
              children: [
                Text(
                  'Status (to date): ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${variance > 0 ? '+' : ''}${variance.toStringAsFixed(1)}h',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isOverTarget ? positiveColor : negativeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Line 2: Worked (to date): X.Xh / Y.Yh
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                children: [
                  const TextSpan(text: 'Worked (to date): '),
                  TextSpan(
                    text: '${effectiveHours.toStringAsFixed(1)}h',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const TextSpan(text: ' / '),
                  TextSpan(
                    text: '${targetForVariance.toStringAsFixed(1)}h',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Line 3 (small): Full month target: XXXh
            Text(
              'Full month target: ${targetHours.toStringAsFixed(0)}h',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),

            // Show credits and adjustments if any
            if (creditHours != null && creditHours! > 0) ...[
              const SizedBox(height: 6),
              Text(
                '+ ${creditHours!.toStringAsFixed(1)}h credited (paid leave)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (adjustmentHours != 0) ...[
              const SizedBox(height: 4),
              Text(
                '${adjustmentHours >= 0 ? '+' : ''}${adjustmentHours.toStringAsFixed(1)}h manual adjustments',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Show "Logged since..." when tracking started mid-month
            if (showLoggedSince && trackingStartDate != null) ...[
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).balance_loggedSince(
                  DateFormat('d MMM').format(trackingStartDate!),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Progress bar for month
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: clampedProgress,
                minHeight: 12,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverTarget ? positiveColor : negativeColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% of full month target',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card displaying yearly balance
/// Primary: "Balance Today" (includes opening balance)
/// Secondary: "Net This Year" (from logged hours only)
class YearlyBalanceCard extends StatefulWidget {
  final int year;
  final double hoursWorked;
  final double targetHours; // Full year target (for display)
  final double? targetHoursToDate; // Year target to date (for variance calculations)
  final double yearNetBalance; // Year-only balance (worked - target + adjustments, NO opening)
  final double? contractBalance; // Balance including opening (for verification)
  final double? creditHours; // Optional: paid absence credits
  final double adjustmentHours;
  final double openingBalanceHours;
  final String? openingBalanceFormatted; // e.g., "+12h 30m" or "-3h 15m"
  final DateTime? trackingStartDate; // Date from which tracking started
  final bool showLoggedSince; // Whether to show "Logged since..." label prominently

  const YearlyBalanceCard({
    super.key,
    required this.year,
    required this.hoursWorked,
    required this.targetHours,
    required this.yearNetBalance,
    required this.adjustmentHours,
    required this.openingBalanceHours,
    this.targetHoursToDate,
    this.contractBalance,
    this.creditHours,
    this.openingBalanceFormatted,
    this.trackingStartDate,
    this.showLoggedSince = false,
  });

  @override
  State<YearlyBalanceCard> createState() => _YearlyBalanceCardState();
}

class _YearlyBalanceCardState extends State<YearlyBalanceCard> {
  bool _showDetails = false;

  Widget _buildBreakdownRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isPositive,
    required Color positiveColor,
    required Color negativeColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isPositive ? positiveColor : negativeColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // PRIMARY: Balance Today = yearNetBalance + openingBalanceHours
    // This is what the user cares about: their actual flex balance right now
    final balanceToday = widget.contractBalance ??
        (widget.yearNetBalance + widget.openingBalanceHours);
    final isPositive = balanceToday >= 0;
    final displayBalance =
        '${isPositive ? '+' : ''}${balanceToday.toStringAsFixed(1)}h';

    // Status reflects balanceToday (the real balance)
    final isOverTarget = balanceToday >= 0;

    // Use target-to-date for display and progress when available
    final targetForDisplay = widget.targetHoursToDate ?? widget.targetHours;
    final progress = targetForDisplay > 0
        ? (widget.hoursWorked / targetForDisplay)
        : 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    // Theme-aware colors
    final positiveColor =
        isDark ? Colors.green.shade300 : Colors.green.shade700;
    final negativeColor = isDark ? Colors.red.shade300 : Colors.red.shade700;
    final warningColor = isDark ? Colors.amber.shade300 : Colors.amber.shade700;
    final cardBgColor = isDark
        ? (isPositive
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.red.withValues(alpha: 0.15))
        : (isPositive ? Colors.green.shade50 : Colors.red.shade50);
    final borderColor = isDark
        ? (isPositive ? Colors.green.shade700 : Colors.red.shade700)
        : (isPositive ? Colors.green.shade200 : Colors.red.shade200);

    // Show details if there's an opening balance OR adjustments to explain
    final hasDetails = widget.openingBalanceHours != 0 || widget.adjustmentHours != 0;

    return Card(
      elevation: 0,
      color: cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: THIS YEAR 2026
            Text(
              l10n.balance_thisYear(widget.year),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            
            // Worked (to date): X.Xh / Y.Yh
            RichText(
              text: TextSpan(
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                children: [
                  const TextSpan(text: 'Worked (to date): '),
                  TextSpan(
                    text: '${(widget.hoursWorked + (widget.creditHours ?? 0.0) + widget.adjustmentHours).toStringAsFixed(1)}h',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const TextSpan(text: ' / '),
                  TextSpan(
                    text: '${targetForDisplay.toStringAsFixed(1)}h',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Full year target
            Text(
              'Full year target: ${widget.targetHours.toStringAsFixed(0)}h',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),

            // Show "Logged since..." prominently when tracking started after Jan 1
            if (widget.showLoggedSince && widget.trackingStartDate != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.balance_loggedSince(
                            DateFormat('d MMM').format(widget.trackingStartDate!),
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Show starting balance if there is one
                    if (widget.openingBalanceFormatted != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.balance_startingBalanceAsOf(
                          DateFormat('d MMM').format(widget.trackingStartDate!),
                          widget.openingBalanceFormatted!,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Credit hours if any (informational)
            if (widget.creditHours != null && widget.creditHours! > 0) ...[
              const SizedBox(height: 4),
              Text(
                l10n.balance_creditedHours(widget.creditHours!.toStringAsFixed(1)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],

            // Adjustments if any
            if (widget.adjustmentHours != 0) ...[
              const SizedBox(height: 4),
              Text(
                'Includes adjustments: '
                '${widget.adjustmentHours >= 0 ? '+' : ''}${widget.adjustmentHours.toStringAsFixed(1)}h',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 8),
            
            // Balance today (avoid "Status" wording)
            Row(
              children: [
                Icon(
                  isOverTarget ? Icons.check_circle : Icons.error_outline,
                  size: 20,
                  color: isOverTarget ? positiveColor : negativeColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${l10n.balance_balanceToday}: $displayBalance',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isOverTarget ? positiveColor : negativeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: clampedProgress,
                minHeight: 12,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverTarget ? positiveColor : warningColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.balance_percentOfTarget((progress * 100).toStringAsFixed(1)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            const SizedBox(height: 16),

            // PRIMARY: Balance Today - the main number users care about
            Text(
              l10n.balance_balanceToday,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayBalance,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isPositive ? positiveColor : negativeColor,
              ),
            ),

            // SECONDARY: Show Net This Year (logged hours only) when there's an opening balance
            if (widget.openingBalanceHours != 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.balance_netThisYear(
                      '${widget.yearNetBalance >= 0 ? '+' : ''}${widget.yearNetBalance.toStringAsFixed(1)}h',
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.balance_startingBalanceValue(
                      widget.openingBalanceFormatted ?? '${widget.openingBalanceHours >= 0 ? '+' : ''}${widget.openingBalanceHours.toStringAsFixed(1)}h',
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),
            Text(
              l10n.balance_resetsOn('31 Dec'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),

            // Collapsible Details section - breakdown of balance components
            if (hasDetails) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setState(() => _showDetails = !_showDetails),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _showDetails ? Icons.expand_less : Icons.expand_more,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.balance_details,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_showDetails) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.balance_breakdown,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Starting balance row
                      if (widget.openingBalanceHours != 0) ...[
                        _buildBreakdownRow(
                          context,
                          icon: Icons.account_balance_wallet,
                          label: widget.trackingStartDate != null
                              ? l10n.balance_startingBalanceAsOf(
                                  DateFormat('d MMM').format(widget.trackingStartDate!),
                                  '',
                                ).replaceAll(': ', '')
                              : l10n.balance_startingBalance,
                          value: widget.openingBalanceFormatted ??
                              '${widget.openingBalanceHours >= 0 ? '+' : ''}${widget.openingBalanceHours.toStringAsFixed(1)}h',
                          isPositive: widget.openingBalanceHours >= 0,
                          positiveColor: positiveColor,
                          negativeColor: negativeColor,
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Net this year row
                      _buildBreakdownRow(
                        context,
                        icon: Icons.analytics,
                        label: l10n.balance_netThisYearLabel,
                        value: '${widget.yearNetBalance >= 0 ? '+' : ''}${widget.yearNetBalance.toStringAsFixed(1)}h',
                        isPositive: widget.yearNetBalance >= 0,
                        positiveColor: positiveColor,
                        negativeColor: negativeColor,
                      ),

                      // Adjustments row (if any)
                      if (widget.adjustmentHours != 0) ...[
                        const SizedBox(height: 8),
                        _buildBreakdownRow(
                          context,
                          icon: Icons.tune,
                          label: l10n.balance_adjustments,
                          value: '${widget.adjustmentHours >= 0 ? '+' : ''}${widget.adjustmentHours.toStringAsFixed(1)}h',
                          isPositive: widget.adjustmentHours >= 0,
                          positiveColor: positiveColor,
                          negativeColor: negativeColor,
                        ),
                      ],

                      const SizedBox(height: 12),
                      Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),

                      // Total row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.balance_balanceToday,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            displayBalance,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isPositive ? positiveColor : negativeColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
