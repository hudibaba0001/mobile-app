import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/domain/time_balance_calculator.dart';
import 'package:myapp/models/entry.dart';

void main() {
  group('TimeBalanceCalculator', () {
    test('two atomic work entries same day do not double-subtract target', () {
      final date = DateTime(2025, 1, 15);
      final targetMinutes = 480; // 8 hours
      
      // Create two atomic work entries for the same day
      final entry1 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 15, 8, 0),
          end: DateTime(2025, 1, 15, 12, 0), // 4 hours = 240 minutes
          unpaidBreakMinutes: 15,
        ),
      );
      
      final entry2 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 15, 13, 0),
          end: DateTime(2025, 1, 15, 17, 0), // 4 hours = 240 minutes
          unpaidBreakMinutes: 30,
        ),
      );
      
      final summaries = TimeBalanceCalculator.calculateDailySummaries(
        entries: [entry1, entry2],
        targetForDate: (_) => targetMinutes,
      );
      
      // Should have exactly one summary for the day
      expect(summaries.length, 1);
      
      final summary = summaries.first;
      expect(summary.date, DateTime(2025, 1, 15));
      
      // Worked: (240-15) + (240-30) = 225 + 210 = 435 minutes
      expect(summary.workedMinutes, 435);
      
      // Target applied ONCE: 480 minutes
      expect(summary.targetMinutes, 480);
      
      // Variance: 435 - 480 = -45 minutes
      expect(summary.varianceMinutes, -45);
    });

    test('mix of work + travel entries same day aggregates correctly', () {
      final date = DateTime(2025, 1, 16);
      final targetMinutes = 480; // 8 hours
      
      // One work entry
      final workEntry = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date,
        shift: Shift(
          start: DateTime(2025, 1, 16, 9, 0),
          end: DateTime(2025, 1, 16, 17, 0), // 8 hours = 480 minutes
          unpaidBreakMinutes: 30,
        ),
      );
      
      // Two travel entries (atomic)
      final travelEntry1 = Entry.makeTravelAtomicFromLeg(
        userId: 'user1',
        date: date,
        from: 'Home',
        to: 'Office',
        minutes: 30,
      );
      
      final travelEntry2 = Entry.makeTravelAtomicFromLeg(
        userId: 'user1',
        date: date,
        from: 'Office',
        to: 'Home',
        minutes: 25,
      );
      
      final summaries = TimeBalanceCalculator.calculateDailySummaries(
        entries: [workEntry, travelEntry1, travelEntry2],
        targetForDate: (_) => targetMinutes,
      );
      
      // Should have exactly one summary
      expect(summaries.length, 1);
      
      final summary = summaries.first;
      expect(summary.date, DateTime(2025, 1, 16));
      
      // Worked: 480 - 30 = 450 minutes
      expect(summary.workedMinutes, 450);
      
      // Travel: 30 + 25 = 55 minutes
      expect(summary.travelMinutes, 55);
      
      // Target applied ONCE: 480 minutes
      expect(summary.targetMinutes, 480);
      
      // Variance: 450 - 480 = -30 minutes (travel not included in variance)
      expect(summary.varianceMinutes, -30);
    });

    test('entries on different days produce separate summaries', () {
      final date1 = DateTime(2025, 1, 15);
      final date2 = DateTime(2025, 1, 16);
      
      final entry1 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date1,
        shift: Shift(
          start: DateTime(2025, 1, 15, 9, 0),
          end: DateTime(2025, 1, 15, 17, 0),
          unpaidBreakMinutes: 30,
        ),
      );
      
      final entry2 = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: date2,
        shift: Shift(
          start: DateTime(2025, 1, 16, 9, 0),
          end: DateTime(2025, 1, 16, 17, 0),
          unpaidBreakMinutes: 30,
        ),
      );
      
      final summaries = TimeBalanceCalculator.calculateDailySummaries(
        entries: [entry1, entry2],
        targetForDate: (_) => 480,
      );
      
      // Should have two summaries
      expect(summaries.length, 2);
      
      // Both should have same worked minutes (450) and target (480)
      for (final summary in summaries) {
        expect(summary.workedMinutes, 450);
        expect(summary.targetMinutes, 480);
        expect(summary.varianceMinutes, -30);
      }
      
      // Dates should be different
      expect(summaries[0].date, date1);
      expect(summaries[1].date, date2);
    });

    test('targetForDate is called once per unique date', () {
      final date = DateTime(2025, 1, 17);
      int callCount = 0;
      
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
      
      final summaries = TimeBalanceCalculator.calculateDailySummaries(
        entries: [entry1, entry2],
        targetForDate: (_) {
          callCount++;
          return 480;
        },
      );
      
      // Should be called exactly once (not once per entry)
      expect(callCount, 1);
      expect(summaries.length, 1);
    });

    test('empty entries list returns empty summaries', () {
      final summaries = TimeBalanceCalculator.calculateDailySummaries(
        entries: [],
        targetForDate: (_) => 480,
      );
      
      expect(summaries, isEmpty);
    });
  });
}
