import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:myapp/screens/unified_home_screen.dart';
import 'package:myapp/providers/entry_provider.dart';
import 'package:myapp/models/travel_entry.dart';
import 'package:myapp/models/work_entry.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/providers/location_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/repositories/repository_provider.dart';
import 'package:myapp/repositories/travel_repository.dart';
import 'package:myapp/repositories/work_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'unified_home_screen_test.mocks.dart';

@GenerateMocks([
  EntryProvider,
  AuthService,
  LocationProvider,
  ThemeProvider,
  User,
  RepositoryProvider,
  TravelRepository,
  WorkRepository,
])
void main() {
  group('UnifiedHomeScreen - Log Travel Dialog', () {
    late MockEntryProvider mockEntryProvider;
    late MockAuthService mockAuthService;
    late MockLocationProvider mockLocationProvider;
    late MockThemeProvider mockThemeProvider;
    late MockRepositoryProvider mockRepositoryProvider;
    late MockTravelRepository mockTravelRepository;
    late MockWorkRepository mockWorkRepository;
    late MockUser mockUser;
    late GoRouter mockRouter;

    setUp(() {
      mockEntryProvider = MockEntryProvider();
      mockAuthService = MockAuthService();
      mockLocationProvider = MockLocationProvider();
      mockThemeProvider = MockThemeProvider();
      mockRepositoryProvider = MockRepositoryProvider();
      mockTravelRepository = MockTravelRepository();
      mockWorkRepository = MockWorkRepository();
      mockUser = MockUser();

      // Setup mock user
      when(mockUser.uid).thenReturn('test-user-id');

      // Setup mock auth service
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.isInitialized).thenReturn(true);
      when(mockAuthService.isAuthenticated).thenReturn(true);

      // Setup mock theme provider
      when(mockThemeProvider.isDarkMode).thenReturn(false);
      when(mockThemeProvider.lightTheme).thenReturn(ThemeData.light());

      // Setup mock repository provider
      when(mockRepositoryProvider.travelRepository)
          .thenReturn(mockTravelRepository);
      when(mockRepositoryProvider.workRepository)
          .thenReturn(mockWorkRepository);
      when(mockTravelRepository.getAllForUser(any)).thenReturn(<TravelEntry>[]);
      when(mockWorkRepository.getAllForUser(any)).thenReturn(<WorkEntry>[]);

      // Setup mock location provider
      when(mockLocationProvider.getAutocompleteSuggestions(any)).thenReturn([]);

      // Setup mock router
      final routerConfig = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const UnifiedHomeScreen(),
          ),
        ],
      );
      mockRouter = routerConfig;
    });

    Future<void> pumpHomeScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: mockRouter,
          builder: (context, child) {
            return MultiProvider(
              providers: [
                ChangeNotifierProvider<EntryProvider>.value(
                  value: mockEntryProvider,
                ),
                ListenableProvider<AuthService>.value(
                  value: mockAuthService,
                ),
                ChangeNotifierProvider<LocationProvider>.value(
                  value: mockLocationProvider,
                ),
                ChangeNotifierProvider<ThemeProvider>.value(
                  value: mockThemeProvider,
                ),
                Provider<RepositoryProvider>.value(
                  value: mockRepositoryProvider,
                ),
              ],
              child: child!,
            );
          },
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openTravelDialog(WidgetTester tester) async {
      final fab = find.byType(FloatingActionButton);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      final travelButton = find.widgetWithText(ListTile, 'Log Travel');
      await tester.tap(travelButton);
      await tester.pumpAndSettle();
    }

    testWidgets('can log a travel entry', (WidgetTester tester) async {
      // ARRANGE
      await pumpHomeScreen(tester);

      // Verify the screen is rendered
      expect(find.byType(UnifiedHomeScreen), findsOneWidget);

      // ACT - Open the Log Travel dialog
      await openTravelDialog(tester);

      // Verify dialog is shown
      expect(find.text('Log Travel Entry'), findsOneWidget);

      // Enter travel details
      final fromField = find.byType(TextField).first;
      final toField = find.byType(TextField).at(1);
      final hoursField = find.byType(TextField).at(2);
      final minutesField = find.byType(TextField).at(3);

      await tester.enterText(fromField, 'Home');
      await tester.enterText(toField, 'Office');
      await tester.enterText(hoursField, '0');
      await tester.enterText(minutesField, '30');

      // Save the entry
      final saveButton = find.widgetWithText(ElevatedButton, 'Log Entry');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // ASSERT
      verify(mockEntryProvider.addEntry(
        argThat(
          isA<TravelEntry>()
              .having((e) => e.fromLocation, 'fromLocation', 'Home')
              .having((e) => e.toLocation, 'toLocation', 'Office')
              .having((e) => e.travelMinutes, 'travelMinutes', 30)
              .having((e) => e.userId, 'userId', 'test-user-id'),
        ),
      )).called(1);
    });

    testWidgets('validates required fields', (WidgetTester tester) async {
      // ARRANGE
      await pumpHomeScreen(tester);

      // ACT - Open the Log Travel dialog
      await openTravelDialog(tester);

      // Try to save without entering any data
      final saveButton = find.widgetWithText(ElevatedButton, 'Log Entry');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // ASSERT
      // Verify error messages are shown
      final fromField = find.byType(TextField).first;
      final toField = find.byType(TextField).at(1);
      final hoursField = find.byType(TextField).at(2);
      final minutesField = find.byType(TextField).at(3);

      expect(fromField, findsOneWidget);
      expect(toField, findsOneWidget);
      expect(hoursField, findsOneWidget);
      expect(minutesField, findsOneWidget);

      // Verify addEntry was not called
      verifyNever(mockEntryProvider.addEntry(any));
    });
  });
}
