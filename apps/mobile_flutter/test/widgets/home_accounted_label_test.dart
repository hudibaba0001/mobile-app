import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/l10n/generated/app_localizations.dart';
import 'package:myapp/l10n/generated/app_localizations_en.dart';
import 'package:myapp/l10n/generated/app_localizations_sv.dart';
import 'package:myapp/widgets/flexsaldo_card.dart';

/// Regression test: any label that displays "work + leave" combined must read
/// "Accounted time" / "Räknad tid", never "Worked" / "Arbetat".
void main() {
  group('Accounted-vs-Worked label regression', () {
    late AppLocalizationsEn en;
    late AppLocalizationsSv sv;

    setUp(() {
      en = AppLocalizationsEn();
      sv = AppLocalizationsSv();
    });

    test('EN: balance_workedToDate says "Accounted", not "Worked"', () {
      expect(en.balance_workedToDate, contains('Accounted'));
      expect(en.balance_workedToDate, isNot(contains('Worked')));
    });

    test('SV: balance_workedToDate says "Räknad tid", not "Arbetat"', () {
      expect(sv.balance_workedToDate, contains('Räknad tid'));
      expect(sv.balance_workedToDate, isNot(contains('Arbetat')));
    });

    test('EN: balance_hoursWorkedToDate says "Accounted", not "Worked"', () {
      expect(
        en.balance_hoursWorkedToDate('8.0', '8.0'),
        contains('Accounted'),
      );
      expect(
        en.balance_hoursWorkedToDate('8.0', '8.0'),
        isNot(contains('Worked')),
      );
    });

    test('SV: balance_hoursWorkedToDate says "Räknade", not "Arbetade"', () {
      expect(
        sv.balance_hoursWorkedToDate('8.0', '8.0'),
        contains('Räknade'),
      );
      expect(
        sv.balance_hoursWorkedToDate('8.0', '8.0'),
        isNot(contains('Arbetade')),
      );
    });

    test('EN: credited leave label says "credited leave", not "paid leave"',
        () {
      expect(en.balance_creditedPaidLeave('8.0'), contains('credited'));
      expect(
        en.balance_creditedPaidLeave('8.0'),
        isNot(contains('paid leave')),
      );
    });

    test(
        'SV: credited leave label says "ersatt frånvaro", not "betald ledighet"',
        () {
      expect(
        sv.balance_creditedPaidLeave('8.0'),
        contains('ersatt frånvaro'),
      );
      expect(
        sv.balance_creditedPaidLeave('8.0'),
        isNot(contains('betald ledighet')),
      );
    });

    test('EN: home_paidLeave says "Credited Leave"', () {
      expect(en.home_paidLeave, equals('Credited Leave'));
    });

    test('SV: home_paidLeave says "Ersatt frånvaro"', () {
      expect(sv.home_paidLeave, equals('Ersatt frånvaro'));
    });
  });

  group('computeHomeMonthlyStatusMinutes includes credit (leave)', () {
    test('leave minutes count toward positive balance', () {
      // Worked 32h, leave 8h, target 40h → balance = 0
      final balance = computeHomeMonthlyStatusMinutes(
        monthActualMinutes: 32 * 60,
        monthCreditMinutes: 8 * 60,
        monthTargetMinutesToDate: 40 * 60,
      );
      expect(balance, 0);
    });

    test('without leave the same scenario shows deficit', () {
      // Worked 32h, leave 0h, target 40h → balance = -8h
      final balance = computeHomeMonthlyStatusMinutes(
        monthActualMinutes: 32 * 60,
        monthCreditMinutes: 0,
        monthTargetMinutesToDate: 40 * 60,
      );
      expect(balance, -8 * 60);
    });
  });

  group('Widget: Accounted label renders in MaterialApp', () {
    testWidgets('EN locale shows "Accounted" in localized widget',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final t = AppLocalizations.of(context);
                return Text(t.balance_workedToDate);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Accounted time'), findsOneWidget);
      expect(find.textContaining('Worked'), findsNothing);
    });

    testWidgets('SV locale shows "Räknad tid" in localized widget',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('sv'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final t = AppLocalizations.of(context);
                return Text(t.balance_workedToDate);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Räknad tid'), findsOneWidget);
      expect(find.textContaining('Arbetat'), findsNothing);
    });
  });
}
