import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/providers/contract_provider.dart';

void main() {
  group('ContractProvider tracking start auto-init', () {
    test('no entries and no absences defaults to today date-only', () {
      final now = DateTime(2026, 2, 19, 14, 45);

      final derived = ContractProvider.deriveInitialTrackingStartDate(
        entryDates: const <DateTime>[],
        absenceDates: const <DateTime>[],
        now: now,
      );

      expect(derived, DateTime(2026, 2, 19));
    });

    test('uses earliest activity date across entries and absences', () {
      final derived = ContractProvider.deriveInitialTrackingStartDate(
        entryDates: <DateTime>[
          DateTime(2026, 3, 10, 16, 0),
          DateTime(2026, 1, 15, 9, 0),
        ],
        absenceDates: <DateTime>[
          DateTime(2025, 12, 20, 8, 0),
          DateTime(2026, 1, 1, 12, 0),
        ],
        now: DateTime(2026, 2, 19),
      );

      expect(derived, DateTime(2025, 12, 20));
    });
  });
}
