import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/providers/contract_provider.dart';
import 'package:myapp/services/sync_queue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('contract offline save queues contract_update and clears after sync',
      () async {
    SharedPreferences.setMockInitialValues({});

    int remoteSaveCalls = 0;
    final syncQueue = SyncQueueService();

    final provider = ContractProvider(
      syncQueue: syncQueue,
      offlineCheck: () async => true,
      currentUserIdProvider: () => 'user_a',
      remoteSaveContract: ({
        required int contractPercent,
        required int fullTimeHours,
        DateTime? trackingStartDate,
        required int openingFlexMinutes,
        required String employerMode,
      }) async {
        remoteSaveCalls++;
        return true;
      },
    );

    await provider.init();

    await provider.updateContractSettings(75, 40);

    expect(provider.lastWriteQueuedOffline, isTrue);
    expect(provider.pendingSyncCount, 1);
    expect(
      syncQueue.pendingOperations
          .where((op) => op.type == SyncOperationType.contractUpdate)
          .length,
      1,
    );

    // Simulate reconnect: allow sync and process queue.
    final syncedProvider = ContractProvider(
      syncQueue: syncQueue,
      offlineCheck: () async => false,
      currentUserIdProvider: () => 'user_a',
      remoteSaveContract: ({
        required int contractPercent,
        required int fullTimeHours,
        DateTime? trackingStartDate,
        required int openingFlexMinutes,
        required String employerMode,
      }) async {
        remoteSaveCalls++;
        return true;
      },
    );
    await syncedProvider.init();

    final result = await syncedProvider.processPendingSync();

    expect(result.succeeded, 1);
    expect(syncedProvider.pendingSyncCount, 0);
    expect(remoteSaveCalls, greaterThanOrEqualTo(1));
  });
}
