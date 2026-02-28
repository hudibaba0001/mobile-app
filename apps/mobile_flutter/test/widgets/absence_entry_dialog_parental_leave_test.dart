import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/l10n/generated/app_localizations.dart';
import 'package:myapp/l10n/generated/app_localizations_sv.dart';
import 'package:myapp/widgets/absence_entry_dialog.dart';

void main() {
  testWidgets('parentalLeave appears in absence type options list',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showAbsenceEntryDialog(context, year: 2026);
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final typeTile = find.ancestor(
      of: find.byIcon(Icons.category),
      matching: find.byType(ListTile),
    );
    expect(typeTile, findsWidgets);

    await tester.tap(typeTile.first);
    await tester.pumpAndSettle();

    expect(find.text('Parental leave'), findsOneWidget);
  });

  test('Swedish label resolves to Föräldraledighet', () {
    final sv = AppLocalizationsSv();
    expect(sv.leave_parentalLeave, 'Föräldraledighet');
  });
}
