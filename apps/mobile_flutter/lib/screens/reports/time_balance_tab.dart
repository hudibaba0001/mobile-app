import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/time_provider.dart';
import '../../providers/entry_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/balance_adjustment_provider.dart';
import '../../widgets/time_balance_dashboard.dart';
import '../../widgets/add_adjustment_dialog.dart';
import '../../l10n/generated/app_localizations.dart';

class TimeBalanceTab extends StatefulWidget {
  const TimeBalanceTab({super.key});

  @override
  State<TimeBalanceTab> createState() => _TimeBalanceTabState();
}

class _TimeBalanceTabState extends State<TimeBalanceTab> {
  @override
  void initState() {
    super.initState();
    // Load balances when tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBalances();
    });
  }

  Future<void> _loadBalances() async {
    final timeProvider = context.read<TimeProvider>();
    final entryProvider = context.read<EntryProvider>();
    final contractProvider = context.read<ContractProvider>();

    // Initialize contract provider if needed (loads saved settings)
    await contractProvider.init();

    // Make sure entries are loaded first
    if (entryProvider.entries.isEmpty) {
      await entryProvider.loadEntries();
    }

    // Calculate balances (will use contract settings automatically)
    await timeProvider.calculateBalances();

    // Force UI refresh
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<TimeProvider, EntryProvider, ContractProvider>(
      builder: (context, timeProvider, entryProvider, contractProvider, _) {
        if (timeProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (timeProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).error_loadingBalance,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  timeProvider.error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadBalances,
                  child: Text(AppLocalizations.of(context).common_retry),
                ),
              ],
            ),
          );
        }

        final t = AppLocalizations.of(context);

        // Get current month summary
        final currentMonth = DateTime.now();
        final monthSummary = timeProvider.getCurrentMonthSummary();

        final currentDate = DateTime.now();

        // Get to-date values (month-to-date and year-to-date)
        final currentMonthHours = timeProvider.monthActualMinutesToDate(
              currentDate.year,
              currentDate.month,
            ) /
            60.0;
        final currentYearHours =
            timeProvider.yearActualMinutesToDate(currentDate.year) / 60.0;
        final monthlyAdjustmentHours = timeProvider.monthlyAdjustmentHours(
          year: currentDate.year,
          month: currentDate.month,
        );
        final yearlyAdjustmentHours = timeProvider.totalYearAdjustmentHours;

        // Get to-date targets (for variance/balance calculations)
        final monthlyTargetToDate = timeProvider.monthTargetHoursToDate(
          year: currentDate.year,
          month: currentDate.month,
        );
        final yearlyTargetToDate =
            timeProvider.yearTargetHoursToDate(year: currentDate.year);

        // Get full month/year targets (for display purposes)
        final fullMonthlyTarget = timeProvider.monthlyTargetHours(
          year: currentDate.year,
          month: currentDate.month,
        );
        final fullYearlyTarget =
            timeProvider.yearlyTargetHours(year: currentDate.year);

        // Get credit hours to-date for current month
        final monthlyCredit = timeProvider.monthCreditMinutesToDate(
              currentDate.year,
              currentDate.month,
            ) /
            60.0;

        // Get credit hours to-date for current year
        final yearlyCredit =
            timeProvider.yearCreditMinutesToDate(currentDate.year) / 60.0;
        final openingBalanceHours = timeProvider.openingFlexHours;

        // Use provider's year-only net balance (no opening balance)
        final yearNetBalance = timeProvider.currentYearNetBalance;

        // Determine if we should show "Logged since..." labels
        final showYearLoggedSince =
            timeProvider.isTrackingStartAfterYearStart(currentDate.year);
        final showMonthLoggedSince = timeProvider.isTrackingStartInMonth(
            currentDate.year, currentDate.month);

        // Get recent adjustments
        final adjustmentProvider = context.watch<BalanceAdjustmentProvider>();
        final recentAdjustments =
            adjustmentProvider.allAdjustments.take(5).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TimeBalanceDashboard(
                currentMonthHours: currentMonthHours,
                currentYearHours: currentYearHours,
                yearNetBalance: yearNetBalance,
                // Don't pass contractBalance - let the card calculate it as yearNetBalance + openingBalanceHours
                targetHours: fullMonthlyTarget, // Full month target for display
                targetYearlyHours:
                    fullYearlyTarget, // Full year target for display
                targetHoursToDate:
                    monthlyTargetToDate, // To-date target for variance
                targetYearlyHoursToDate:
                    yearlyTargetToDate, // To-date target for variance
                currentMonthName: monthSummary?.monthName ?? t.common_unknown,
                currentYear: currentMonth.year,
                creditHours: monthlyCredit > 0 ? monthlyCredit : null,
                yearCreditHours: yearlyCredit > 0 ? yearlyCredit : null,
                monthlyAdjustmentHours: monthlyAdjustmentHours,
                yearlyAdjustmentHours: yearlyAdjustmentHours,
                openingBalanceHours: openingBalanceHours,
                openingBalanceFormatted: timeProvider.hasOpeningBalance
                    ? timeProvider.openingFlexFormatted
                    : (showYearLoggedSince ? '+0h' : null),
                trackingStartDate: showYearLoggedSince || showMonthLoggedSince
                    ? timeProvider.trackingStartDate
                    : null,
                showYearLoggedSince: showYearLoggedSince,
                showMonthLoggedSince: showMonthLoggedSince,
              ),

              const SizedBox(height: 24),

              // Adjustments Section
              _buildAdjustmentsSection(
                  context, recentAdjustments, yearlyAdjustmentHours),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdjustmentsSection(
    BuildContext context,
    List<dynamic> recentAdjustments,
    double totalAdjustmentHours,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: colorScheme.tertiary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).adjustment_title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.tertiary,
                    ),
                  ),
                ),
                if (totalAdjustmentHours != 0) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: totalAdjustmentHours >= 0
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${totalAdjustmentHours >= 0 ? '+' : ''}${totalAdjustmentHours.toStringAsFixed(1)}h',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: totalAdjustmentHours >= 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            Text(
              AppLocalizations.of(context).adjustment_description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            // Add Adjustment Button
            OutlinedButton.icon(
              onPressed: () => _showAddAdjustmentDialog(context),
              icon: const Icon(Icons.add),
              label:
                  Text(AppLocalizations.of(context).adjustment_addAdjustment),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            if (recentAdjustments.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).adjustment_recent,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              ...recentAdjustments.map((adjustment) {
                return _buildAdjustmentItem(
                  context,
                  adjustment,
                  dateFormat,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentItem(
    BuildContext context,
    dynamic adjustment,
    DateFormat dateFormat,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPositive = adjustment.deltaMinutes >= 0;

    return InkWell(
      onTap: () => _showEditAdjustmentDialog(context, adjustment),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPositive
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPositive ? Icons.add : Icons.remove,
                size: 20,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adjustment.note ?? AppLocalizations.of(context).adjustment_title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dateFormat.format(adjustment.effectiveDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              adjustment.deltaFormatted,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddAdjustmentDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddAdjustmentDialog(),
    );

    if (result == true && mounted) {
      // Refresh balances
      await _loadBalances();
    }
  }

  Future<void> _showEditAdjustmentDialog(
      BuildContext context, dynamic adjustment) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddAdjustmentDialog(existingAdjustment: adjustment),
    );

    if (result == true && mounted) {
      // Refresh balances
      await _loadBalances();
    }
  }
}
