import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:myapp/screens/admin_users_screen.dart';
import 'package:myapp/services/admin_api_service.dart';
import 'package:myapp/models/admin_user.dart';

@GenerateMocks([AdminApiService])
import 'admin_users_screen_test.mocks.dart';

void main() {
  late MockAdminApiService mockAdminApiService;
  late List<AdminUser> mockUsers;

  setUp(() {
    mockAdminApiService = MockAdminApiService();
    mockUsers = [
      AdminUser(
        uid: 'user1',
        email: 'user1@test.com',
        displayName: 'Test User 1',
        disabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      AdminUser(
        uid: 'user2',
        email: 'user2@test.com',
        displayName: 'Test User 2',
        disabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: Provider<AdminApiService>.value(
        value: mockAdminApiService,
        child: const AdminUsersScreen(),
      ),
    );
  }

  testWidgets('displays user list correctly', (WidgetTester tester) async {
    when(mockAdminApiService.fetchUsers()).thenAnswer((_) async => mockUsers);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify users are displayed
    expect(find.text('Test User 1'), findsOneWidget);
    expect(find.text('Test User 2'), findsOneWidget);
    expect(find.text('user1@test.com'), findsOneWidget);
    expect(find.text('user2@test.com'), findsOneWidget);
  });

  testWidgets('disable button calls disableUser', (WidgetTester tester) async {
    when(mockAdminApiService.fetchUsers()).thenAnswer((_) async => mockUsers);
    when(mockAdminApiService.disableUser(any)).thenAnswer((_) async {
      return;
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Find and tap the Disable button for the first (enabled) user
    final disableButton = find.widgetWithText(OutlinedButton, 'Disable').first;
    await tester.tap(disableButton);
    await tester.pumpAndSettle();

    // Verify confirmation dialog appears
    expect(find.text('Disable User'), findsOneWidget);
    expect(find.text('Are you sure you want to disable Test User 1?'), findsOneWidget);

    // Confirm disable
    final confirmButton = find.widgetWithText(FilledButton, 'Disable');
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    // Verify service was called
    verify(mockAdminApiService.disableUser('user1')).called(1);
  });

  testWidgets('enable button calls enableUser', (WidgetTester tester) async {
    when(mockAdminApiService.fetchUsers()).thenAnswer((_) async => mockUsers);
    when(mockAdminApiService.enableUser(any)).thenAnswer((_) async {
      return;
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Find and tap the Enable button for the second (disabled) user
    final enableButton = find.widgetWithText(OutlinedButton, 'Enable').first;
    await tester.tap(enableButton);
    await tester.pumpAndSettle();

    // Verify confirmation dialog appears
    expect(find.text('Enable User'), findsOneWidget);
    expect(find.text('Are you sure you want to enable Test User 2?'), findsOneWidget);

    // Confirm enable
    final confirmButton = find.widgetWithText(FilledButton, 'Enable');
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    // Verify service was called
    verify(mockAdminApiService.enableUser('user2')).called(1);
  });

  testWidgets('delete confirmation dialog appears correctly', (WidgetTester tester) async {
    when(mockAdminApiService.fetchUsers()).thenAnswer((_) async => mockUsers);
    when(mockAdminApiService.deleteUser(any)).thenAnswer((_) async {
      return;
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Open the popup menu
    final menuButton = find.byIcon(Icons.more_vert).first;
    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    // Tap delete option
    final deleteOption = find.text('Delete');
    await tester.tap(deleteOption);
    await tester.pumpAndSettle();

    // Verify dialog appears with correct content
    expect(find.text('Confirm Permanent Deletion'), findsOneWidget);
    expect(
      find.text('Warning: This action cannot be undone. All user data will be permanently deleted.'),
      findsOneWidget,
    );
    expect(find.text('Type DELETE to confirm:'), findsOneWidget);

    // Verify delete button is initially disabled
    final deleteButton = find.widgetWithText(FilledButton, 'Confirm Delete');
    expect(tester.widget<FilledButton>(deleteButton).onPressed, isNull);

         // Type incorrect confirmation
     await tester.enterText(find.byType(TextField).last, 'delete');
     await tester.pump();
     expect(tester.widget<FilledButton>(deleteButton).onPressed, isNull);

     // Type correct confirmation
     await tester.enterText(find.byType(TextField).last, 'DELETE');
     await tester.pump();
    expect(tester.widget<FilledButton>(deleteButton).onPressed, isNotNull);

    // Confirm deletion
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Verify service was called
    verify(mockAdminApiService.deleteUser('user1')).called(1);
  });
}