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

  testWidgets(
      'Yearly status uses adjustments so it matches year balance', (tester) async {
    // Scenario: worked 26.6h, target 152h, adjustments +126h => net +0.6h
    // yearNetBalance = worked + adjustments - target = 26.6 + 126 - 152 = 0.6h
    // balanceToday = yearNetBalance + openingBalanceHours = 0.6 + 0 = 0.6h
    await tester.pumpWidget(wrap(TimeBalanceDashboard(
      currentMonthHours: 0,
      currentYearHours: 26.6,
      yearNetBalance: 0.6, // Year-only net balance (worked + adj - target)
      targetHours: 0,
      targetYearlyHours: 152,
      currentMonthName: 'Jan',
      currentYear: 2026,
      monthlyAdjustmentHours: 0,
      yearlyAdjustmentHours: 126,
      openingBalanceHours: 0,
      creditHours: 0,
      yearCreditHours: 0,
    )));

    await tester.pumpAndSettle();

    // The status should show the variance (effective - target)
    expect(find.text('Status: +0.6 h (Over target)'), findsOneWidget);

    // Balance Today section should show the balanceToday value (yearNetBalance + openingBalanceHours)
    expect(find.textContaining('BALANCE TODAY'), findsOneWidget);
    expect(find.text('+0.6h'), findsOneWidget);
  });

  testWidgets('Balance Today includes opening balance', (tester) async {
    // Scenario: User signed up Jan 31, tracking from Jan 1, no logged hours
    // Worked: 0h, Target: 160h, Opening Balance: +170h
    // yearNetBalance = 0 - 160 = -160h (without opening)
    // balanceToday = -160 + 170 = +10h (with opening)
    await tester.pumpWidget(wrap(TimeBalanceDashboard(
      currentMonthHours: 0,
      currentYearHours: 0,
      yearNetBalance: -160.0, // Year-only net balance (NO opening)
      targetHours: 160,
      targetYearlyHours: 160,
      currentMonthName: 'Jan',
      currentYear: 2026,
      monthlyAdjustmentHours: 0,
      yearlyAdjustmentHours: 0,
      openingBalanceHours: 170, // User's starting balance
      creditHours: 0,
      yearCreditHours: 0,
      openingBalanceFormatted: '+170h',
      trackingStartDate: DateTime(2026, 1, 1),
      showYearLoggedSince: true,
    )));

    await tester.pumpAndSettle();

    // Balance Today should be +10h (yearNetBalance + openingBalance = -160 + 170)
    expect(find.textContaining('BALANCE TODAY'), findsOneWidget);
    expect(find.text('+10.0h'), findsOneWidget);

    // Should show "Net this year" with the year-only balance (-160h)
    expect(find.textContaining('Net this year'), findsOneWidget);
    expect(find.textContaining('-160.0h'), findsOneWidget);

    // Should show starting balance info
    expect(find.textContaining('+170h'), findsAtLeastNWidgets(1));
  });
}
