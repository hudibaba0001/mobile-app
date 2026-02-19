// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design/app_theme.dart';
import '../providers/time_provider.dart';
import '../providers/entry_provider.dart';
import '../providers/contract_provider.dart';
import '../reporting/time_format.dart';
import '../widgets/time_balance_dashboard.dart';
import '../widgets/standard_app_bar.dart';
import '../l10n/generated/app_localizations.dart';
import '../config/app_router.dart';

/// Screen that displays the time balance dashboard
/// Loads data from TimeProvider and displays weekly, monthly, and yearly balances
class TimeBalanceScreen extends StatefulWidget {
  const TimeBalanceScreen({super.key});

  @override
  State<TimeBalanceScreen> createState() => _TimeBalanceScreenState();
}

class _TimeBalanceScreenState extends State<TimeBalanceScreen> {
  @override
  void initState() {
    super.initState();
    // Load balances when screen is opened
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

    debugPrint(
        'TimeBalanceScreen: Contract settings loaded - %: ${contractProvider.contractPercent}%, Full-time: ${contractProvider.fullTimeHours}h, Allowed: ${contractProvider.allowedHours}h');

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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (timeProvider.error != null) {
          final t = AppLocalizations.of(context);
          return Scaffold(
            appBar: StandardAppBar(title: t.balance_title),
            body: Center(
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
                    t.error_loadingBalance,
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
                    child: Text(t.common_retry),
                  ),
                ],
              ),
            ),
          );
        }

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
        final openingBalanceMinutes = contractProvider.openingFlexMinutes;

        // Get to-date targets (for variance calculations)
        final monthlyTargetToDateMinutes = timeProvider.monthTargetMinutesToDate(
          currentDate.year,
          currentDate.month,
        );
        final yearlyTargetToDateMinutes =
            timeProvider.yearTargetMinutesToDate(currentDate.year);

        // Get full month/year targets (for display)
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

        // Year-only net balance (no opening balance) - primary display.
        final yearNetMinutes = timeProvider.currentYearNetMinutes;
        // Contract balance includes opening balance (for Details section).
        final contractBalanceMinutes = yearNetMinutes + openingBalanceMinutes;

        debugPrint(
            'TimeBalanceScreen: Using contract settings - Weekly: ${contractProvider.weeklyTargetHours}h, Monthly: ${(fullMonthlyTargetMinutes / 60.0).toStringAsFixed(1)}h, Yearly: ${(fullYearlyTargetMinutes / 60.0).toStringAsFixed(1)}h');
        debugPrint(
            'TimeBalanceScreen: Contract %: ${contractProvider.contractPercent}%, Full-time hours: ${contractProvider.fullTimeHours}h');
        debugPrint(
            'TimeBalanceScreen: Monthly credit: ${(monthlyCreditMinutes / 60.0).toStringAsFixed(1)}h, Yearly credit: ${(yearlyCreditMinutes / 60.0).toStringAsFixed(1)}h');
        debugPrint(
            'TimeBalanceScreen: Year net balance: ${(yearNetMinutes / 60.0).toStringAsFixed(1)}h (contract: ${(contractBalanceMinutes / 60.0).toStringAsFixed(1)}h)');

        final t = AppLocalizations.of(context);
        return Scaffold(
          appBar: StandardAppBar(
            title: t.balance_myTimeBalance(currentMonth.year),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  AppRouter.goToContractSettings(context);
                },
                tooltip: t.settings_title,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TimeBalanceDashboard(
              currentMonthMinutes: currentMonthMinutes,
              currentYearMinutes: currentYearMinutes,
              yearNetMinutes: yearNetMinutes,
              contractBalanceMinutes: contractBalanceMinutes,
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
              creditMinutes:
                  monthlyCreditMinutes > 0 ? monthlyCreditMinutes : null,
              yearCreditMinutes:
                  yearlyCreditMinutes > 0 ? yearlyCreditMinutes : null,
              monthlyAdjustmentMinutes: monthlyAdjustmentMinutes,
              yearlyAdjustmentMinutes: yearlyAdjustmentMinutes,
              openingBalanceMinutes: openingBalanceMinutes,
              openingBalanceFormatted: timeProvider.hasOpeningBalance
                  ? formatSignedMinutes(
                      openingBalanceMinutes,
                      localeCode: localeCode,
                      showPlusForZero: true,
                    )
                  : null,
              trackingStartDate: timeProvider.hasOpeningBalance ||
                      timeProvider.hasCustomTrackingStartDate
                  ? timeProvider.trackingStartDate
                  : null,
            ),
          ),
        );
      },
    );
  }
}

