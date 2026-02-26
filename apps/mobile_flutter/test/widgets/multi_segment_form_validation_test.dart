import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/l10n/generated/app_localizations.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/providers/entry_provider.dart';
import 'package:myapp/services/supabase_auth_service.dart';
import 'package:myapp/widgets/multi_segment_form.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _RecordingEntryProvider extends Mock
    with ChangeNotifier
    implements EntryProvider {
  int addEntryCalls = 0;

  @override
  Future<void> addEntry(Entry entry) async {
    addEntryCalls++;
  }
}

class _StubSupabaseAuthService extends Mock
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

Widget _buildHarness({
  required EntryProvider entryProvider,
  required SupabaseAuthService authService,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<EntryProvider>.value(value: entryProvider),
      ChangeNotifierProvider<SupabaseAuthService>.value(value: authService),
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
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://dummy.supabase.co',
      anonKey: 'dummy',
    );
  });

  testWidgets(
      'save journey halts when active segment has data but fails validation',
      (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(2400, 3200);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    final entryProvider = _RecordingEntryProvider();
    final authService = _StubSupabaseAuthService()
      ..user = User(
        id: 'test-user',
        email: 'test@example.com',
        appMetadata: const {},
        userMetadata: const {},
        createdAt: DateTime.now().toIso8601String(),
        aud: '',
      );
    var onSuccessCalled = false;

    final existingSegment = Entry.makeTravelAtomicFromLeg(
      userId: 'test-user',
      date: DateTime(2026, 3, 3),
      from: 'A',
      to: 'B',
      minutes: 30,
    );

    await tester.pumpWidget(
      _buildHarness(
        entryProvider: entryProvider,
        authService: authService,
        child: MultiSegmentForm(
          existingSegments: [existingSegment],
          onSuccess: () => onSuccessCalled = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(4));

    await tester.enterText(fields.at(1), 'C');
    await tester.enterText(fields.at(2), '-10');

    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid travel time'), findsOneWidget);
    expect(entryProvider.addEntryCalls, 0);
    expect(onSuccessCalled, isFalse);
  });
}
