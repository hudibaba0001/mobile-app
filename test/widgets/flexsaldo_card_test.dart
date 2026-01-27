import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:myapp/widgets/flexsaldo_card.dart';
import 'package:myapp/providers/time_provider.dart';
import 'package:myapp/providers/entry_provider.dart';
import 'package:myapp/providers/contract_provider.dart';
import 'package:myapp/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myapp/services/supabase_auth_service.dart';

import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'flexsaldo_card_test.mocks.dart';

@GenerateMocks([SupabaseAuthService])
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

  group('FlexsaldoCard', () {
    late MockSupabaseAuthService mockSupabaseAuthService;
    late EntryProvider mockEntryProvider;
    late ContractProvider mockContractProvider;
    late TimeProvider timeProvider;

    setUp(() {
      mockSupabaseAuthService = MockSupabaseAuthService();
      mockEntryProvider = EntryProvider(mockSupabaseAuthService);
      mockContractProvider = ContractProvider();
      timeProvider = TimeProvider(mockEntryProvider, mockContractProvider);
    });

    Widget createTestWidget({
      VoidCallback? onExportTimeReport,
      VoidCallback? onExportTravelReport,
    }) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<EntryProvider>.value(value: mockEntryProvider),
            ChangeNotifierProvider<ContractProvider>.value(value: mockContractProvider),
            ChangeNotifierProvider<TimeProvider>.value(value: timeProvider),
          ],
          child: Scaffold(
            body: FlexsaldoCard(
              onExportTimeReport: onExportTimeReport,
              onExportTravelReport: onExportTravelReport,
            ),
          ),
        ),
      );
    }

    testWidgets('renders FlexsaldoCard with balance title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show balance title
      expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);
    });

    testWidgets('renders export buttons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show export buttons
      expect(find.text('Export Time'), findsOneWidget);
      expect(find.text('Export Travel'), findsOneWidget);
    });

    testWidgets('calls onExportTimeReport when Time button tapped', (tester) async {
      bool timeExportCalled = false;

      await tester.pumpWidget(createTestWidget(
        onExportTimeReport: () => timeExportCalled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export Time'));
      await tester.pumpAndSettle();

      expect(timeExportCalled, isTrue);
    });

    testWidgets('calls onExportTravelReport when Travel button tapped', (tester) async {
      bool travelExportCalled = false;

      await tester.pumpWidget(createTestWidget(
        onExportTravelReport: () => travelExportCalled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export Travel'));
      await tester.pumpAndSettle();

      expect(travelExportCalled, isTrue);
    });

    testWidgets('renders progress bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show LinearProgressIndicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
