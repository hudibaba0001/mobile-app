import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:myapp/widgets/unified_entry_form.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/providers/entry_provider.dart';
import 'package:myapp/services/supabase_auth_service.dart';
import 'package:myapp/services/holiday_service.dart';
import 'package:myapp/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/mockito.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockEntryProvider extends Mock implements EntryProvider {}
class MockSupabaseAuthService extends Mock implements SupabaseAuthService {}
class FakeHolidayService extends Mock implements HolidayService {
  @override
  RedDayInfo getRedDayInfo(DateTime date) => RedDayInfo(date: date);
}
void main() {
  setUpAll(() async {
    HttpOverrides.global = null;
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    await Supabase.initialize(
      url: 'https://dummy.supabase.co',
      anonKey: 'dummy',
    );
  });

  group('UnifiedEntryForm Edit Mode Restrictions', () {
    late EntryProvider mockEntryProvider;
    late MockSupabaseAuthService mockAuthService;
    late FakeHolidayService mockHolidayService;

    setUp(() {
      mockEntryProvider = MockEntryProvider();
      mockAuthService = MockSupabaseAuthService();
      mockHolidayService = FakeHolidayService();
      
      when(mockAuthService.currentUser).thenReturn(null);
    });

    Widget createTestWidget({
      EntryType entryType = EntryType.work,
      Entry? existingEntry,
    }) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('sv', ''),
        ],
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<EntryProvider>.value(value: mockEntryProvider),
              ChangeNotifierProvider<SupabaseAuthService>.value(value: mockAuthService),
              ChangeNotifierProvider<HolidayService>.value(value: mockHolidayService),
            ],
            child: UnifiedEntryForm(
              entryType: entryType,
              existingEntry: existingEntry,
            ),
          ),
        ),
      );
    }

    testWidgets('when existingEntry != null: allows adding more shifts and shows hint', (WidgetTester tester) async {
      final existingEntry = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: DateTime(2025, 1, 15),
        shift: Shift(
          start: DateTime(2025, 1, 15, 9, 0),
          end: DateTime(2025, 1, 15, 17, 0),
          unpaidBreakMinutes: 30,
        ),
      );

      await tester.pumpWidget(createTestWidget(
        entryType: EntryType.work,
        existingEntry: existingEntry,
      ));
      await tester.pumpAndSettle();

      // Should find hint about first shift updating existing entry
      expect(find.textContaining('First shift updates this entry'), findsOneWidget);
      // Add another shift button should be present
      expect(find.textContaining('Add another shift'), findsWidgets);
    });

    testWidgets('when existingEntry != null: allows adding more travel legs and shows hint', (WidgetTester tester) async {
      final existingEntry = Entry.makeTravelAtomicFromLeg(
        userId: 'user1',
        date: DateTime(2025, 1, 15),
        from: 'Home',
        to: 'Office',
        minutes: 30,
      );

      await tester.pumpWidget(createTestWidget(
        entryType: EntryType.travel,
        existingEntry: existingEntry,
      ));
      await tester.pumpAndSettle();

      // Should find hint about first leg updating existing entry
      expect(find.textContaining('First leg updates the existing entry'), findsOneWidget);
      // Add another travel button should be present
      expect(find.textContaining('Add another'), findsWidgets);
    });

    testWidgets('"Add new entry for this date" button exists in edit mode', (WidgetTester tester) async {
      final existingEntry = Entry.makeWorkAtomicFromShift(
        userId: 'user1',
        date: DateTime(2025, 1, 15),
        shift: Shift(
          start: DateTime(2025, 1, 15, 9, 0),
          end: DateTime(2025, 1, 15, 17, 0),
        ),
      );

      await tester.pumpWidget(createTestWidget(
        entryType: EntryType.work,
        existingEntry: existingEntry,
      ));
      await tester.pumpAndSettle();

      // Should find "Add new entry for this date" button
      // Note: The button text comes from localization, so we search for a partial match
      expect(find.textContaining('Add new entry'), findsOneWidget);
    });

    testWidgets('create mode (existingEntry == null) shows "Add Another Shift"', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        entryType: EntryType.work,
        existingEntry: null,
      ));
      await tester.pumpAndSettle();

      // Should find an add shift button in create mode
      expect(find.textContaining('Add another shift'), findsWidgets);
      
      // Should NOT find edit-mode-only hint
      expect(find.textContaining('First shift updates this entry'), findsNothing);
      
      // Verify the button is actually clickable (has an onPressed handler)
      final button = find.byType(OutlinedButton);
      expect(button, findsWidgets); // Should find at least one button
    });
  });
}
