import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/generated/app_localizations.dart';

/// Dashboard widget for displaying time balance information
/// Shows current month status and yearly running balance with Material 3 styling
class TimeBalanceDashboard extends StatelessWidget {
  final double currentMonthHours;
  final double currentYearHours;
  final double yearlyBalance;
  final double targetHours;
  final double targetYearlyHours;
  final String currentMonthName;
  final int currentYear;
  final double? creditHours; // Optional: paid absence credits for month
  final double? yearCreditHours; // Optional: paid absence credits for year
  final String? openingBalanceFormatted; // e.g., "+12h 30m" for opening balance
  final DateTime? trackingStartDate; // Date from which tracking started
  final double monthlyAdjustmentHours;
  final double yearlyAdjustmentHours;
  final double openingBalanceHours;

  const TimeBalanceDashboard({
    super.key,
    required this.currentMonthHours,
    required this.currentYearHours,
    required this.yearlyBalance,
    required this.targetHours,
    required this.targetYearlyHours,
    required this.currentMonthName,
    required this.currentYear,
    required this.monthlyAdjustmentHours,
    required this.yearlyAdjustmentHours,
    required this.openingBalanceHours,
    this.creditHours,
    this.yearCreditHours,
    this.openingBalanceFormatted,
    this.trackingStartDate,
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
          creditHours: creditHours,
          adjustmentHours: monthlyAdjustmentHours,
        ),
        const SizedBox(height: 16),
        YearlyBalanceCard(
          year: currentYear,
          hoursWorked: currentYearHours,
          targetHours: targetYearlyHours,
          balance: yearlyBalance,
          creditHours: yearCreditHours,
          adjustmentHours: yearlyAdjustmentHours,
          openingBalanceHours: openingBalanceHours,
          openingBalanceFormatted: openingBalanceFormatted,
          trackingStartDate: trackingStartDate,
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
  final double targetHours;
  final double adjustmentHours;
  final double? creditHours; // Optional: paid absence credits

  const MonthlyStatusCard({
    super.key,
    required this.monthName,
    required this.hoursWorked,
    required this.targetHours,
    required this.adjustmentHours,
    this.creditHours,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Calculate effective hours including credits and adjustments
    final effectiveHours =
        hoursWorked + (creditHours ?? 0.0) + adjustmentHours;
    final variance = effectiveHours - targetHours;
    final isOverTarget = variance >= 0;
    // Guard against division by zero for future months
    final progress = targetHours > 0 ? (effectiveHours / targetHours) : 0.0;
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
                  .balance_thisMonth(monthName.toUpperCase()),
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
            if (creditHours != null && creditHours! > 0) ...[
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)
                    .balance_creditedHours(creditHours!.toStringAsFixed(1)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            if (adjustmentHours != 0) ...[
              const SizedBox(height: 4),
              Text(
                'Includes adjustments: '
                '${adjustmentHours >= 0 ? '+' : ''}${adjustmentHours.toStringAsFixed(1)}h',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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

/// Card displaying yearly running balance
class YearlyBalanceCard extends StatelessWidget {
  final int year;
  final double hoursWorked;
  final double targetHours;
  final double balance;
  final double? creditHours; // Optional: paid absence credits
  final double adjustmentHours;
  final double openingBalanceHours;
  final String? openingBalanceFormatted; // e.g., "+12h 30m" or "-3h 15m"
  final DateTime? trackingStartDate; // Date from which tracking started

  const YearlyBalanceCard({
    super.key,
    required this.year,
    required this.hoursWorked,
    required this.targetHours,
    required this.balance,
    required this.adjustmentHours,
    required this.openingBalanceHours,
    this.creditHours,
    this.openingBalanceFormatted,
    this.trackingStartDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPositive = balance >= 0;
    final displayBalance = '${isPositive ? '+' : ''}${balance.toStringAsFixed(1)}h';
    // Calculate variance including credits, adjustments, and opening balance
    final totalEffectiveHours =
        hoursWorked + (creditHours ?? 0.0) + adjustmentHours + openingBalanceHours;
    final variance = totalEffectiveHours - targetHours;
    final isOverTarget = variance >= 0;
    // Guard against division by zero for future years
    final progress =
        targetHours > 0 ? (totalEffectiveHours / targetHours) : 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    // Theme-aware colors for dark/light mode
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
            Text(
              AppLocalizations.of(context).balance_thisYear(year),
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
            if (creditHours != null && creditHours! > 0) ...[
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)
                    .balance_creditedHours(creditHours!.toStringAsFixed(1)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            if (adjustmentHours != 0 || openingBalanceHours != 0) ...[
              const SizedBox(height: 4),
              Text(
                'Includes adjustments${openingBalanceHours != 0 ? " & opening balance" : ""}: '
                '${adjustmentHours >= 0 ? '+' : ''}${adjustmentHours.toStringAsFixed(1)}h'
                '${openingBalanceHours != 0 ? ' / Opening ${openingBalanceHours >= 0 ? '+' : ''}${openingBalanceHours.toStringAsFixed(1)}h' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).balance_yearlyRunningBalance,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).balance_totalAccumulation,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.check_circle : Icons.error,
                  color:
                      isPositive ? Colors.green.shade700 : Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isPositive
                        ? AppLocalizations.of(context).balance_inCredit
                        : AppLocalizations.of(context).balance_timeDebt,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isPositive
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            // Opening balance note
            if (openingBalanceFormatted != null &&
                openingBalanceFormatted!.isNotEmpty) ...[
              const SizedBox(height: 16),
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
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trackingStartDate != null
                            ? AppLocalizations.of(context)
                                .balance_includesOpeningBalance(
                                openingBalanceFormatted!,
                                DateFormat('MMM d, yyyy')
                                    .format(trackingStartDate!),
                              )
                            : AppLocalizations.of(context)
                                .balance_includesOpeningBalanceShort(
                                    openingBalanceFormatted!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}






