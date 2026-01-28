import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:myapp/screens/unified_home_screen.dart';
import 'package:myapp/providers/entry_provider.dart';
import 'package:myapp/services/supabase_auth_service.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class RecordingEntryProvider extends Mock
    with ChangeNotifier
    implements EntryProvider {
  List<Entry>? recorded;

  @override
  Future<void> addEntries(List<Entry> entries) async {
    recorded = entries;
  }

  @override
  Future<void> addEntry(Entry entry) async {
    recorded = [entry];
  }
}

class StubSupabaseAuthService extends Mock
    with ChangeNotifier
    implements SupabaseAuthService {
  User? user;
  bool authenticated = true;
  bool initialized = true;

  @override
  User? get currentUser => user;

  @override
  bool get isAuthenticated => authenticated;

  @override
  bool get isInitialized => initialized;
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

  group('TravelEntryDialog EntryProvider integration', () {
    late RecordingEntryProvider mockEntryProvider;
    late StubSupabaseAuthService mockAuthService;
    List<Entry>? capturedEntries;

    setUp(() {
      mockEntryProvider = RecordingEntryProvider();
      mockAuthService = StubSupabaseAuthService();
      capturedEntries = null;
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.physicalSizeTestValue = const Size(2400, 2600);
      binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        binding.window.clearPhysicalSizeTestValue();
        binding.window.clearDevicePixelRatioTestValue();
      });
      
      mockAuthService.user = User(
        id: 'test-user-id',
        email: 'test@example.com',
        appMetadata: {},
        userMetadata: {},
        createdAt: DateTime.now().toIso8601String(),
        aud: '',
      );
      mockAuthService.authenticated = true;
      mockAuthService.initialized = true;
    });

    Widget createTestWidget({required Widget child}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<EntryProvider>.value(
              value: mockEntryProvider),
          ChangeNotifierProvider<SupabaseAuthService>.value(
              value: mockAuthService),
        ],
        child: MaterialApp(
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
            body: child,
          ),
        ),
      );
    }

    testWidgets('TravelEntryDialog saves atomic travel entries via EntryProvider', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const TravelEntryDialog(enableSuggestions: false),
                );
              },
              child: const Text('Open Dialog'),
            );
          },
        ),
      ));

      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(TravelEntryDialog), findsOneWidget);
      final dialogContext = tester.element(find.byType(TravelEntryDialog));
      final providedEntryProvider =
          Provider.of<EntryProvider>(dialogContext, listen: false);
      final providedAuth =
          Provider.of<SupabaseAuthService>(dialogContext, listen: false);
      expect(identical(providedEntryProvider, mockEntryProvider), isTrue);
      expect(identical(providedAuth, mockAuthService), isTrue);

      await tester.enterText(find.byKey(const Key('travel_from_0')), 'A');
      await tester.enterText(find.byKey(const Key('travel_to_0')), 'B');
      await tester.enterText(find.byKey(const Key('travel_hours_0')), '1');
      await tester.enterText(find.byKey(const Key('travel_minutes_0')), '15');
      await tester.pumpAndSettle();

      final saveButton =
          tester.widget<ElevatedButton>(find.byKey(const Key('travel_save_button')));
      expect(saveButton.onPressed, isNotNull);
      await tester.runAsync(() async {
        saveButton.onPressed!.call();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();

      capturedEntries = mockEntryProvider.recorded;
      expect(capturedEntries, isNotNull);
      expect(capturedEntries!.length, 1);
      expect(capturedEntries!.first.type, EntryType.travel);
      expect(capturedEntries!.first.travelMinutes, 75);
    });

    testWidgets('WorkEntryDialog saves one Entry per shift via EntryProvider', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const WorkEntryDialog(enableSuggestions: false),
                );
              },
              child: const Text('Open Work Dialog'),
            );
          },
        ),
      ));

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Work Dialog'));
      await tester.pumpAndSettle();

      final dialogContext = tester.element(find.byType(WorkEntryDialog));
      final providedEntryProvider =
          Provider.of<EntryProvider>(dialogContext, listen: false);
      final providedAuth =
          Provider.of<SupabaseAuthService>(dialogContext, listen: false);
      expect(identical(providedEntryProvider, mockEntryProvider), isTrue);
      expect(identical(providedAuth, mockAuthService), isTrue);

      await tester.enterText(find.byKey(const Key('work_start_0')), '8:00 AM');
      await tester.enterText(find.byKey(const Key('work_end_0')), '10:00 AM');

      await tester.tap(find.byKey(const Key('add_shift_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('work_start_1')), '11:00 AM');
      await tester.enterText(find.byKey(const Key('work_end_1')), '12:00 PM');
      await tester.pumpAndSettle();

      final saveButton =
          tester.widget<ElevatedButton>(find.byKey(const Key('work_save_button')));
      expect(saveButton.onPressed, isNotNull);
      await tester.runAsync(() async {
        saveButton.onPressed!.call();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();

      capturedEntries = mockEntryProvider.recorded;
      expect(capturedEntries, isNotNull);
      expect(capturedEntries!.length, 2);
      expect(capturedEntries!.every((e) => e.type == EntryType.work), isTrue);
      expect(capturedEntries!.every((e) => e.isAtomicWork), isTrue);
    });
  });
}
