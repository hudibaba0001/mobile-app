import 'package:flutter/material.dart';

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

  const TimeBalanceDashboard({
    super.key,
    required this.currentMonthHours,
    required this.currentYearHours,
    required this.yearlyBalance,
    required this.targetHours,
    required this.targetYearlyHours,
    required this.currentMonthName,
    required this.currentYear,
    this.creditHours,
    this.yearCreditHours,
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
        ),
        const SizedBox(height: 16),
        YearlyBalanceCard(
          year: currentYear,
          hoursWorked: currentYearHours,
          targetHours: targetYearlyHours,
          balance: yearlyBalance,
          creditHours: yearCreditHours,
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
    final positiveColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
    final warningColor = isDark ? Colors.amber.shade300 : Colors.amber.shade700;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'THIS WEEK: ${weekRange.toUpperCase()}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hours Worked (to date): ${hoursWorked.toStringAsFixed(1)} / ${targetHours.toStringAsFixed(1)} h',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isOverTarget ? Icons.check_circle : Icons.warning_amber_rounded,
                  size: 20,
                  color: isOverTarget ? positiveColor : warningColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: ${variance >= 0 ? '+' : ''}${variance.toStringAsFixed(1)} h (${isOverTarget ? 'Over' : 'Under'})',
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
              '${(progress * 100).toStringAsFixed(1)}% of target',
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
  final double? creditHours; // Optional: paid absence credits

  const MonthlyStatusCard({
    super.key,
    required this.monthName,
    required this.hoursWorked,
    required this.targetHours,
    this.creditHours,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Calculate effective hours including credits
    final effectiveHours = hoursWorked + (creditHours ?? 0.0);
    final variance = effectiveHours - targetHours;
    final isOverTarget = effectiveHours >= targetHours;
    // Guard against division by zero for future months
    final progress = targetHours > 0 ? (effectiveHours / targetHours) : 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    // Theme-aware colors
    final positiveColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
    final warningColor = isDark ? Colors.amber.shade300 : Colors.amber.shade700;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'THIS MONTH: ${monthName.toUpperCase()}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hours Worked (to date): ${hoursWorked.toStringAsFixed(1)} / ${targetHours.toStringAsFixed(1)} h',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (creditHours != null && creditHours! > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Credited Hours: ${creditHours!.toStringAsFixed(1)} h',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isOverTarget ? Icons.check_circle : Icons.warning_amber_rounded,
                  size: 20,
                  color: isOverTarget ? positiveColor : warningColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: ${variance >= 0 ? '+' : ''}${variance.toStringAsFixed(1)} h (${isOverTarget ? 'Over' : 'Under'})',
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
              '${(progress * 100).toStringAsFixed(1)}% of target',
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

/// Card displaying current year's work hours status
class YearlyStatusCard extends StatelessWidget {
  final int year;
  final double hoursWorked;
  final double targetHours;

  const YearlyStatusCard({
    super.key,
    required this.year,
    required this.hoursWorked,
    required this.targetHours,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final variance = hoursWorked - targetHours;
    final isOverTarget = hoursWorked >= targetHours;
    // Guard against division by zero for future years
    final progress = targetHours > 0 ? (hoursWorked / targetHours) : 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    // Theme-aware colors
    final positiveColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
    final warningColor = isDark ? Colors.amber.shade300 : Colors.amber.shade700;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'THIS YEAR: $year',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hours Worked (to date): ${hoursWorked.toStringAsFixed(1)} / ${targetHours.toStringAsFixed(1)} h',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isOverTarget ? Icons.check_circle : Icons.warning_amber_rounded,
                  size: 20,
                  color: isOverTarget ? positiveColor : warningColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: ${variance >= 0 ? '+' : ''}${variance.toStringAsFixed(1)} h (${isOverTarget ? 'Over' : 'Under'})',
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
              '${(progress * 100).toStringAsFixed(1)}% of target',
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

  const YearlyBalanceCard({
    super.key,
    required this.year,
    required this.hoursWorked,
    required this.targetHours,
    required this.balance,
    this.creditHours,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPositive = balance >= 0;
    final displayBalance = '${isPositive ? '+' : ''}${balance.toStringAsFixed(1)}h';
    // Calculate variance including credits: (actual + credit) - target
    final totalEffectiveHours = hoursWorked + (creditHours ?? 0.0);
    final variance = totalEffectiveHours - targetHours;
    final isOverTarget = totalEffectiveHours >= targetHours;
    // Guard against division by zero for future years
    final progress = targetHours > 0 ? (totalEffectiveHours / targetHours) : 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    // Theme-aware colors for dark/light mode
    final positiveColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
    final negativeColor = isDark ? Colors.red.shade300 : Colors.red.shade700;
    final warningColor = isDark ? Colors.amber.shade300 : Colors.amber.shade700;
    final cardBgColor = isDark
        ? (isPositive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15))
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
              'THIS YEAR: $year',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hours Worked (to date): ${hoursWorked.toStringAsFixed(1)} / ${targetHours.toStringAsFixed(1)} h',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (creditHours != null && creditHours! > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Credited Hours: ${creditHours!.toStringAsFixed(1)} h',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isOverTarget ? Icons.check_circle : Icons.warning_amber_rounded,
                  size: 20,
                  color: isOverTarget ? positiveColor : warningColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: ${variance >= 0 ? '+' : ''}${variance.toStringAsFixed(1)} h (${isOverTarget ? 'Over' : 'Under'})',
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
              '${(progress * 100).toStringAsFixed(1)}% of target',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outline.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'YEARLY RUNNING BALANCE',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Accumulation:',
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
                  color: isPositive
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isPositive
                        ? 'You are in credit'
                        : 'You maintain a time debt',
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
          ],
        ),
      ),
    );
  }
}

