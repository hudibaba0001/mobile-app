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

  group('ContractProvider effectiveTrackingStartDate', () {
    test('explicit tracking start date wins', () {
      final resolved = ContractProvider.resolveEffectiveTrackingStartDate(
        explicitTrackingStartDate: DateTime(2026, 2, 1, 15, 30),
        hasAnyEntries: true,
        earliestEntryDate: DateTime(2026, 1, 1),
        now: DateTime(2026, 3, 1),
      );

      expect(resolved, DateTime(2026, 2, 1));
    });

    test('without explicit date, earliest entry date is used', () {
      final resolved = ContractProvider.resolveEffectiveTrackingStartDate(
        explicitTrackingStartDate: null,
        hasAnyEntries: true,
        earliestEntryDate: DateTime(2026, 1, 12, 23, 59),
        now: DateTime(2026, 3, 1),
      );

      expect(resolved, DateTime(2026, 1, 12));
    });

    test('without explicit date and without entries, falls back to today', () {
      final resolved = ContractProvider.resolveEffectiveTrackingStartDate(
        explicitTrackingStartDate: null,
        hasAnyEntries: false,
        earliestEntryDate: null,
        now: DateTime(2026, 2, 19, 11, 45),
      );

      expect(resolved, DateTime(2026, 2, 19));
    });
  });
}
