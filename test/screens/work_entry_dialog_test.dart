import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:myapp/screens/unified_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/repositories/repository_provider.dart';
import 'package:myapp/repositories/work_repository.dart';
import 'package:myapp/services/auth_service.dart';

import 'work_entry_dialog_test.mocks.dart';

@GenerateMocks([
  RepositoryProvider,
  WorkRepository,
  AuthService,
  User,
])
void main() {
  group('WorkEntryDialog', () {
    late MockRepositoryProvider mockRepositoryProvider;
    late MockWorkRepository mockWorkRepository;
    late MockAuthService mockAuthService;
    late MockUser mockUser;
    late GoRouter router;

    setUp(() {
      mockRepositoryProvider = MockRepositoryProvider();
      mockWorkRepository = MockWorkRepository();
      mockAuthService = MockAuthService();
      mockUser = MockUser();

      when(mockRepositoryProvider.workRepository)
          .thenReturn(mockWorkRepository);
      when(mockWorkRepository.getAllForUser(any)).thenReturn([]);
      when(mockWorkRepository.add(any))
          .thenAnswer((invocation) async => invocation.positionalArguments[0]);

      // Mock currentUser with uid
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockAuthService.currentUser).thenReturn(mockUser);
      when(mockAuthService.isInitialized).thenReturn(true);
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockAuthService.isInitialized).thenReturn(true);
      when(mockAuthService.isAuthenticated).thenReturn(true);

      router = GoRouter(routes: [
        GoRoute(
            path: '/', builder: (context, state) => const SizedBox.shrink()),
      ]);
    });

    Future<void> pumpDialog(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return MultiProvider(
                  providers: [
                    Provider<RepositoryProvider>.value(
                        value: mockRepositoryProvider),
                    ChangeNotifierProvider<AuthService>.value(
                        value: mockAuthService),
                  ],
                  child: const SizedBox.shrink(),
                );
              },
            ),
          ),
        ),
      );
      showDialog(
        context: tester.element(find.byType(Scaffold)),
        builder: (_) => const WorkEntryDialog(enableSuggestions: false),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('saves work entry', (tester) async {
      await pumpDialog(tester);

      // Fill first shift: 1h 30m
      // Start and End time fields are the first two TextFields
      final startField = find.byType(TextField).at(0);
      final endField = find.byType(TextField).at(1);

      await tester.enterText(startField, '9:00 AM');
      await tester.pump();
      await tester.enterText(endField, '10:30 AM');
      await tester.pump();

      // Save
      final saveButton = find.widgetWithText(ElevatedButton, 'Log Entry');
      final btn = tester.widget<ElevatedButton>(saveButton);
      expect(btn.onPressed, isNotNull);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      verify(mockWorkRepository.add(any)).called(1);
    });
  });
}

class FakeUser extends Mock implements Object {
  final String uid;
  FakeUser(this.uid);
}
