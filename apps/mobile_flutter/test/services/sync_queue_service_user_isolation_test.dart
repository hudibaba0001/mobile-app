import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/services/sync_queue_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncQueueService user isolation', () {
    late SyncQueueService service;

    Entry createEntry({
      required String userId,
      required String id,
    }) {
      return Entry(
        id: id,
        userId: userId,
        type: EntryType.travel,
        date: DateTime(2026, 1, 1),
        from: 'From',
        to: 'To',
        travelMinutes: 15,
        createdAt: DateTime(2026, 1, 1),
      );
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = SyncQueueService();
      await service.init();
    });

    test(
        'processQueue(userId) processes only active user operations and keeps others pending',
        () async {
      await service.queueCreate(
        createEntry(userId: 'user_a', id: 'a1'),
        'user_a',
      );
      await service.queueCreate(
        createEntry(userId: 'user_b', id: 'b1'),
        'user_b',
      );

      final processedUserIds = <String>[];
      final result = await service.processQueue((operation) async {
        processedUserIds.add(operation.userId);
      }, userId: 'user_a');

      expect(result.processed, 1);
      expect(result.succeeded, 1);
      expect(result.failed, 0);
      expect(processedUserIds, ['user_a']);
      expect(service.pendingCountForUser('user_a'), 0);
      expect(service.pendingCountForUser('user_b'), 1);
    });

    test('clearAllExceptUser removes non-active user pending operations',
        () async {
      await service.queueCreate(
        createEntry(userId: 'user_a', id: 'a1'),
        'user_a',
      );
      await service.queueCreate(
        createEntry(userId: 'user_a', id: 'a2'),
        'user_a',
      );
      await service.queueCreate(
        createEntry(userId: 'user_b', id: 'b1'),
        'user_b',
      );

      await service.clearAllExceptUser('user_a');

      expect(service.pendingCountForUser('user_a'), 2);
      expect(service.pendingCountForUser('user_b'), 0);
      expect(service.pendingCount, 2);
    });

    test('max-retry failures stay queued instead of being dropped', () async {
      await service.queueCreate(
        createEntry(userId: 'user_a', id: 'a1'),
        'user_a',
      );

      for (var i = 0; i < SyncQueueService.maxRetries + 2; i++) {
        await service.processQueue(
          (operation) async {
            throw Exception('400 forced failure');
          },
          userId: 'user_a',
        );
      }

      expect(service.pendingCountForUser('user_a'), 1);
      final operation = service.pendingOperations.firstWhere(
        (op) => op.userId == 'user_a' && op.entryId == 'a1',
      );
      expect(operation.retryCount, SyncQueueService.maxRetries);
      expect(operation.lastError, isNotNull);
    });
  });
}
