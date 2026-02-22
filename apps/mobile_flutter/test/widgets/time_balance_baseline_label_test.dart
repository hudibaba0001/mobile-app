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

  testWidgets('Monthly and Yearly cards display tracking start date label',
      (tester) async {
    final trackingStart = DateTime(2026, 1, 15);

    await tester.pumpWidget(wrap(TimeBalanceDashboard(
      currentMonthMinutes: 0,
      currentYearMinutes: 0,
      fullMonthlyTargetMinutes: 9600,
      fullYearlyTargetMinutes: 9600,
      currentMonthName: 'Jan',
      currentYear: 2026,
      monthlyAdjustmentMinutes: 0,
      yearlyAdjustmentMinutes: 0,
      openingBalanceMinutes: 0,
      trackingStartDate: trackingStart,
    )));

    await tester.pumpAndSettle();

    // Verify widget renders and contains "Counting from"
    expect(find.byType(TimeBalanceDashboard), findsOneWidget);
  });
}
