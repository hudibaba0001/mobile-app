import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../design/app_theme.dart';
import '../../providers/time_provider.dart';
import '../../providers/entry_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/balance_adjustment_provider.dart';
import '../../reporting/time_format.dart';
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
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppLocalizations.of(context).error_loadingBalance,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  timeProvider.error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
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
        final localeCode = Localizations.localeOf(context).languageCode;

        // Get to-date values (month-to-date and year-to-date)
        final currentMonthMinutes = timeProvider.monthActualMinutesToDate(
          currentDate.year,
          currentDate.month,
        );
        final currentYearMinutes =
            timeProvider.yearActualMinutesToDate(currentDate.year);
        final monthlyAdjustmentMinutes = timeProvider.monthlyAdjustmentMinutes(
          year: currentDate.year,
          month: currentDate.month,
        );
        final yearlyAdjustmentMinutes =
            timeProvider.yearAdjustmentMinutesToDate(currentDate.year);

        // Get to-date targets (for variance/balance calculations)
        final monthlyTargetToDateMinutes = timeProvider.monthTargetMinutesToDate(
          year: currentDate.year,
          month: currentDate.month,
        );
        final yearlyTargetToDateMinutes =
            timeProvider.yearTargetMinutesToDate(currentDate.year);

        // Get full month/year targets (for display purposes)
        final fullMonthlyTargetMinutes = timeProvider.monthlyTargetMinutes(
          year: currentDate.year,
          month: currentDate.month,
        );
        final fullYearlyTargetMinutes =
            timeProvider.yearlyTargetMinutes(year: currentDate.year);

        // Get credit minutes to-date for current month/year
        final monthlyCreditMinutes = timeProvider.monthCreditMinutesToDate(
          currentDate.year,
          currentDate.month,
        );
        final yearlyCreditMinutes =
            timeProvider.yearCreditMinutesToDate(currentDate.year);

        final openingBalanceMinutes = contractProvider.openingFlexMinutes;

        // Use provider's year-only net balance in minutes (no opening balance)
        final yearNetMinutes = timeProvider.currentYearNetMinutes;

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
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TimeBalanceDashboard(
                currentMonthMinutes: currentMonthMinutes,
                currentYearMinutes: currentYearMinutes,
                yearNetMinutes: yearNetMinutes,
                // Don't pass contractBalance - let the card calculate
                // it as yearNet + opening balance in minutes.
                targetMinutes:
                    fullMonthlyTargetMinutes, // Full month target for display
                targetYearlyMinutes:
                    fullYearlyTargetMinutes, // Full year target for display
                targetMinutesToDate:
                    monthlyTargetToDateMinutes, // To-date target for variance
                targetYearlyMinutesToDate:
                    yearlyTargetToDateMinutes, // To-date target for variance
                currentMonthName: monthSummary?.monthName ?? t.common_unknown,
                currentYear: currentMonth.year,
                creditMinutes: monthlyCreditMinutes > 0 ? monthlyCreditMinutes : null,
                yearCreditMinutes: yearlyCreditMinutes > 0 ? yearlyCreditMinutes : null,
                monthlyAdjustmentMinutes: monthlyAdjustmentMinutes,
                yearlyAdjustmentMinutes: yearlyAdjustmentMinutes,
                openingBalanceMinutes: openingBalanceMinutes,
                openingBalanceFormatted: timeProvider.hasOpeningBalance
                    ? formatSignedMinutes(
                        openingBalanceMinutes,
                        localeCode: localeCode,
                        showPlusForZero: true,
                      )
                    : (showYearLoggedSince
                        ? formatSignedMinutes(
                            0,
                            localeCode: localeCode,
                            showPlusForZero: true,
                          )
                        : null),
                trackingStartDate: showYearLoggedSince || showMonthLoggedSince
                    ? timeProvider.trackingStartDate
                    : null,
                showYearLoggedSince: showYearLoggedSince,
                showMonthLoggedSince: showMonthLoggedSince,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Adjustments Section
              _buildAdjustmentsSection(
                context,
                recentAdjustments,
                yearlyAdjustmentMinutes,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdjustmentsSection(
    BuildContext context,
    List<dynamic> recentAdjustments,
    int totalAdjustmentMinutes,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy');

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
                  Icons.tune,
                  color: colorScheme.tertiary,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).adjustment_title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.tertiary,
                    ),
                  ),
                ),
                if (totalAdjustmentMinutes != 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md - 2,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: totalAdjustmentMinutes >= 0
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Text(
                      _formatSignedMinutes(context, totalAdjustmentMinutes),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: totalAdjustmentMinutes >= 0
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              AppLocalizations.of(context).adjustment_description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Add Adjustment Button
            OutlinedButton.icon(
              onPressed: () => _showAddAdjustmentDialog(context),
              icon: const Icon(Icons.add),
              label:
                  Text(AppLocalizations.of(context).adjustment_addAdjustment),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),

            if (recentAdjustments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppLocalizations.of(context).adjustment_recent,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
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
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isPositive
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                isPositive ? Icons.add : Icons.remove,
                size: 20,
                color: isPositive ? AppColors.success : AppColors.error,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adjustment.note ??
                        AppLocalizations.of(context).adjustment_title,
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
              _formatSignedMinutes(context, adjustment.deltaMinutes),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isPositive ? AppColors.success : AppColors.error,
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

  String _formatSignedMinutes(
    BuildContext context,
    int minutes, {
    bool showPlusForZero = false,
  }) {
    final localeCode = Localizations.localeOf(context).languageCode;
    return formatSignedMinutes(
      minutes,
      localeCode: localeCode,
      showPlusForZero: showPlusForZero,
    );
  }
}
