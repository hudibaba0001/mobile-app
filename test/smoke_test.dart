import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myapp/main.dart' as app;
import 'package:myapp/config/app_router.dart';
import 'package:myapp/services/supabase_auth_service.dart';
import 'package:myapp/models/user_profile.dart'; // Import UserProfile
import 'package:myapp/services/profile_service.dart'; // Import ProfileService

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end Smoke Tests', () {
    setUpAll(() async {
      // Mock Supabase initialization for tests
      // Ensure Supabase is initialized only once for all tests
      await Supabase.initialize(
        url: 'https://test.supabase.co', // Dummy URL
        anonKey: 'dummy_anon_key', // Dummy Anon Key
      );
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('App boots successfully', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('AccountStatusGate blocks unauthenticated users', (WidgetTester tester) async {
      // Start the app with unauthenticated state
      final authService = SupabaseAuthService(); // Assuming it starts unauthenticated
      await tester.pumpWidget(
        Provider<SupabaseAuthService>.value(
          value: authService,
          child: app.MyApp(authService: authService, localeProvider: app.LocaleProvider()),
        ),
      );
      await tester.pumpAndSettle();

      // Expect to be on the login screen
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('AccountStatusGate allows users with active subscription', (WidgetTester tester) async {
      // Mock an authenticated user with an active subscription
      final authService = SupabaseAuthService();
      // Mock an authenticated user
      when(authService.isAuthenticated).thenReturn(true);
      when(authService.isInitialized).thenReturn(true);
      when(authService.currentUser).thenReturn(User(id: 'test-user-id', email: 'test@example.com', appMetadata: {}, userMetadata: {}, createdAt: DateTime.now().toIso8601String()));

      // Mock the ProfileService to return a profile with active subscription
      final mockProfileService = ProfileService();
      when(mockProfileService.fetchProfile()).thenAnswer((_) async => UserProfile(id: 'test-user-id', subscriptionStatus: 'active', hasAcceptedLegal: true));


      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SupabaseAuthService>.value(value: authService),
            Provider<ProfileService>.value(value: mockProfileService), // Provide mock ProfileService
            ChangeNotifierProvider<app.LocaleProvider>.value(value: app.LocaleProvider()),
          ],
          child: app.MyApp(authService: authService, localeProvider: app.LocaleProvider()),
        ),
      );
      await tester.pumpAndSettle();

      // Expect to be on the home screen
      expect(find.byType(UnifiedHomeScreen), findsOneWidget);
    });

    testWidgets('Export function can be triggered without crashing', (WidgetTester tester) async {
      // Mock an authenticated user with an active subscription (as above)
      final authService = SupabaseAuthService();
      when(authService.isAuthenticated).thenReturn(true);
      when(authService.isInitialized).thenReturn(true);
      when(authService.currentUser).thenReturn(User(id: 'test-user-id', email: 'test@example.com', appMetadata: {}, userMetadata: {}, createdAt: DateTime.now().toIso8601String()));

      final mockProfileService = ProfileService();
      when(mockProfileService.fetchProfile()).thenAnswer((_) async => UserProfile(id: 'test-user-id', subscriptionStatus: 'active', hasAcceptedLegal: true));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SupabaseAuthService>.value(value: authService),
            Provider<ProfileService>.value(value: mockProfileService),
            ChangeNotifierProvider<app.LocaleProvider>.value(value: app.LocaleProvider()),
          ],
          child: app.MyApp(authService: authService, localeProvider: app.LocaleProvider()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the export time report button
      await tester.tap(find.text('Export Time'));
      await tester.pumpAndSettle();

      // Expect a dialog to appear (CSV/Excel choice)
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap CSV option
      await tester.tap(find.text('CSV'));
      await tester.pumpAndSettle();

      // Expect a success snackbar (or no crash)
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Export successful!'), findsOneWidget); // Assuming this is the success message
    });

    testWidgets('Time balance screen loads correctly', (WidgetTester tester) async {
      // Mock an authenticated user with an active subscription (as above)
      final authService = SupabaseAuthService();
      when(authService.isAuthenticated).thenReturn(true);
      when(authService.isInitialized).thenReturn(true);
      when(authService.currentUser).thenReturn(User(id: 'test-user-id', email: 'test@example.com', appMetadata: {}, userMetadata: {}, createdAt: DateTime.now().toIso8601String()));

      final mockProfileService = ProfileService();
      when(mockProfileService.fetchProfile()).thenAnswer((_) async => UserProfile(id: 'test-user-id', subscriptionStatus: 'active', hasAcceptedLegal: true));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SupabaseAuthService>.value(value: authService),
            Provider<ProfileService>.value(value: mockProfileService),
            ChangeNotifierProvider<app.LocaleProvider>.value(value: app.LocaleProvider()),
          ],
          child: app.MyApp(authService: authService, localeProvider: app.LocaleProvider()),
        ),
      );
      await tester.pumpAndSettle();

      // Expect FlexsaldoCard (which displays time balance) to be present
      expect(find.byType(FlexsaldoCard), findsOneWidget);
      // Also check for some text that would indicate data is loaded
      expect(find.textContaining(RegExp(r'\+\d+\.\d h|\-\d+\.\d h')), findsOneWidget);
    });
  });
}