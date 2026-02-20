import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/screens/reports_screen.dart';
import 'package:myapp/widgets/flexsaldo_card.dart';

void main() {
  group('Tracking range text widgets', () {
    testWidgets('Home shows tracking and month effective range',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeTrackingRangeText(
              baselineDate: DateTime(2026, 1, 1),
              baselineMinutes: 1740,
              today: DateTime(2026, 2, 19),
              localeCode: 'en',
            ),
          ),
        ),
      );

      expect(
        find.text('Baseline: +29h 0m (as of 2026-01-01)'),
        findsOneWidget,
      );
      expect(
        find.text('Calculated from: 2026-01-01 → 2026-02-19'),
        findsOneWidget,
      );
    });

    testWidgets('Overview shows tracking start and effective range',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewTrackingRangeText(
              reportStart: DateTime(2026, 1, 1),
              reportEnd: DateTime(2026, 1, 31),
              trackingStartDate: DateTime(2026, 1, 10),
            ),
          ),
        ),
      );

      expect(
        find.text('Report period: 2026-01-01 → 2026-01-31'),
        findsOneWidget,
      );
      expect(
        find.text('Calculated from: 2026-01-10 → 2026-01-31'),
        findsOneWidget,
      );
    });
  });
}
