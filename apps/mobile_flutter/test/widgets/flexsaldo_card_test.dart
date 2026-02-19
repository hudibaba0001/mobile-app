import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/absence.dart';
import 'package:myapp/models/balance_adjustment.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/widgets/flexsaldo_card.dart';

void main() {
  group('FlexsaldoCard yearly balance', () {
    test(
      'includes opening balance + year adjustments + period difference',
      () {
        final now = DateTime(2026, 2, 19, 12, 0);
        final entries = <Entry>[
          Entry.makeWorkAtomicFromShift(
            userId: 'user-1',
            date: DateTime(2026, 2, 10),
            shift: Shift(
              start: DateTime(2026, 2, 10, 8, 0),
              end: DateTime(2026, 2, 10, 13, 15), // +315 min difference
            ),
          ),
        ];
        final adjustments = <BalanceAdjustment>[
          BalanceAdjustment(
            userId: 'user-1',
            effectiveDate: DateTime(2026, 2, 11),
            deltaMinutes: -120,
          ),
        ];

        final yearlyBalance = computeHomeYearlyBalanceMinutes(
          now: now,
          entries: entries,
          absences: const <AbsenceEntry>[],
          adjustments: adjustments,
          weeklyTargetMinutes: 0,
          trackingStartDate: DateTime(2026, 1, 1),
          openingBalanceMinutes: 600,
          travelEnabled: true,
        );

        expect(yearlyBalance, 795); // 600 - 120 + 315
      },
    );

    test(
      'monthly home status stays unchanged when opening/adjustment events exist',
      () {
        final monthlyBefore = computeHomeMonthlyStatusMinutes(
          monthActualMinutes: 112 * 60,
          monthCreditMinutes: 8 * 60,
          monthTargetMinutesToDate: 120 * 60,
        );

        final yearlyBalance = computeHomeYearlyBalanceMinutes(
          now: DateTime(2026, 2, 19),
          entries: <Entry>[
            Entry.makeWorkAtomicFromShift(
              userId: 'user-2',
              date: DateTime(2026, 2, 12),
              shift: Shift(
                start: DateTime(2026, 2, 12, 8, 0),
                end: DateTime(2026, 2, 12, 13, 15),
              ),
            ),
          ],
          absences: const <AbsenceEntry>[],
          adjustments: <BalanceAdjustment>[
            BalanceAdjustment(
              userId: 'user-2',
              effectiveDate: DateTime(2026, 2, 12),
              deltaMinutes: -120,
            ),
          ],
          weeklyTargetMinutes: 0,
          trackingStartDate: DateTime(2026, 1, 1),
          openingBalanceMinutes: 600,
          travelEnabled: true,
        );

        final monthlyAfter = computeHomeMonthlyStatusMinutes(
          monthActualMinutes: 112 * 60,
          monthCreditMinutes: 8 * 60,
          monthTargetMinutesToDate: 120 * 60,
        );

        expect(monthlyBefore, 0);
        expect(monthlyAfter, monthlyBefore);
        expect(yearlyBalance, 795); // Yearly includes opening/adjustments.
      },
    );
  });
}
