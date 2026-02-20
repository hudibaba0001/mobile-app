import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myapp/widgets/time_balance_dashboard.dart';
import 'package:myapp/l10n/generated/app_localizations.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('sv'),
      ],
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  testWidgets('Yearly status uses adjustments so it matches year balance',
      (tester) async {
    // Scenario: worked 26h 36m, target 152h 0m, adjustments +126h 0m => net +0h 36m
    // yearNet = worked + adjustments - target = 1596 + 7560 - 9120 = +36 min
    // balanceToday = yearNet + openingBalance = +36 + 0 = +36 min
    await tester.pumpWidget(wrap(TimeBalanceDashboard(
      currentMonthMinutes: 0,
      currentYearMinutes: 1596,
      yearNetMinutes: 36,
      targetMinutes: 0,
      targetYearlyMinutes: 9120,
      currentMonthName: 'Jan',
      currentYear: 2026,
      monthlyAdjustmentMinutes: 0,
      yearlyAdjustmentMinutes: 7560,
      openingBalanceMinutes: 0,
      creditMinutes: 0,
      yearCreditMinutes: 0,
    )));

    await tester.pumpAndSettle();

    // Balance today row should match the balanceToday value
    expect(find.text('BALANCE TODAY: +0h 36m'), findsOneWidget);

    // Balance Today section should show the balanceToday value (yearNet + openingBalance)
    expect(find.text('BALANCE TODAY'), findsOneWidget);
    expect(find.text('+0h 36m'), findsWidgets);
  });

  testWidgets('Balance Today includes opening balance', (tester) async {
    // Scenario: User signed up Jan 31, tracking from Jan 1, no logged hours
    // Worked: 0h, Target: 160h, Opening Balance: +170h
    // yearNet = 0 - 160h = -160h
    // balanceToday = -160h + 170h = +10h
    await tester.pumpWidget(wrap(TimeBalanceDashboard(
      currentMonthMinutes: 0,
      currentYearMinutes: 0,
      yearNetMinutes: -9600,
      targetMinutes: 9600,
      targetYearlyMinutes: 9600,
      currentMonthName: 'Jan',
      currentYear: 2026,
      monthlyAdjustmentMinutes: 0,
      yearlyAdjustmentMinutes: 0,
      openingBalanceMinutes: 10200,
      creditMinutes: 0,
      yearCreditMinutes: 0,
      openingBalanceFormatted: '+170h',
      trackingStartDate: DateTime(2026, 1, 1),
      showYearLoggedSince: true,
    )));

    await tester.pumpAndSettle();

    // Balance Today should be +10h (yearNet + openingBalance = -160h + 170h)
    expect(find.text('BALANCE TODAY'), findsOneWidget);
    expect(find.text('+10h 00m'), findsWidgets);

    // Should show "Net this year" with the year-only balance (-160h).
    expect(find.textContaining('Net this year'), findsOneWidget);
    expect(find.text('Net this year (logged): -160h 00m'), findsOneWidget);

    // Should show starting balance info
    expect(find.textContaining('+170h'), findsAtLeastNWidgets(1));
  });
}
