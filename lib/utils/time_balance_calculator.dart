import '../models/monthly_summary.dart';
import '../models/weekly_summary.dart';

/// Utility class for calculating time balance and yearly running totals
class TimeBalanceCalculator {
  /// Calculate yearly running balance from monthly summaries
  /// 
  /// Iterates through months chronologically and calculates:
  /// - Monthly variance = actualWorkedHours - targetHours
  /// - Cumulative yearly balance (running sum of variances)
  /// 
  /// [monthlySummaries] List of MonthlySummary objects, should be sorted chronologically
  /// [targetHours] Target hours per month (default: 160)
  /// 
  /// Returns the cumulative yearly balance (positive = credit, negative = debt)
  static double calculateYearlyBalance(
    List<MonthlySummary> monthlySummaries, {
    double targetHours = 160.0,
  }) {
    // Sort by year and month to ensure chronological order
    final sorted = List<MonthlySummary>.from(monthlySummaries)
      ..sort((a, b) {
        final yearCompare = a.year.compareTo(b.year);
        if (yearCompare != 0) return yearCompare;
        return a.month.compareTo(b.month);
      });

    double cumulativeYearlyBalance = 0.0;

    for (final summary in sorted) {
      // Calculate monthly variance
      final monthlyVariance = summary.actualWorkedHours - targetHours;
      
      // Add to running sum
      cumulativeYearlyBalance += monthlyVariance;
    }

    return cumulativeYearlyBalance;
  }

  /// Calculate monthly variance for a specific month
  /// 
  /// [actualWorkedHours] Hours actually worked in the month
  /// [targetHours] Target hours for the month (default: 160)
  /// 
  /// Returns the variance (positive = over, negative = under)
  static double calculateMonthlyVariance(
    double actualWorkedHours, {
    double targetHours = 160.0,
  }) {
    return actualWorkedHours - targetHours;
  }

  /// Get detailed breakdown of monthly variances and cumulative balance
  /// 
  /// Returns a map with:
  /// - 'yearlyBalance': cumulative balance
  /// - 'monthlyVariances': list of variances per month
  /// - 'cumulativeBalances': list of cumulative balances after each month
  static Map<String, dynamic> calculateDetailedBalance(
    List<MonthlySummary> monthlySummaries, {
    double targetHours = 160.0,
  }) {
    final sorted = List<MonthlySummary>.from(monthlySummaries)
      ..sort((a, b) {
        final yearCompare = a.year.compareTo(b.year);
        if (yearCompare != 0) return yearCompare;
        return a.month.compareTo(b.month);
      });

    double cumulativeYearlyBalance = 0.0;
    final List<Map<String, dynamic>> monthlyVariances = [];
    final List<double> cumulativeBalances = [];

    for (final summary in sorted) {
      final monthlyVariance = summary.actualWorkedHours - targetHours;
      cumulativeYearlyBalance += monthlyVariance;

      monthlyVariances.add({
        'month': summary.monthName,
        'year': summary.year,
        'actualHours': summary.actualWorkedHours,
        'targetHours': targetHours,
        'variance': monthlyVariance,
      });

      cumulativeBalances.add(cumulativeYearlyBalance);
    }

    return {
      'yearlyBalance': cumulativeYearlyBalance,
      'monthlyVariances': monthlyVariances,
      'cumulativeBalances': cumulativeBalances,
    };
  }

  /// Calculate yearly running balance from weekly summaries
  /// 
  /// Iterates through weeks chronologically and calculates:
  /// - Weekly variance = actualWorkedHours - targetHours
  /// - Cumulative yearly balance (running sum of variances)
  /// 
  /// [weeklySummaries] List of WeeklySummary objects, should be sorted chronologically
  /// [targetHours] Target hours per week (default: 40)
  /// 
  /// Returns the cumulative yearly balance (positive = credit, negative = debt)
  static double calculateYearlyBalanceFromWeeks(
    List<WeeklySummary> weeklySummaries, {
    double targetHours = 40.0,
  }) {
    // Sort by year, week number, and week start to ensure chronological order
    final sorted = List<WeeklySummary>.from(weeklySummaries)
      ..sort((a, b) {
        final yearCompare = a.year.compareTo(b.year);
        if (yearCompare != 0) return yearCompare;
        final weekCompare = a.weekNumber.compareTo(b.weekNumber);
        if (weekCompare != 0) return weekCompare;
        return a.weekStart.compareTo(b.weekStart);
      });

    double cumulativeYearlyBalance = 0.0;

    for (final summary in sorted) {
      // Calculate weekly variance
      final weeklyVariance = summary.actualWorkedHours - targetHours;
      
      // Add to running sum
      cumulativeYearlyBalance += weeklyVariance;
    }

    return cumulativeYearlyBalance;
  }

  /// Calculate weekly variance for a specific week
  /// 
  /// [actualWorkedHours] Hours actually worked in the week
  /// [targetHours] Target hours for the week (default: 40)
  /// 
  /// Returns the variance (positive = over, negative = under)
  static double calculateWeeklyVariance(
    double actualWorkedHours, {
    double targetHours = 40.0,
  }) {
    return actualWorkedHours - targetHours;
  }

  /// Get detailed breakdown of weekly variances and cumulative balance
  /// 
  /// Returns a map with:
  /// - 'yearlyBalance': cumulative balance
  /// - 'weeklyVariances': list of variances per week
  /// - 'cumulativeBalances': list of cumulative balances after each week
  static Map<String, dynamic> calculateDetailedWeeklyBalance(
    List<WeeklySummary> weeklySummaries, {
    double targetHours = 40.0,
  }) {
    final sorted = List<WeeklySummary>.from(weeklySummaries)
      ..sort((a, b) {
        final yearCompare = a.year.compareTo(b.year);
        if (yearCompare != 0) return yearCompare;
        final weekCompare = a.weekNumber.compareTo(b.weekNumber);
        if (weekCompare != 0) return weekCompare;
        return a.weekStart.compareTo(b.weekStart);
      });

    double cumulativeYearlyBalance = 0.0;
    final List<Map<String, dynamic>> weeklyVariances = [];
    final List<double> cumulativeBalances = [];

    for (final summary in sorted) {
      final weeklyVariance = summary.actualWorkedHours - targetHours;
      cumulativeYearlyBalance += weeklyVariance;

      weeklyVariances.add({
        'weekNumber': summary.weekNumber,
        'year': summary.year,
        'weekRange': summary.weekRange,
        'actualHours': summary.actualWorkedHours,
        'targetHours': targetHours,
        'variance': weeklyVariance,
      });

      cumulativeBalances.add(cumulativeYearlyBalance);
    }

    return {
      'yearlyBalance': cumulativeYearlyBalance,
      'weeklyVariances': weeklyVariances,
      'cumulativeBalances': cumulativeBalances,
    };
  }
}

