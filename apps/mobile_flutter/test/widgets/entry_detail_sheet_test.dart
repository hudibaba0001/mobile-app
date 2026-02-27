import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/l10n/generated/app_localizations.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/widgets/entry_detail_sheet.dart';

void main() {
  testWidgets(
      'EntryDetailSheet scrolls long content without overflow and keeps actions visible',
      (tester) async {
    final entry = Entry(
      userId: 'user_a',
      type: EntryType.work,
      date: DateTime(2026, 2, 3),
      shifts: List.generate(6, (i) {
        final start = DateTime(2026, 2, 3, 8 + i, 0);
        final end = start.add(const Duration(minutes: 75));
        return Shift(
          start: start,
          end: end,
          notes: 'Shift notes $i',
        );
      }),
      notes: List.filled(120, 'Very long notes text').join(' '),
      createdAt: DateTime(2026, 2, 3, 7, 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 320,
              width: 380,
              child: EntryDetailSheet(
                entry: entry,
                onEdit: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    final sheetRect = tester.getRect(find.byType(EntryDetailSheet));
    final deleteRect = tester.getRect(find.byIcon(Icons.delete_outline));
    expect(deleteRect.bottom <= sheetRect.bottom, isTrue);

    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -200));
    await tester.pump();
    expect(tester.takeException(), isNull);

    expect(tester.takeException(), isNull);
  });
}
