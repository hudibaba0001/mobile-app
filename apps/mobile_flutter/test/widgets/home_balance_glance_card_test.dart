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
    testWidgets('renders title, big number, and month line with planned > 0',
        (tester) async {
      var seeMoreTapped = false;

      await tester.pumpWidget(wrap(HomeBalanceGlanceCard(
        timeBalanceEnabled: true,
        balanceTodayMinutes: 265, // +4h 25m
        monthAccountedMinutes: 7465, // 124h 25m
        monthPlannedMinutes: 7200, // 120h 0m
        monthDeltaMinutes: 265, // +4h 25m
        monthLabel: 'Feb',
        yearDeltaMinutes: 360, // +6h 0m
        yearLabel: 'This year',
        title: 'Time balance',
        seeMoreLabel: 'See more →',
        sinceStartLabel: 'since start',
        localeCode: 'en',
        onSeeMore: () => seeMoreTapped = true,
      )));
      await tester.pumpAndSettle();

      // Title present
      expect(find.text('Time balance'), findsOneWidget);
      // See more link present
      expect(find.text('See more →'), findsOneWidget);

      // Month line contains worked / planned format
      expect(find.textContaining('Feb:'), findsOneWidget);
      expect(find.textContaining('/'), findsOneWidget);

      // Year line present
      expect(find.textContaining('This year:'), findsOneWidget);

      // Does NOT contain verbose legacy strings
      expect(find.textContaining('Calculated from'), findsNothing);
      expect(find.textContaining('Baseline'), findsNothing);
      expect(find.textContaining('Full month target'), findsNothing);
      expect(find.textContaining('Starting balance'), findsNothing);
      expect(find.textContaining('Status (to date)'), findsNothing);

      // Progress bar present
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Tap "See more" triggers callback
      await tester.tap(find.text('See more →'));
      expect(seeMoreTapped, isTrue);
    });
  });

  group('HomeBalanceGlanceCard - planned zero edge case', () {
    testWidgets('shows "since start" variant when planned is 0',
        (tester) async {
      await tester.pumpWidget(wrap(HomeBalanceGlanceCard(
        timeBalanceEnabled: true,
        balanceTodayMinutes: 480,
        monthAccountedMinutes: 480, // 8h 0m
        monthPlannedMinutes: 0,
        monthDeltaMinutes: 480,
        monthLabel: 'Feb',
        yearDeltaMinutes: 480,
        yearLabel: 'This year (since start)',
        title: 'Time balance',
        seeMoreLabel: 'See more →',
        sinceStartLabel: 'since start',
        localeCode: 'en',
        onSeeMore: () {},
      )));
      await tester.pumpAndSettle();

      // Shows "since start" variant in month line
      expect(find.textContaining('since start'), findsWidgets);
      // Does NOT show "/ 0h" confusing denominator
      expect(find.textContaining('/ 0h'), findsNothing);
    });
  });

  group('HomeBalanceGlanceCard - year label variants', () {
    testWidgets('shows "This year (since start)" when tracking started mid-year',
        (tester) async {
      await tester.pumpWidget(wrap(HomeBalanceGlanceCard(
        timeBalanceEnabled: true,
        balanceTodayMinutes: 120,
        monthAccountedMinutes: 480,
        monthPlannedMinutes: 480,
        monthDeltaMinutes: 0,
        monthLabel: 'Feb',
        yearDeltaMinutes: 120, // +2h 0m
        yearLabel: 'This year (since start)',
        title: 'Time balance',
        seeMoreLabel: 'See more →',
        sinceStartLabel: 'since start',
        localeCode: 'en',
        onSeeMore: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('This year (since start):'), findsOneWidget);
    });

    testWidgets('shows "This year" when tracking started on/before Jan 1',
        (tester) async {
      await tester.pumpWidget(wrap(HomeBalanceGlanceCard(
        timeBalanceEnabled: true,
        balanceTodayMinutes: -60,
        monthAccountedMinutes: 480,
        monthPlannedMinutes: 480,
        monthDeltaMinutes: 0,
        monthLabel: 'Feb',
        yearDeltaMinutes: -60, // -1h 0m
        yearLabel: 'This year',
        title: 'Time balance',
        seeMoreLabel: 'See more →',
        sinceStartLabel: 'since start',
        localeCode: 'en',
        onSeeMore: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('This year:'), findsOneWidget);
      // Should NOT contain "since start" in the year label
      expect(find.textContaining('This year (since start)'), findsNothing);
    });
  });

  group('HomeBalanceGlanceCard - log-only mode', () {
    testWidgets('shows log-only title and hides delta/planned and year line',
        (tester) async {
      await tester.pumpWidget(wrap(HomeBalanceGlanceCard(
        timeBalanceEnabled: false,
        balanceTodayMinutes: 0,
        monthAccountedMinutes: 480,
        monthPlannedMinutes: 0,
        monthDeltaMinutes: 0,
        monthLabel: 'Feb',
        yearDeltaMinutes: 0,
        yearLabel: 'This year',
        title: 'Logged time',
        seeMoreLabel: 'See more →',
        sinceStartLabel: 'since start',
        localeCode: 'en',
        onSeeMore: () {},
      )));
      await tester.pumpAndSettle();

      // Title shows log-only mode
      expect(find.text('Logged time'), findsOneWidget);
      // No progress bar in log-only mode
      expect(find.byType(LinearProgressIndicator), findsNothing);
      // Shows month label with accounted time
      expect(find.textContaining('Feb:'), findsOneWidget);
      // Year line should NOT appear in log-only mode
      expect(find.textContaining('This year'), findsNothing);
    });
  });
}
