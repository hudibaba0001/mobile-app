import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:myapp/services/admin_api_service.dart';
import 'package:myapp/models/admin_user.dart';
import 'package:myapp/viewmodels/admin_users_view_model.dart';

@GenerateMocks([AdminApiService])
import 'admin_users_view_model_test.mocks.dart';

void main() {
  late MockAdminApiService mockAdminApiService;
  late AdminUsersViewModel viewModel;
  late List<AdminUser> mockUsers;

  setUp(() {
    mockAdminApiService = MockAdminApiService();
    // Don't stub fetchUsers here - each test should set up its own expectations
    viewModel = AdminUsersViewModel(mockAdminApiService);
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

  test('initial state is correct', () {
    expect(viewModel.users, isNull);
    expect(viewModel.error, isNull);
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.filterRole, equals('All'));
    expect(viewModel.searchQuery, isNull);
  });

  group('fetchUsers', () {
    test('successful fetch updates state correctly', () async {
      when(mockAdminApiService.fetchUsers()).thenAnswer((_) async => mockUsers);

      await viewModel.fetchUsers();

      expect(viewModel.users, equals(mockUsers));
      expect(viewModel.error, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('failed fetch updates error state', () async {
      when(mockAdminApiService.fetchUsers()).thenThrow('Test error');

      await viewModel.fetchUsers();

      expect(viewModel.users, isNull);
      expect(viewModel.error, equals('Test error'));
      expect(viewModel.isLoading, isFalse);
    });
  });

  group('filtering', () {
    setUp(() {
      when(mockAdminApiService.fetchUsers()).thenAnswer((_) async => mockUsers);
      viewModel.fetchUsers();
    });

    test('search filter works correctly', () {
      viewModel.setSearchQuery('user1');
      expect(viewModel.filteredUsers.length, equals(1));
      expect(viewModel.filteredUsers.first.uid, equals('user1'));

      viewModel.setSearchQuery('nonexistent');
      expect(viewModel.filteredUsers.isEmpty, isTrue);

      viewModel.setSearchQuery(null);
      expect(viewModel.filteredUsers.length, equals(mockUsers.length));
    });

    test('role filter is prepared for future implementation', () {
      viewModel.setFilterRole('Admin');
      // Currently returns all users as role filtering is not implemented
      expect(viewModel.filteredUsers.length, equals(mockUsers.length));
    });
  });

  group('user operations', () {
    setUp(() {
      when(mockAdminApiService.fetchUsers()).thenAnswer((_) async => mockUsers);
      // Fetch users initially to set up the state
      viewModel.fetchUsers();
    });

    test('disableUser success path', () async {
      when(mockAdminApiService.disableUser('user1')).thenAnswer((_) async {
        return;
      });

      final success = await viewModel.disableUser(mockUsers[0]);

      verify(mockAdminApiService.disableUser('user1')).called(1);
      verify(mockAdminApiService.fetchUsers())
          .called(2); // Initial + after disable
      expect(success, isTrue);
      expect(viewModel.error, isNull);
    });

    test('enableUser success path', () async {
      when(mockAdminApiService.enableUser('user2')).thenAnswer((_) async {
        return;
      });

      final success = await viewModel.enableUser(mockUsers[1]);

      verify(mockAdminApiService.enableUser('user2')).called(1);
      verify(mockAdminApiService.fetchUsers())
          .called(2); // Initial + after enable
      expect(success, isTrue);
      expect(viewModel.error, isNull);
    });

    test('deleteUser success path', () async {
      when(mockAdminApiService.deleteUser('user1')).thenAnswer((_) async {
        return;
      });

      final success = await viewModel.deleteUser(mockUsers[0]);

      verify(mockAdminApiService.deleteUser('user1')).called(1);
      verify(mockAdminApiService.fetchUsers())
          .called(2); // Initial + after delete
      expect(success, isTrue);
      expect(viewModel.error, isNull);
    });

    test('operation failure sets error state', () async {
      when(mockAdminApiService.deleteUser('user1')).thenThrow('Test error');

      final success = await viewModel.deleteUser(mockUsers[0]);

      expect(success, isFalse);
      expect(viewModel.error, equals('Test error'));
    });
  });
}
