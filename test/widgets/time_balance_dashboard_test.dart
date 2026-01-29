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
      'Yearly status uses adjustments so it matches running balance', (tester) async {
    // Scenario: worked 26.6h, target 152h, adjustments +126h => net +0.6h
    await tester.pumpWidget(wrap(TimeBalanceDashboard(
      currentMonthHours: 0,
      currentYearHours: 26.6,
      yearlyBalance: 0.6,
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

    expect(find.text('Status: +0.6 h (Over)'), findsOneWidget);
    expect(find.text('Total Accumulation:'), findsOneWidget);
  });
}
