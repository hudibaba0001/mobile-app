import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/time_provider.dart';
import '../../providers/entry_provider.dart';
import '../../providers/contract_provider.dart';
import '../../widgets/time_balance_dashboard.dart';

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
                  'Error loading balance',
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
                  child: const Text('Retry'),
                ),
              ],
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
        
        // Calculate YTD yearly balance: actual + credit - target
        final yearlyBalanceToDate = (currentYearHours + yearlyCredit) - yearlyTarget;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
          ),
        );
      },
    );
  }
}

