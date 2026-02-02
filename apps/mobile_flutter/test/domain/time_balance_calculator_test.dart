import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/domain/time_balance_calculator.dart';
import '../helpers/entry_fixtures.dart';

void main() {
  group('Domain TimeBalanceCalculator (Logic Core)', () {
    test('Groups entries by local date & applies target ONCE per day', () {
      final date = DateTime(2024, 1, 15);
      
      // Two entries on the same day
      final entry1 = makeWorkEntry(
        localDate: date, // 8-12
        startHHMM: '08:00',
        endHHMM: '12:00',
      );
      final entry2 = makeWorkEntry(
        localDate: date, // 13-17
        startHHMM: '13:00', 
        endHHMM: '17:00',
      );

      final entries = [entry1, entry2];

      // Target function: 8h (480m) per day
      int mockTarget(DateTime d) => 480;

      final summaries = TimeBalanceCalculator.calculateDailySummaries(
        entries: entries,
        targetForDate: mockTarget,
      );

      // Should have 1 summary for Jan 15
      expect(summaries.length, 1);
      final summary = summaries.first;

      // Total worked: 4h + 4h = 8h (480m)
      expect(summary.workedMinutes, 480);
      
      // Target applied ONCE: 480m
      expect(summary.targetMinutes, 480);
      
      // Variance: 480 - 480 = 0
      expect(summary.varianceMinutes, 0);
    });

    test('Local date grouping: Groups by Y-M-D regardless of time', () {
      // Entry at 08:00
      final entry1 = makeWorkEntry(
        localDate: DateTime(2024, 1, 1, 8, 0),
        startHHMM: '08:00', endHHMM: '09:00',
      );
      // Entry at 23:00 (same day)
      final entry2 = makeWorkEntry(
        localDate: DateTime(2024, 1, 1, 23, 0),
        startHHMM: '23:00', endHHMM: '23:30',
      );

      final summaries = TimeBalanceCalculator.calculateDailySummaries(
        entries: [entry1, entry2],
        targetForDate: (_) => 0,
      );

      expect(summaries.length, 1);
      expect(summaries.first.workedMinutes, 90); // 60 + 30
    });
  });
}
