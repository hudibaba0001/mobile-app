import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/domain/time_balance_calculator.dart';
import 'package:myapp/models/entry.dart';

/// Regression test to ensure daily target is applied ONCE per date
/// even when there are multiple atomic work entries on the same date.
/// 
/// This test will FAIL if someone reverts to per-entry target subtraction.
void main() {
  group('Daily Target Grouping Regression Test', () {
    test('two atomic work entries same date: target applied ONCE, variance = 0 when worked = target', () {
      // Setup: Target = 480 minutes (8h)
      // Entry1 worked = 240 minutes (4h)
      // Entry2 worked = 240 minutes (4h)
      // Expected: Daily variance = 0 (NOT -480)
      
      final date = DateTime(2025, 1, 15); // Wednesday (weekday)
      final targetMinutes = 480; // 8 hours
      
      // Create two atomic work entries for the same day
      // Entry 1: 4 hours worked (240 minutes)
      final entry1 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 15, 8, 0),
          end: DateTime(2025, 1, 15, 12, 0), // 4 hours = 240 minutes
          unpaidBreakMinutes: 0, // No break, so worked = 240
        ),
      );
      
      // Entry 2: 4 hours worked (240 minutes)
      final entry2 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 15, 13, 0),
          end: DateTime(2025, 1, 15, 17, 0), // 4 hours = 240 minutes
          unpaidBreakMinutes: 0, // No break, so worked = 240
        ),
      );
      
      // Calculate daily summaries using TimeBalanceCalculator
      // This is the function used by the app to compute daily variance
      final summaries = TimeBalanceCalculator.calculateDailySummaries(
        entries: [entry1, entry2],
        targetForDate: (_) => targetMinutes,
      );
      
      // Should have exactly ONE summary for the day (entries grouped by date)
      expect(summaries.length, 1, 
        reason: 'Multiple entries on same date must produce ONE summary');
      
      final summary = summaries.first;
      expect(summary.date, date);
      
      // Total worked minutes: 240 + 240 = 480
      expect(summary.workedMinutes, 480,
        reason: 'Worked minutes must be sum of all entries for the day');
      
      // Target applied ONCE: 480 minutes (not 480 * 2 = 960)
      expect(summary.targetMinutes, 480,
        reason: 'Target must be applied ONCE per date, not per entry');
      
      // Variance: 480 (worked) - 480 (target) = 0
      // If target was applied twice, variance would be: 480 - 960 = -480
      expect(summary.varianceMinutes, 0,
        reason: 'Variance must be 0 when worked = target. '
                'If this fails, target is being applied per-entry instead of per-date.');
    });

    test('three atomic work entries same date: target still applied ONCE', () {
      // Additional test: Three entries, target applied once
      final date = DateTime(2025, 1, 16);
      final targetMinutes = 480;
      
      final entry1 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 16, 8, 0),
          end: DateTime(2025, 1, 16, 10, 0), // 2 hours = 120 minutes
          unpaidBreakMinutes: 0,
        ),
      );
      
      final entry2 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 16, 10, 30),
          end: DateTime(2025, 1, 16, 14, 30), // 4 hours = 240 minutes
          unpaidBreakMinutes: 30, // 240 - 30 = 210 worked
        ),
      );
      
      final entry3 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 16, 15, 0),
          end: DateTime(2025, 1, 16, 17, 0), // 2 hours = 120 minutes
          unpaidBreakMinutes: 0,
        ),
      );
      
      final summaries = TimeBalanceCalculator.calculateDailySummaries(
        entries: [entry1, entry2, entry3],
        targetForDate: (_) => targetMinutes,
      );
      
      expect(summaries.length, 1);
      
      final summary = summaries.first;
      // Worked: 120 + 210 + 120 = 450
      expect(summary.workedMinutes, 450);
      // Target: 480 (applied ONCE, not 480 * 3 = 1440)
      expect(summary.targetMinutes, 480);
      // Variance: 450 - 480 = -30
      expect(summary.varianceMinutes, -30);
    });

    test('targetForDate called exactly once per unique date (not per entry)', () {
      // Verify that targetForDate is called once per date, not once per entry
      final date = DateTime(2025, 1, 17);
      int callCount = 0;
      final callDates = <DateTime>[];
      
      final entry1 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 17, 8, 0),
          end: DateTime(2025, 1, 17, 12, 0),
        ),
      );
      
      final entry2 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 17, 13, 0),
          end: DateTime(2025, 1, 17, 17, 0),
        ),
      );
      
      final entry3 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 17, 18, 0),
          end: DateTime(2025, 1, 17, 20, 0),
        ),
      );
      
      final summaries = TimeBalanceCalculator.calculateDailySummaries(
        entries: [entry1, entry2, entry3],
        targetForDate: (date) {
          callCount++;
          callDates.add(date);
          return 480;
        },
      );
      
      // Should be called exactly ONCE (not 3 times, once per entry)
      expect(callCount, 1,
        reason: 'targetForDate must be called ONCE per unique date, not per entry');
      expect(callDates.length, 1);
      expect(callDates.first, date);
      expect(summaries.length, 1);
    });

    test('break logic with grouping: calculator sums workedMinutes (after breaks), not raw span', () {
      // Regression test: Proves calculator sums workedMinutes correctly
      // This catches a common bug where someone might sum raw span instead of workedMinutes
      // 
      // Same date, two work entries:
      // Entry1: span 300, break 30 → worked 270
      // Entry2: span 240, break 0 → worked 240
      // worked total = 510
      // target = 480
      // variance = +30
      
      final date = DateTime(2025, 1, 18);
      final targetMinutes = 480; // 8 hours
      
      // Entry 1: 5 hours span (300 min), 30 min break → 270 worked
      final entry1 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 18, 8, 0),
          end: DateTime(2025, 1, 18, 13, 0), // 5 hours = 300 minutes span
          unpaidBreakMinutes: 30, // Break 30, so worked = 300 - 30 = 270
        ),
      );
      
      // Entry 2: 4 hours span (240 min), 0 break → 240 worked
      final entry2 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 18, 14, 0),
          end: DateTime(2025, 1, 18, 18, 0), // 4 hours = 240 minutes span
          unpaidBreakMinutes: 0, // No break, so worked = 240
        ),
      );
      
      // Verify individual shift workedMinutes
      expect(entry1.shifts!.first.workedMinutes, 270); // 300 - 30
      expect(entry2.shifts!.first.workedMinutes, 240); // 240 - 0
      
      final summaries = TimeBalanceCalculator.calculateDailySummaries(
        entries: [entry1, entry2],
        targetForDate: (_) => targetMinutes,
      );
      
      expect(summaries.length, 1);
      
      final summary = summaries.first;
      
      // Total worked: 270 + 240 = 510 (NOT 300 + 240 = 540 if summing raw span)
      expect(summary.workedMinutes, 510,
        reason: 'Calculator must sum workedMinutes (after breaks), not raw span. '
                'If this fails, breaks are not being subtracted correctly.');
      
      // Target: 480
      expect(summary.targetMinutes, 480);
      
      // Variance: 510 - 480 = +30
      expect(summary.varianceMinutes, 30,
        reason: 'Variance must account for breaks. '
                'If breaks were ignored, variance would be: 540 - 480 = 60 (wrong)');
    });
  });
}
