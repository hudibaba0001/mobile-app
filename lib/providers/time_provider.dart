// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import '../models/monthly_summary.dart';
import '../models/weekly_summary.dart';
import '../utils/time_balance_calculator.dart';
import '../utils/target_hours_calculator.dart';
import '../models/entry.dart';
import '../calendar/sweden_holidays.dart';
import '../services/holiday_service.dart';
import 'entry_provider.dart';
import 'contract_provider.dart';
import 'absence_provider.dart';
import 'balance_adjustment_provider.dart';

/// Provider for managing time balance calculations and data
/// Uses EntryProvider to get entries and ContractProvider for target hours
/// Calculates monthly/yearly balances based on user's contract settings
/// Now includes holiday-aware scheduling and paid absence credits (Option A)
/// 
/// V1 Starting Balance Feature:
/// - trackingStartDate: Date from which to calculate balances (entries before are ignored)
/// - openingFlexMinutes: Opening flex balance added once at start of running total
/// 
/// Balance Adjustments:
/// - Manual corrections that shift the running balance by +/- minutes
/// - Included in monthly/yearly totals on their effective date
class TimeProvider extends ChangeNotifier {
  final EntryProvider _entryProvider;
  final ContractProvider _contractProvider;
  final AbsenceProvider?
      _absenceProvider; // Optional for backward compatibility
  final BalanceAdjustmentProvider?
      _adjustmentProvider; // Optional for balance adjustments
  final HolidayService? _holidayService; // For personal red days + half-day support
  final SwedenHolidayCalendar _holidays = SwedenHolidayCalendar();

  // Listener tracking for auto-refresh
  bool _isListening = false;

  // State
  double _currentMonthlyVariance = 0.0;
  double _currentWeeklyVariance = 0.0;
  double _currentYearlyVariance = 0.0;
  double _currentYearTotalHours = 0.0;
  double _yearlyRunningBalance = 0.0;
  double _yearlyRunningBalanceFromWeeks = 0.0;
  List<MonthlySummary> _monthlySummaries = [];
  List<WeeklySummary> _weeklySummaries = [];
  bool _isLoading = false;
  String? _error;

  // Store monthly credit minutes for UI display
  final Map<String, int> _monthlyCreditMinutes = {}; // Key: "year-month"

  // Store monthly adjustment minutes for UI display
  final Map<String, int> _monthlyAdjustmentMinutes = {}; // Key: "year-month"

  TimeProvider(
    this._entryProvider,
    this._contractProvider, [
    this._absenceProvider,
    this._adjustmentProvider,
    this._holidayService,
  ]) {
    // Auto-refresh: Listen to EntryProvider changes
    _setupListeners();
  }

  /// Setup listeners for auto-refresh when entries change
  void _setupListeners() {
    if (_isListening) return;
    _isListening = true;

    // Listen to entry changes and recalculate balances
    _entryProvider.addListener(_onEntriesChanged);

    // Listen to holiday service changes (personal red days)
    _holidayService?.addListener(_onHolidaysChanged);

    debugPrint('TimeProvider: Auto-refresh listeners enabled');
  }

  /// Handle entry changes - debounced recalculation
  void _onEntriesChanged() {
    // Only recalculate if we have already done initial calculation
    if (_monthlySummaries.isNotEmpty) {
      debugPrint('TimeProvider: Entries changed, recalculating balances...');
      calculateBalances();
    }
  }

  /// Handle holiday changes - recalculate balances
  void _onHolidaysChanged() {
    if (_monthlySummaries.isNotEmpty) {
      debugPrint('TimeProvider: Holidays changed, recalculating balances...');
      calculateBalances();
    }
  }

  @override
  void dispose() {
    // Remove listeners to prevent memory leaks
    _entryProvider.removeListener(_onEntriesChanged);
    _holidayService?.removeListener(_onHolidaysChanged);
    _isListening = false;
    super.dispose();
  }

  /// Get scheduled minutes for a date with full red day support
  ///
  /// Uses HolidayService when available to check:
  /// - Auto holidays (Swedish public holidays)
  /// - Personal red days (user-defined)
  /// - Half-day red day support (50% of normal scheduled)
  ///
  /// Falls back to basic holiday calendar if HolidayService is not available.
  int _getScheduledMinutesForDate({
    required DateTime date,
    required int weeklyTargetMinutes,
  }) {
    // If HolidayService is available, use it for full red day support
    if (_holidayService != null) {
      final redDayInfo = _holidayService.getRedDayInfo(date);

      if (redDayInfo.isRedDay) {
        // Use scheduledMinutesWithRedDayInfo for half-day support
        return TargetHoursCalculator.scheduledMinutesWithRedDayInfo(
          date: date,
          weeklyTargetMinutes: weeklyTargetMinutes,
          isFullRedDay: redDayInfo.isFullDay,
          isHalfRedDay: redDayInfo.halfDay != null,
        );
      }
    }

    // Fallback: Use basic holiday calendar (auto holidays only)
    return TargetHoursCalculator.scheduledMinutesForDate(
      date: date,
      weeklyTargetMinutes: weeklyTargetMinutes,
      holidays: _holidays,
    );
  }

  // Getters
  double get currentMonthlyVariance => _currentMonthlyVariance;
  double get currentWeeklyVariance => _currentWeeklyVariance;
  double get currentYearlyVariance => _currentYearlyVariance;
  double get currentYearTotalHours => _currentYearTotalHours;
  double get yearlyRunningBalance => _yearlyRunningBalance;
  double get yearlyRunningBalanceFromWeeks => _yearlyRunningBalanceFromWeeks;
  
  /// Get the tracking start date from contract provider
  DateTime get trackingStartDate => _contractProvider.trackingStartDate;
  
  /// Get opening flex balance in hours
  double get openingFlexHours => _contractProvider.openingFlexHours;
  
  /// Get formatted opening flex balance string
  String get openingFlexFormatted => _contractProvider.openingFlexFormatted;
  
  /// Whether an opening balance is set
  bool get hasOpeningBalance => _contractProvider.hasOpeningBalance;
  
  /// Whether a custom tracking start date is set
  bool get hasCustomTrackingStartDate => _contractProvider.hasCustomTrackingStartDate;
  List<MonthlySummary> get monthlySummaries => _monthlySummaries;
  List<WeeklySummary> get weeklySummaries => _weeklySummaries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Calculate balances from EntryProvider entries
  /// Uses contract settings from ContractProvider for target hours
  ///
  /// [year] The year to calculate balances for (defaults to current year)
  /// Uses calendar-based monthly targets (weekdays in each month)
  Future<void> calculateBalances({
    int? year,
  }) async {
    // Get weekly target in minutes from ContractProvider
    final weeklyTargetMinutes = _contractProvider.weeklyTargetMinutes;
    _setLoading(true);
    _error = null;

    try {
      final targetYear = year ?? DateTime.now().year;
      
      // Get tracking start date and opening balance from contract settings
      final startDate = _contractProvider.trackingStartDate;
      final openingFlexMinutes = _contractProvider.openingFlexMinutes;

      debugPrint('TimeProvider: Calculating balances for year $targetYear');
      debugPrint(
          'TimeProvider: Weekly target: $weeklyTargetMinutes minutes (${weeklyTargetMinutes / 60.0} hours)');
      debugPrint(
          'TimeProvider: Tracking start date: $startDate, Opening balance: ${openingFlexMinutes / 60.0}h');

      // Get entries from EntryProvider
      final allEntries = _entryProvider.entries;
      debugPrint('TimeProvider: Total entries available: ${allEntries.length}');

      // Debug: Show entry years
      if (allEntries.isNotEmpty) {
        final entryYears = allEntries.map((e) => e.date.year).toSet().toList()
          ..sort();
        debugPrint('TimeProvider: Entry years found: $entryYears');
      }

      // Load absences for the year if AbsenceProvider is available
      await _absenceProvider?.loadAbsences(year: targetYear);

      // Load adjustments for the year if BalanceAdjustmentProvider is available
      await _adjustmentProvider?.loadAdjustments(year: targetYear);

      // Load personal red days for the year if HolidayService is available
      await _holidayService?.loadPersonalRedDays(targetYear);

      // Filter entries for the target year AND on/after tracking start date
      final yearEntries = allEntries.where((entry) {
        if (entry.date.year != targetYear) return false;
        // Filter out entries before tracking start date (date-only comparison)
        final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        final trackingDate = DateTime(startDate.year, startDate.month, startDate.day);
        return !entryDate.isBefore(trackingDate);
      }).toList();
      debugPrint(
          'TimeProvider: Entries for year $targetYear (after $startDate): ${yearEntries.length}');

      // Build map of actual minutes by date (day-by-day)
      final Map<DateTime, int> actualByDate = {};
      for (final entry in yearEntries) {
        final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
        actualByDate[day] =
            (actualByDate[day] ?? 0) + entry.totalDuration.inMinutes;
      }

      // Generate ALL 12 months with day-by-day calculations
      // But skip days before trackingStartDate
      _monthlySummaries = [];
      int totalYearlyVarianceMinutes = 0;
      int totalYearActualMinutes = 0;
      int totalYearScheduledMinutes = 0;
      int totalYearCreditMinutes = 0;
      int totalYearAdjustmentMinutes = 0;
      
      // Normalize tracking start date for comparison
      final trackingDate = DateTime(startDate.year, startDate.month, startDate.day);

      for (int month = 1; month <= 12; month++) {
        final lastDay = DateTime(targetYear, month + 1, 0);

        int monthActualMinutes = 0;
        int monthScheduledMinutes = 0;
        int monthCreditMinutes = 0;
        int monthAdjustmentMinutes = 0;

        // Calculate day-by-day for this month
        for (int day = 1; day <= lastDay.day; day++) {
          final date = DateTime(targetYear, month, day);
          
          // Skip days before tracking start date
          if (date.isBefore(trackingDate)) {
            continue;
          }

          // Scheduled minutes (holiday-aware with personal red days support)
          final scheduled = _getScheduledMinutesForDate(
            date: date,
            weeklyTargetMinutes: weeklyTargetMinutes,
          );
          monthScheduledMinutes += scheduled;

          // Actual minutes
          final actual = actualByDate[date] ?? 0;
          monthActualMinutes += actual;

          // Credit minutes (paid absences - Option A) - reuse scheduled value
          final credit =
              _absenceProvider?.paidAbsenceMinutesForDate(date, scheduled) ?? 0;
          monthCreditMinutes += credit;
          
          // Adjustment minutes (manual corrections) - separate from variance calculation
          final adjustment = _adjustmentProvider?.adjustmentMinutesForDate(date) ?? 0;
          monthAdjustmentMinutes += adjustment;
        }

        // Month variance = actual + credit - scheduled
        // (adjustments are added separately to running balance)
        final monthVarianceMinutes =
            monthActualMinutes + monthCreditMinutes - monthScheduledMinutes;
        totalYearlyVarianceMinutes += monthVarianceMinutes;
        totalYearActualMinutes += monthActualMinutes;
        totalYearScheduledMinutes += monthScheduledMinutes;
        totalYearCreditMinutes += monthCreditMinutes;
        totalYearAdjustmentMinutes += monthAdjustmentMinutes;

        final actualHours = monthActualMinutes / 60.0;
        _monthlySummaries.add(
          MonthlySummary(
            year: targetYear,
            month: month,
            actualWorkedHours: actualHours,
          ),
        );

        // Store credit and adjustment minutes for UI
        _monthlyCreditMinutes['$targetYear-$month'] = monthCreditMinutes;
        _monthlyAdjustmentMinutes['$targetYear-$month'] = monthAdjustmentMinutes;

        debugPrint(
            'TimeProvider: ${_monthlySummaries.last.monthName} $targetYear: '
            '${actualHours.toStringAsFixed(1)}h actual, '
            '${(monthScheduledMinutes / 60.0).toStringAsFixed(1)}h scheduled, '
            '${(monthCreditMinutes / 60.0).toStringAsFixed(1)}h credit, '
            '${(monthAdjustmentMinutes / 60.0).toStringAsFixed(1)}h adj, '
            '${(monthVarianceMinutes / 60.0).toStringAsFixed(1)}h variance');
      }

      // Add opening balance and adjustments to yearly variance
      // Formula: runningBalance = opening + sum(variances) + sum(adjustments)
      final totalVarianceWithOpening = totalYearlyVarianceMinutes + 
          openingFlexMinutes + 
          totalYearAdjustmentMinutes;
      
      _yearlyRunningBalance = totalVarianceWithOpening / 60.0;
      _currentYearTotalHours = totalYearActualMinutes / 60.0;

      // Yearly variance = sum of monthly variances + opening balance + adjustments
      final yearVarianceMinutes = totalYearActualMinutes +
          totalYearCreditMinutes -
          totalYearScheduledMinutes +
          openingFlexMinutes +
          totalYearAdjustmentMinutes;
      _currentYearlyVariance = yearVarianceMinutes / 60.0;
      
      debugPrint(
          'TimeProvider: Opening balance applied: ${openingFlexMinutes / 60.0}h');
      debugPrint(
          'TimeProvider: Adjustments applied: ${totalYearAdjustmentMinutes / 60.0}h');

      debugPrint(
          'TimeProvider: Yearly totals - Actual: ${_currentYearTotalHours.toStringAsFixed(1)}h, '
          'Scheduled: ${(totalYearScheduledMinutes / 60.0).toStringAsFixed(1)}h, '
          'Credit: ${(totalYearCreditMinutes / 60.0).toStringAsFixed(1)}h, '
          'Variance: ${_currentYearlyVariance.toStringAsFixed(1)}h');
      debugPrint(
          'TimeProvider: Yearly running balance (sum of monthly variances): ${_yearlyRunningBalance.toStringAsFixed(1)}h');
      debugPrint(
          'TimeProvider: Match check: ${(yearVarianceMinutes - totalYearlyVarianceMinutes).abs() < 1 ? "✓ PASS" : "✗ FAIL"} (diff: ${(yearVarianceMinutes - totalYearlyVarianceMinutes).abs()} minutes)');

      // Calculate current month variance (respecting tracking start date)
      final currentMonth = DateTime.now().month;

      // Recalculate current month with day-by-day method
      final currentLastDay = DateTime(targetYear, currentMonth + 1, 0);
      int currentMonthActual = 0;
      int currentMonthScheduled = 0;
      int currentMonthCredit = 0;

      for (int day = 1; day <= currentLastDay.day; day++) {
        final date = DateTime(targetYear, currentMonth, day);
        
        // Skip days before tracking start date
        if (date.isBefore(trackingDate)) {
          continue;
        }
        
        final scheduled = _getScheduledMinutesForDate(
          date: date,
          weeklyTargetMinutes: weeklyTargetMinutes,
        );
        currentMonthScheduled += scheduled;
        currentMonthActual += actualByDate[date] ?? 0;
        currentMonthCredit +=
            _absenceProvider?.paidAbsenceMinutesForDate(date, scheduled) ?? 0;
      }

      _currentMonthlyVariance =
          (currentMonthActual + currentMonthCredit - currentMonthScheduled) /
              60.0;

      // Group entries by week (already filtered by trackingStartDate via yearEntries)
      final weeklyData = _groupEntriesByWeek(yearEntries);

      // Create WeeklySummary objects
      _weeklySummaries = weeklyData.entries.map((entry) {
        final weekData = entry.value;
        final totalHours = _calculateTotalHours(weekData);

        return WeeklySummary(
          year: targetYear,
          weekNumber: entry.key.weekNumber,
          weekStart: entry.key.weekStart,
          actualWorkedHours: totalHours,
        );
      }).toList();

      // Calculate yearly balance from weeks using contract settings
      _yearlyRunningBalanceFromWeeks =
          TimeBalanceCalculator.calculateYearlyBalanceFromWeeks(
        _weeklySummaries,
        targetHours: weeklyTargetMinutes / 60.0,
      );

      // Calculate current week variance
      final currentWeek = _getWeekForDate(DateTime.now());
      final currentWeekSummary = _weeklySummaries.firstWhere(
        (s) => s.weekNumber == currentWeek.weekNumber && s.year == targetYear,
        orElse: () => WeeklySummary(
          year: targetYear,
          weekNumber: currentWeek.weekNumber,
          weekStart: currentWeek.weekStart,
          actualWorkedHours: 0.0,
        ),
      );

      _currentWeeklyVariance = TimeBalanceCalculator.calculateWeeklyVariance(
        currentWeekSummary.actualWorkedHours,
        targetHours: weeklyTargetMinutes / 60.0,
      );

      debugPrint(
          'TimeProvider: Using contract settings - Weekly target: ${weeklyTargetMinutes / 60.0}h');
      debugPrint(
          'TimeProvider: Calculated yearly balance (monthly): ${_yearlyRunningBalance.toStringAsFixed(1)}h');
      debugPrint(
          'TimeProvider: Calculated yearly balance (weekly): ${_yearlyRunningBalanceFromWeeks.toStringAsFixed(1)}h');
      debugPrint(
          'TimeProvider: Current month variance: ${_currentMonthlyVariance.toStringAsFixed(1)}h');
      debugPrint(
          'TimeProvider: Current week variance: ${_currentWeeklyVariance.toStringAsFixed(1)}h');

      notifyListeners();
    } catch (e) {
      _error = 'Failed to calculate balances: $e';
      debugPrint('TimeProvider: Error: $_error');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Group entries by week
  /// Returns a map with week key (containing weekNumber and weekStart) to list of entries
  Map<_WeekKey, List<Entry>> _groupEntriesByWeek(List<Entry> entries) {
    final Map<_WeekKey, List<Entry>> grouped = {};

    for (final entry in entries) {
      final week = _getWeekForDate(entry.date);
      final key =
          _WeekKey(weekNumber: week.weekNumber, weekStart: week.weekStart);
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    return grouped;
  }

  /// Get week information for a given date
  /// Returns week number (ISO) and week start date (Monday)
  ({int weekNumber, DateTime weekStart}) _getWeekForDate(DateTime date) {
    // Get ISO week number
    final weekNumber = _getISOWeekNumber(date);

    // Get Monday of the week (ISO weeks start on Monday)
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    final daysFromMonday = weekday == 7 ? 6 : weekday - 1;
    final weekStart = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysFromMonday));

    return (weekNumber: weekNumber, weekStart: weekStart);
  }

  /// Get ISO week number for a date
  int _getISOWeekNumber(DateTime date) {
    // ISO 8601 week: Week 1 is the week with the year's first Thursday
    final jan4 = DateTime(date.year, 1, 4);
    final jan4Weekday = jan4.weekday; // 1 = Monday, 7 = Sunday
    final daysToThursday = (4 - jan4Weekday + 7) % 7;
    final firstThursday = jan4.add(Duration(days: daysToThursday));
    final week1Start =
        firstThursday.subtract(const Duration(days: 3)); // Monday of week 1

    if (date.isBefore(week1Start)) {
      // Date is in the last week of previous year
      final prevYear = date.year - 1;
      final prevJan4 = DateTime(prevYear, 1, 4);
      final prevJan4Weekday = prevJan4.weekday;
      final prevDaysToThursday = (4 - prevJan4Weekday + 7) % 7;
      final prevFirstThursday =
          prevJan4.add(Duration(days: prevDaysToThursday));
      final prevWeek1Start =
          prevFirstThursday.subtract(const Duration(days: 3));
      final daysSincePrevWeek1 = date.difference(prevWeek1Start).inDays;
      return (daysSincePrevWeek1 ~/ 7) + 1;
    }

    final daysSinceWeek1 = date.difference(week1Start).inDays;
    return (daysSinceWeek1 ~/ 7) + 1;
  }

  /// Calculate total hours from a list of entries
  /// Includes BOTH travel time (from travel entries) and work shifts (from work entries)
  /// Uses Entry.totalDuration which handles both types automatically:
  /// - Travel entries: uses travelMinutes
  /// - Work entries: uses shifts duration
  double _calculateTotalHours(List<Entry> entries) {
    double totalHours = 0.0;

    for (final entry in entries) {
      // totalDuration handles both travel (travelMinutes) and work (shifts)
      final duration = entry.totalDuration;
      totalHours += duration.inMinutes / 60.0;
    }

    return totalHours;
  }

  /// Refresh data for current year using contract settings
  Future<void> refresh() async {
    await calculateBalances();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Get current month summary
  MonthlySummary? getCurrentMonthSummary() {
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    return _monthlySummaries.firstWhere(
      (s) => s.month == currentMonth && s.year == currentYear,
      orElse: () => MonthlySummary(
        year: currentYear,
        month: currentMonth,
        actualWorkedHours: 0.0,
      ),
    );
  }

  /// Get detailed balance breakdown using contract settings
  ///
  /// Note: This method now uses calendar-based monthly targets.
  /// The targetHours parameter is ignored in favor of contract settings.
  Map<String, dynamic> getDetailedBalance({double? targetHours}) {
    final weeklyTargetMinutes = _contractProvider.weeklyTargetMinutes;

    // Build detailed breakdown with calendar-based targets
    final sorted = List<MonthlySummary>.from(_monthlySummaries)
      ..sort((a, b) {
        final yearCompare = a.year.compareTo(b.year);
        if (yearCompare != 0) return yearCompare;
        return a.month.compareTo(b.month);
      });

    double cumulativeYearlyBalance = 0.0;
    final List<Map<String, dynamic>> monthlyVariances = [];
    final List<double> cumulativeBalances = [];

    for (final summary in sorted) {
      final actualMinutes = (summary.actualWorkedHours * 60).round();
      final targetMinutes = TargetHoursCalculator.monthlyTargetMinutes(
        summary.year,
        summary.month,
        weeklyTargetMinutes,
      );
      final monthlyVariance = (actualMinutes - targetMinutes) / 60.0;
      cumulativeYearlyBalance += monthlyVariance;

      monthlyVariances.add({
        'month': summary.monthName,
        'year': summary.year,
        'actualHours': summary.actualWorkedHours,
        'targetHours': targetMinutes / 60.0,
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

  /// Get detailed weekly balance breakdown using contract settings
  Map<String, dynamic> getDetailedWeeklyBalance({double? targetHours}) {
    final weeklyTarget = targetHours ?? _contractProvider.weeklyTargetHours;
    return TimeBalanceCalculator.calculateDetailedWeeklyBalance(
      _weeklySummaries,
      targetHours: weeklyTarget,
    );
  }

  /// Get current target hours from contract settings
  double get weeklyTargetHours => _contractProvider.weeklyTargetHours;

  /// Get current monthly scheduled hours for a specific month (holiday-aware)
  ///
  /// [year] The year
  /// [month] The month (1-12)
  double monthlyTargetHours({required int year, required int month}) {
    final weeklyTargetMinutes = _contractProvider.weeklyTargetMinutes;
    final scheduledMinutes = TargetHoursCalculator.monthlyScheduledMinutes(
      year: year,
      month: month,
      weeklyTargetMinutes: weeklyTargetMinutes,
      holidays: _holidays,
    );
    return scheduledMinutes / 60.0;
  }

  /// Get current yearly scheduled hours (sum of all monthly scheduled, holiday-aware)
  ///
  /// [year] The year
  double yearlyTargetHours({required int year}) {
    final weeklyTargetMinutes = _contractProvider.weeklyTargetMinutes;
    final scheduledMinutes = TargetHoursCalculator.yearlyScheduledMinutes(
      year: year,
      weeklyTargetMinutes: weeklyTargetMinutes,
      holidays: _holidays,
    );
    return scheduledMinutes / 60.0;
  }

  /// Get monthly credit hours (paid absences) for a specific month
  ///
  /// [year] The year
  /// [month] The month (1-12)
  /// Returns credit hours (0 if no absences or not calculated yet)
  double monthlyCreditHours({required int year, required int month}) {
    final key = '$year-$month';
    final creditMinutes = _monthlyCreditMinutes[key] ?? 0;
    return creditMinutes / 60.0;
  }
  
  /// Get monthly adjustment hours for a specific month
  ///
  /// [year] The year
  /// [month] The month (1-12)
  /// Returns adjustment hours (0 if no adjustments or not calculated yet)
  double monthlyAdjustmentHours({required int year, required int month}) {
    final key = '$year-$month';
    final adjustmentMinutes = _monthlyAdjustmentMinutes[key] ?? 0;
    return adjustmentMinutes / 60.0;
  }
  
  /// Get total adjustment minutes for the year
  int get totalYearAdjustmentMinutes {
    int total = 0;
    for (final entry in _monthlyAdjustmentMinutes.entries) {
      total += entry.value;
    }
    return total;
  }
  
  /// Get total adjustment hours for the year
  double get totalYearAdjustmentHours => totalYearAdjustmentMinutes / 60.0;

  /// Get month target minutes up to today (month-to-date)
  ///
  /// [year] The year
  /// [month] The month (1-12)
  /// Returns scheduled minutes from 1st of month up to today (or end of month if today is later)
  int monthTargetMinutesToDate(int year, int month) {
    final weeklyTargetMinutes = _contractProvider.weeklyTargetMinutes;
    final start = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final end = DateTime.now().isBefore(lastDayOfMonth)
        ? DateTime.now()
        : lastDayOfMonth;

    return TargetHoursCalculator.scheduledMinutesInRange(
      start: start,
      endInclusive: end,
      weeklyTargetMinutes: weeklyTargetMinutes,
      holidays: _holidays,
    );
  }

  /// Get year target minutes up to today (year-to-date)
  ///
  /// [year] The year
  /// Returns scheduled minutes from Jan 1 up to today (or Dec 31 if today is later)
  int yearTargetMinutesToDate(int year) {
    final weeklyTargetMinutes = _contractProvider.weeklyTargetMinutes;
    final start = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31);
    final end = DateTime.now().isBefore(endOfYear) ? DateTime.now() : endOfYear;

    return TargetHoursCalculator.scheduledMinutesInRange(
      start: start,
      endInclusive: end,
      weeklyTargetMinutes: weeklyTargetMinutes,
      holidays: _holidays,
    );
  }

  /// Get month target hours up to today (for display)
  ///
  /// [year] The year
  /// [month] The month (1-12)
  double monthTargetHoursToDate({required int year, required int month}) {
    return monthTargetMinutesToDate(year, month) / 60.0;
  }

  /// Get year target hours up to today (for display)
  ///
  /// [year] The year
  double yearTargetHoursToDate({required int year}) {
    return yearTargetMinutesToDate(year) / 60.0;
  }

  /// Get actual worked minutes up to today for a month
  ///
  /// [year] The year
  /// [month] The month (1-12)
  int monthActualMinutesToDate(int year, int month) {
    final start = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final end = DateTime.now().isBefore(lastDayOfMonth)
        ? DateTime.now()
        : lastDayOfMonth;

    final allEntries = _entryProvider.entries;
    int totalMinutes = 0;

    for (final entry in allEntries) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate.year == year &&
          entryDate.month == month &&
          !entryDate.isBefore(start) &&
          !entryDate.isAfter(end)) {
        totalMinutes += entry.totalDuration.inMinutes;
      }
    }

    return totalMinutes;
  }

  /// Get credit minutes up to today for a month
  ///
  /// [year] The year
  /// [month] The month (1-12)
  int monthCreditMinutesToDate(int year, int month) {
    final absenceProvider = _absenceProvider;
    if (absenceProvider == null) return 0;

    final start = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final end = DateTime.now().isBefore(lastDayOfMonth)
        ? DateTime.now()
        : lastDayOfMonth;

    final weeklyTargetMinutes = _contractProvider.weeklyTargetMinutes;
    int totalCredit = 0;

    DateTime current = start;
    while (!current.isAfter(end)) {
      final scheduled = _getScheduledMinutesForDate(
        date: current,
        weeklyTargetMinutes: weeklyTargetMinutes,
      );
      totalCredit +=
          absenceProvider.paidAbsenceMinutesForDate(current, scheduled);
      current = current.add(const Duration(days: 1));
    }

    return totalCredit;
  }

  /// Get year actual minutes up to today
  ///
  /// [year] The year
  int yearActualMinutesToDate(int year) {
    final start = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31);
    final end = DateTime.now().isBefore(endOfYear) ? DateTime.now() : endOfYear;

    final allEntries = _entryProvider.entries;
    int totalMinutes = 0;

    for (final entry in allEntries) {
      final entryDate =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate.year == year &&
          !entryDate.isBefore(start) &&
          !entryDate.isAfter(end)) {
        totalMinutes += entry.totalDuration.inMinutes;
      }
    }

    return totalMinutes;
  }

  /// Get year credit minutes up to today
  ///
  /// [year] The year
  int yearCreditMinutesToDate(int year) {
    final absenceProvider = _absenceProvider;
    if (absenceProvider == null) return 0;

    final start = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31);
    final end = DateTime.now().isBefore(endOfYear) ? DateTime.now() : endOfYear;

    final weeklyTargetMinutes = _contractProvider.weeklyTargetMinutes;
    int totalCredit = 0;

    DateTime current = start;
    while (!current.isAfter(end)) {
      final scheduled = _getScheduledMinutesForDate(
        date: current,
        weeklyTargetMinutes: weeklyTargetMinutes,
      );
      totalCredit +=
          absenceProvider.paidAbsenceMinutesForDate(current, scheduled);
      current = current.add(const Duration(days: 1));
    }

    return totalCredit;
  }

  /// Get current week summary
  WeeklySummary? getCurrentWeekSummary() {
    final currentWeek = _getWeekForDate(DateTime.now());
    final currentYear = DateTime.now().year;

    return _weeklySummaries.firstWhere(
      (s) => s.weekNumber == currentWeek.weekNumber && s.year == currentYear,
      orElse: () => WeeklySummary(
        year: currentYear,
        weekNumber: currentWeek.weekNumber,
        weekStart: currentWeek.weekStart,
        actualWorkedHours: 0.0,
      ),
    );
  }
}

/// Helper class for week grouping key
class _WeekKey {
  final int weekNumber;
  final DateTime weekStart;

  _WeekKey({required this.weekNumber, required this.weekStart});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _WeekKey &&
          runtimeType == other.runtimeType &&
          weekNumber == other.weekNumber &&
          weekStart.year == other.weekStart.year &&
          weekStart.month == other.weekStart.month &&
          weekStart.day == other.weekStart.day;

  @override
  int get hashCode => weekNumber.hashCode ^ weekStart.hashCode;
}
