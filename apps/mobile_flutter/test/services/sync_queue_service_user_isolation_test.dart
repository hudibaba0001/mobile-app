import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/models/absence.dart';
import 'package:myapp/models/balance_adjustment.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/services/sync_queue_service.dart';

class _FakeErrorWithCode implements Exception {
  final String code;
  final String message;

  const _FakeErrorWithCode(this.code, this.message);

  @override
  String toString() => message;
}

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

    test(
        'processQueue persists each successful op immediately so completed ops survive mid-run interruption',
        () async {
      await service.queueCreate(
        createEntry(userId: 'user_a', id: 'a1'),
        'user_a',
      );
      await service.queueCreate(
        createEntry(userId: 'user_a', id: 'a2'),
        'user_a',
      );

      final secondStarted = Completer<void>();
      final releaseSecond = Completer<void>();

      final processingFuture = service.processQueue(
        (operation) async {
          if (operation.entryId == 'a2') {
            if (!secondStarted.isCompleted) {
              secondStarted.complete();
            }
            await releaseSecond.future;
          }
        },
        userId: 'user_a',
      );

      await secondStarted.future;

      final reloaded = SyncQueueService();
      await reloaded.init();

      // First op (a1) should already be removed/persisted while a2 is in-flight.
      expect(
          reloaded.pendingOperations.any((op) => op.entryId == 'a1'), isFalse);
      expect(
          reloaded.pendingOperations.any((op) => op.entryId == 'a2'), isTrue);

      releaseSecond.complete();
      await processingFuture;
    });

    test('duplicate 23505 errors for create operations are treated as success',
        () async {
      await service.queueCreate(
        createEntry(userId: 'user_a', id: 'entry_a1'),
        'user_a',
      );
      await service.queueAbsenceCreate(
        AbsenceEntry(
          id: 'absence_a1',
          date: DateTime(2026, 2, 3),
          minutes: 0,
          type: AbsenceType.vacationPaid,
        ),
        'user_a',
      );
      await service.queueAdjustmentCreate(
        BalanceAdjustment(
          id: 'adjustment_a1',
          userId: 'user_a',
          effectiveDate: DateTime(2026, 2, 3),
          deltaMinutes: 30,
          note: 'duplicate tolerance',
        ),
        'user_a',
      );

      final result = await service.processQueue((operation) async {
        throw const _FakeErrorWithCode(
          '23505',
          'already exists',
        );
      }, userId: 'user_a');

      expect(result.processed, 3);
      expect(result.succeeded, 3);
      expect(result.failed, 0);
      expect(service.pendingCountForUser('user_a'), 0);
    });

    test(
        'structured non-23505 code is not treated as success even if message says already exists',
        () async {
      await service.queueCreate(
        createEntry(userId: 'user_a', id: 'entry_a1'),
        'user_a',
      );

      final result = await service.processQueue((operation) async {
        throw const _FakeErrorWithCode(
          '42501',
          'already exists',
        );
      }, userId: 'user_a');

      expect(result.processed, 1);
      expect(result.succeeded, 0);
      expect(result.failed, 1);
      expect(service.pendingCountForUser('user_a'), 1);
      final queued = service.pendingOperations.firstWhere(
        (op) => op.entryId == 'entry_a1' && op.userId == 'user_a',
      );
      expect(queued.retryCount, 1);
    });
  });
}
