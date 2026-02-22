import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myapp/widgets/home_balance_glance_card.dart';
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
      supportedLocales: const [Locale('en'), Locale('sv')],
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('HomeBalanceGlanceCard - compact rendering', () {
    testWidgets(
        'renders title, subtitle, big number, and change-vs-plan lines',
        (tester) async {
      var seeMoreTapped = false;

      await tester.pumpWidget(wrap(HomeBalanceGlanceCard(
        timeBalanceEnabled: true,
        balanceTodayMinutes: 265, // +4h 25m
        monthDeltaMinutes: 265, // +4h 25m
        monthLabel: 'Feb',
        yearDeltaMinutes: 360, // +6h 0m
        yearLabel: 'This year',
        title: 'Balance today',
        balanceSubtitle: 'Incl. opening + adjustments',
        changeVsPlanLabel: 'Change vs plan',
        seeMoreLabel: 'See more →',
        localeCode: 'en',
        onSeeMore: () => seeMoreTapped = true,
      )));
      await tester.pumpAndSettle();

      // Title present
      expect(find.text('Balance today'), findsOneWidget);
      // Subtitle present
      expect(find.text('Incl. opening + adjustments'), findsOneWidget);
      // See more link present
      expect(find.text('See more →'), findsOneWidget);

      // Month line: "Feb: Change vs plan  +4h 25m"
      expect(find.textContaining('Feb: Change vs plan'), findsOneWidget);

      // Year line: "This year: Change vs plan  +6h 0m"
      expect(find.textContaining('This year: Change vs plan'), findsOneWidget);

      // Does NOT contain verbose legacy strings
      expect(find.textContaining('Calculated from'), findsNothing);
      expect(find.textContaining('Baseline'), findsNothing);
      expect(find.textContaining('Full month target'), findsNothing);
      expect(find.textContaining('Starting balance'), findsNothing);
      expect(find.textContaining('Status (to date)'), findsNothing);

      // Progress bar present (even at zero progress when timeBalanceEnabled)
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Tap "See more" triggers callback
      await tester.tap(find.text('See more →'));
      expect(seeMoreTapped, isTrue);
    });
  });

  group('HomeBalanceGlanceCard - with progress bar', () {
    testWidgets('shows progress bar when month planned > 0', (tester) async {
      await tester.pumpWidget(wrap(HomeBalanceGlanceCard(
        timeBalanceEnabled: true,
        balanceTodayMinutes: 265,
        monthAccountedMinutes: 7465,
        monthPlannedMinutes: 7200,
        monthDeltaMinutes: 265,
        monthLabel: 'Feb',
        yearDeltaMinutes: 360,
        yearLabel: 'This year',
        title: 'Balance today',
        balanceSubtitle: 'Incl. opening + adjustments',
        changeVsPlanLabel: 'Change vs plan',
        seeMoreLabel: 'See more →',
        localeCode: 'en',
        onSeeMore: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('HomeBalanceGlanceCard - year label variants', () {
    testWidgets(
        'shows "This year (since start)" when tracking started mid-year',
        (tester) async {
      await tester.pumpWidget(wrap(HomeBalanceGlanceCard(
        timeBalanceEnabled: true,
        balanceTodayMinutes: 120,
        monthDeltaMinutes: 0,
        monthLabel: 'Feb',
        yearDeltaMinutes: 120, // +2h 0m
        yearLabel: 'This year (since start)',
        title: 'Balance today',
        balanceSubtitle: 'Incl. opening + adjustments',
        changeVsPlanLabel: 'Change vs plan',
        seeMoreLabel: 'See more →',
        localeCode: 'en',
        onSeeMore: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('This year (since start): Change vs plan'),
          findsOneWidget);
    });

    testWidgets('shows "This year" when tracking started on/before Jan 1',
        (tester) async {
      await tester.pumpWidget(wrap(HomeBalanceGlanceCard(
        timeBalanceEnabled: true,
        balanceTodayMinutes: -60,
        monthDeltaMinutes: 0,
        monthLabel: 'Feb',
        yearDeltaMinutes: -60, // -1h 0m
        yearLabel: 'This year',
        title: 'Balance today',
        balanceSubtitle: 'Incl. opening + adjustments',
        changeVsPlanLabel: 'Change vs plan',
        seeMoreLabel: 'See more →',
        localeCode: 'en',
        onSeeMore: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('This year: Change vs plan'), findsOneWidget);
      // Should NOT contain "since start" in the year label
      expect(find.textContaining('This year (since start)'), findsNothing);
    });
  });

  group('HomeBalanceGlanceCard - log-only mode', () {
    testWidgets('shows log-only title and hides balance/year line',
        (tester) async {
      await tester.pumpWidget(wrap(HomeBalanceGlanceCard(
        timeBalanceEnabled: false,
        balanceTodayMinutes: 0,
        monthDeltaMinutes: 0,
        monthLabel: 'Feb',
        yearDeltaMinutes: 0,
        yearLabel: 'This year',
        title: 'Logged time',
        balanceSubtitle: 'Incl. opening + adjustments',
        changeVsPlanLabel: 'Change vs plan',
        seeMoreLabel: 'See more →',
        localeCode: 'en',
        onSeeMore: () {},
      )));
      await tester.pumpAndSettle();

      // Title shows log-only mode
      expect(find.text('Logged time'), findsOneWidget);
      // No subtitle in log-only mode
      expect(find.text('Incl. opening + adjustments'), findsNothing);
      // No progress bar in log-only mode
      expect(find.byType(LinearProgressIndicator), findsNothing);
      // Shows month label with accounted time
      expect(find.textContaining('Feb:'), findsOneWidget);
      // Year line should NOT appear in log-only mode
      expect(find.textContaining('This year'), findsNothing);
    });
  });
}
