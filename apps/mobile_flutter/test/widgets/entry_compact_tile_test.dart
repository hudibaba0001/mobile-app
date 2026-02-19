import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/l10n/generated/app_localizations.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/widgets/entry_compact_tile.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
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
      body: child,
    ),
  );
}

void main() {
  testWidgets('shows duration pill and work subtitle with time and break',
      (tester) async {
    final entry = Entry.makeWorkAtomicFromShift(
      userId: 'test-user',
      date: DateTime(2026, 2, 26),
      shift: Shift(
        start: DateTime(2026, 2, 26, 9, 0),
        end: DateTime(2026, 2, 26, 17, 30),
        unpaidBreakMinutes: 30,
      ),
      dayNotes: 'Client handoff',
    );

    await tester.pumpWidget(_wrap(EntryCompactTile(entry: entry)));
    await tester.pumpAndSettle();

    expect(find.text('Work'), findsOneWidget);
    expect(find.text('8h 0m'), findsOneWidget);
    expect(find.text('09:00\u201317:30 \u2022 Break 30m'), findsOneWidget);
  });

  testWidgets('shows travel route subtitle as From to To', (tester) async {
    final entry = Entry.makeTravelAtomicFromLeg(
      userId: 'test-user',
      date: DateTime(2026, 2, 26),
      from: 'Gothenburg',
      to: 'Torslanda',
      minutes: 55,
      dayNotes: 'Morning commute',
    );

    await tester.pumpWidget(_wrap(EntryCompactTile(entry: entry)));
    await tester.pumpAndSettle();

    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Gothenburg \u2192 Torslanda'), findsOneWidget);
    expect(find.text('55m'), findsOneWidget);
  });

  testWidgets('shows date-only meta line when note is empty', (tester) async {
    final entry = Entry.makeTravelAtomicFromLeg(
      userId: 'test-user',
      date: DateTime(2026, 2, 26),
      from: 'Gothenburg',
      to: 'Torslanda',
      minutes: 30,
      dayNotes: '',
    );

    await tester.pumpWidget(_wrap(EntryCompactTile(entry: entry)));
    await tester.pumpAndSettle();

    expect(find.text('Feb 26, 2026'), findsOneWidget);
    expect(find.textContaining('Feb 26, 2026 \u2022'), findsNothing);
  });
}
