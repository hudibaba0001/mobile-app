// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/time_provider.dart';
import '../providers/entry_provider.dart';
import '../providers/contract_provider.dart';
import '../widgets/time_balance_dashboard.dart';
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
    
    debugPrint('TimeBalanceScreen: Contract settings loaded - %: ${contractProvider.contractPercent}%, Full-time: ${contractProvider.fullTimeHours}h, Allowed: ${contractProvider.allowedHours}h');
    
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
            appBar: AppBar(title: Text(t.balance_title)),
            body: Center(
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
                    t.error_loadingBalance,
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
        
        // Get to-date values (month-to-date and year-to-date)
        final currentMonthHours = timeProvider.monthActualMinutesToDate(
          currentDate.year,
          currentDate.month,
        ) / 60.0;
        final currentYearHours = timeProvider.yearActualMinutesToDate(currentDate.year) / 60.0;
        final monthlyAdjustmentHours = timeProvider.monthlyAdjustmentHours(
          year: currentDate.year,
          month: currentDate.month,
        );
        final yearlyAdjustmentHours = timeProvider.totalYearAdjustmentHours;
        final openingBalanceHours = timeProvider.openingFlexHours;
        
        // Get to-date targets
        final monthlyTarget = timeProvider.monthTargetHoursToDate(
          year: currentDate.year,
          month: currentDate.month,
        );
        final yearlyTarget = timeProvider.yearTargetHoursToDate(year: currentDate.year);
        
        // Get credit hours to-date for current month
        final monthlyCredit = timeProvider.monthCreditMinutesToDate(
          currentDate.year,
          currentDate.month,
        ) / 60.0;
        
        // Get credit hours to-date for current year
        final yearlyCredit = timeProvider.yearCreditMinutesToDate(currentDate.year) / 60.0;
        
        // Use provider's running balance (includes credits, adjustments, opening balance)
        final yearlyBalanceToDate = timeProvider.yearlyRunningBalance;

        debugPrint('TimeBalanceScreen: Using contract settings - Weekly: ${contractProvider.weeklyTargetHours}h, Monthly: ${monthlyTarget.toStringAsFixed(1)}h, Yearly: ${yearlyTarget.toStringAsFixed(1)}h');
        debugPrint('TimeBalanceScreen: Contract %: ${contractProvider.contractPercent}%, Full-time hours: ${contractProvider.fullTimeHours}h');
        debugPrint('TimeBalanceScreen: Monthly credit: ${monthlyCredit.toStringAsFixed(1)}h, Yearly credit: ${yearlyCredit.toStringAsFixed(1)}h');
        debugPrint('TimeBalanceScreen: YTD Yearly balance: ${yearlyBalanceToDate.toStringAsFixed(1)}h');

        final t = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(t.balance_myTimeBalance(currentMonth.year)),
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
            padding: const EdgeInsets.all(16.0),
            child: TimeBalanceDashboard(
              currentMonthHours: currentMonthHours,
              currentYearHours: currentYearHours,
              yearlyBalance: yearlyBalanceToDate,
              targetHours: monthlyTarget,
              targetYearlyHours: yearlyTarget,
              currentMonthName: monthSummary?.monthName ?? 'Unknown',
              currentYear: currentMonth.year,
              creditHours: monthlyCredit > 0 ? monthlyCredit : null,
              yearCreditHours: yearlyCredit > 0 ? yearlyCredit : null,
              monthlyAdjustmentHours: monthlyAdjustmentHours,
              yearlyAdjustmentHours: yearlyAdjustmentHours,
              openingBalanceHours: openingBalanceHours,
              openingBalanceFormatted: timeProvider.hasOpeningBalance 
                  ? timeProvider.openingFlexFormatted 
                  : null,
              trackingStartDate: timeProvider.hasOpeningBalance || timeProvider.hasCustomTrackingStartDate
                  ? timeProvider.trackingStartDate 
                  : null,
            ),
          ),
        );
      },
    );
  }
}
