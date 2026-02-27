import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/models/absence.dart';
import 'package:myapp/models/absence_entry_adapter.dart';
import 'package:myapp/models/balance_adjustment.dart';
import 'package:myapp/models/balance_adjustment_adapter.dart';
import 'package:myapp/providers/absence_provider.dart';
import 'package:myapp/providers/balance_adjustment_provider.dart';
import 'package:myapp/repositories/balance_adjustment_repository.dart';
import 'package:myapp/services/supabase_absence_service.dart';
import 'package:myapp/services/supabase_auth_service.dart';
import 'package:myapp/services/sync_queue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuthService extends Fake implements SupabaseAuthService {
  FakeAuthService(this._user);
  final User _user;

  @override
  User? get currentUser => _user;
}

class FakeAbsenceService extends Fake implements SupabaseAbsenceService {
  int addCalls = 0;

  @override
  Future<List<AbsenceEntry>> fetchAbsencesForYear(
      String userId, int year) async {
    return <AbsenceEntry>[];
  }

  @override
  Future<String> addAbsence(String userId, AbsenceEntry absence) async {
    addCalls++;
    return absence.id ?? 'remote';
  }

  @override
  Future<void> updateAbsence(
    String userId,
    String absenceId,
    AbsenceEntry absence,
  ) async {}

  @override
  Future<void> deleteAbsence(String userId, String absenceId) async {}
}

class FakeBalanceAdjustmentRepository extends Fake
    implements BalanceAdjustmentRepository {
  int createCalls = 0;

  @override
  Future<List<BalanceAdjustment>> listAdjustmentsRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return <BalanceAdjustment>[];
  }

  @override
  Future<List<BalanceAdjustment>> listAdjustmentsForYear({
    required String userId,
    required int year,
  }) async {
    return <BalanceAdjustment>[];
  }

  @override
  Future<List<BalanceAdjustment>> listAllAdjustments({
    required String userId,
  }) async {
    return <BalanceAdjustment>[];
  }

  @override
  Future<BalanceAdjustment> createAdjustment({
    String? id,
    required String userId,
    required DateTime effectiveDate,
    required int deltaMinutes,
    String? note,
  }) async {
    createCalls++;
    return BalanceAdjustment(
      id: id,
      userId: userId,
      effectiveDate: effectiveDate,
      deltaMinutes: deltaMinutes,
      note: note,
    );
  }

  @override
  Future<BalanceAdjustment> updateAdjustment({
    required String id,
    required String userId,
    required DateTime effectiveDate,
    required int deltaMinutes,
    String? note,
  }) async {
    return BalanceAdjustment(
      id: id,
      userId: userId,
      effectiveDate: effectiveDate,
      deltaMinutes: deltaMinutes,
      note: note,
    );
  }

  @override
  Future<void> deleteAdjustment({
    required String id,
    required String userId,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<AbsenceEntry> absenceBox;
  late Box<BalanceAdjustment> adjustmentBox;

  late FakeAuthService authService;
  late FakeAbsenceService absenceService;
  late FakeBalanceAdjustmentRepository adjustmentRepository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('offline_sync_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(AbsenceEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(BalanceAdjustmentAdapter());
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    absenceBox = await Hive.openBox<AbsenceEntry>('absence_offline_sync_test');
    adjustmentBox =
        await Hive.openBox<BalanceAdjustment>('adjustment_offline_sync_test');

    final user = User(
      id: 'user_a',
      appMetadata: const <String, dynamic>{},
      userMetadata: const <String, dynamic>{},
      aud: 'authenticated',
      createdAt: DateTime(2026, 1, 1).toIso8601String(),
    );

    authService = FakeAuthService(user);
    absenceService = FakeAbsenceService();
    adjustmentRepository = FakeBalanceAdjustmentRepository();
  });

  tearDown(() async {
    await absenceBox.clear();
    await adjustmentBox.clear();
    await absenceBox.close();
    await adjustmentBox.close();
    await Hive.deleteBoxFromDisk('absence_offline_sync_test');
    await Hive.deleteBoxFromDisk('adjustment_offline_sync_test');
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'offline absence save updates local cache and queues absence_create',
    () async {
      final syncQueue = SyncQueueService(
        absenceService: absenceService,
        adjustmentRepository: adjustmentRepository,
      );
      final provider = AbsenceProvider(
        authService,
        absenceService,
        syncQueue: syncQueue,
        offlineCheck: () async => true,
      );
      await provider.initHive(absenceBox);

      final entry = AbsenceEntry(
        date: DateTime(2026, 3, 12),
        minutes: 0,
        type: AbsenceType.vacationPaid,
      );

      await provider.addAbsenceEntry(entry);

      expect(provider.lastWriteQueuedOffline, isTrue);
      expect(provider.absencesForYear(2026).length, 1);
      expect(provider.pendingSyncCount, 1);
      expect(absenceService.addCalls, 0);
      final queued = syncQueue.pendingOperations.where(
        (op) => op.type == SyncOperationType.absenceCreate,
      );
      expect(queued.length, 1);
    },
  );

  test(
    'adjustment queued offline is cleared after successful queue processing',
    () async {
      final syncQueue = SyncQueueService(
        absenceService: absenceService,
        adjustmentRepository: adjustmentRepository,
      );
      final provider = BalanceAdjustmentProvider(
        authService,
        adjustmentRepository,
        syncQueue: syncQueue,
        offlineCheck: () async => true,
      );
      await provider.initHive(adjustmentBox);

      await provider.addAdjustment(
        effectiveDate: DateTime(2026, 3, 15),
        deltaMinutes: 120,
        note: 'Offline adjustment',
      );

      expect(provider.lastWriteQueuedOffline, isTrue);
      expect(provider.pendingSyncCount, 1);
      expect(
        syncQueue.pendingOperations
            .where((op) => op.type == SyncOperationType.adjustmentCreate)
            .length,
        1,
      );

      final result = await provider.processPendingSync();

      expect(result.succeeded, 1);
      expect(provider.pendingSyncCount, 0);
      expect(
        syncQueue.pendingOperations
            .where((op) => op.type == SyncOperationType.adjustmentCreate)
            .isEmpty,
        isTrue,
      );
      expect(adjustmentRepository.createCalls, greaterThanOrEqualTo(1));
    },
  );
}
