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
              trackingStartDate: DateTime(2026, 1, 1),
              today: DateTime(2026, 2, 19),
              monthEffectiveStart: DateTime(2026, 2, 1),
            ),
          ),
        ),
      );

      expect(find.text('Tracking: 2026-01-01 -> 2026-02-19'), findsOneWidget);
      expect(
        find.text('This month (from 2026-02-01 -> 2026-02-19)'),
        findsOneWidget,
      );
    });

    testWidgets('Overview shows tracking start and effective range',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewTrackingRangeText(
              selectedStart: DateTime(2026, 1, 1),
              selectedEnd: DateTime(2026, 1, 31),
              trackingStartDate: DateTime(2026, 1, 10),
            ),
          ),
        ),
      );

      expect(find.text('Tracking start: 2026-01-10'), findsOneWidget);
      expect(
        find.text('Effective range: 2026-01-10 -> 2026-01-31'),
        findsOneWidget,
      );
    });
  });
}
