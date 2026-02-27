import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/absence.dart';
import '../models/balance_adjustment.dart';
import '../models/entry.dart';
import '../repositories/balance_adjustment_repository.dart';
import '../services/profile_service.dart';
import '../services/supabase_absence_service.dart';
import '../services/supabase_entry_service.dart';
import '../utils/retry_helper.dart';

/// Types of sync operations that can be queued
enum SyncOperationType {
  create,
  update,
  delete,
  absenceCreate,
  absenceUpdate,
  absenceDelete,
  adjustmentCreate,
  adjustmentUpdate,
  adjustmentDelete,
  contractUpdate,
}

/// Represents a pending sync operation
class SyncOperation {
  final String id;
  final SyncOperationType type;
  final String entryId;
  final String userId;
  final Map<String, dynamic>? entryData; // For create/update operations
  final DateTime createdAt;
  int retryCount;
  String? lastError;

  SyncOperation({
    required this.id,
    required this.type,
    required this.entryId,
    required this.userId,
    this.entryData,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'entryId': entryId,
        'userId': userId,
        'entryData': entryData,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
      };

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      type: SyncOperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SyncOperationType.create,
      ),
      entryId: json['entryId'] as String,
      userId: json['userId'] as String,
      entryData: json['entryData'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
    );
  }
}

/// Service for managing a queue of failed sync operations
/// Persists queue to SharedPreferences for survival across app restarts
class SyncQueueService extends ChangeNotifier {
  static const String _queueKey = 'sync_queue';
  static const int maxRetries = 5;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Set<SyncOperationType> entryOperationTypes = {
    SyncOperationType.create,
    SyncOperationType.update,
    SyncOperationType.delete,
  };
  static const Set<SyncOperationType> absenceOperationTypes = {
    SyncOperationType.absenceCreate,
    SyncOperationType.absenceUpdate,
    SyncOperationType.absenceDelete,
  };
  static const Set<SyncOperationType> adjustmentOperationTypes = {
    SyncOperationType.adjustmentCreate,
    SyncOperationType.adjustmentUpdate,
    SyncOperationType.adjustmentDelete,
  };
  static const Set<SyncOperationType> contractOperationTypes = {
    SyncOperationType.contractUpdate,
  };

  final List<SyncOperation> _queue = [];
  bool _isProcessing = false;
  Future<SyncResult>? _activeProcessFuture;
  bool _initialized = false;
  SupabaseEntryService? _entryService;
  SupabaseAbsenceService? _absenceService;
  BalanceAdjustmentRepository? _adjustmentRepository;
  ProfileService? _profileService;

  SyncQueueService({
    SupabaseEntryService? entryService,
    SupabaseAbsenceService? absenceService,
    BalanceAdjustmentRepository? adjustmentRepository,
    ProfileService? profileService,
  })  : _entryService = entryService,
        _absenceService = absenceService,
        _adjustmentRepository = adjustmentRepository,
        _profileService = profileService;

  List<SyncOperation> get pendingOperations => List.unmodifiable(_queue);
  int get pendingCount => _queue.length;
  bool get hasPendingOperations => _queue.isNotEmpty;
  bool get isProcessing => _isProcessing;

  /// Number of pending operations for a specific user.
  int pendingCountForUser(String userId) {
    return _queue.where((op) => op.userId == userId).length;
  }

  Set<String> pendingEntityIdsForUser(
    String userId, {
    required Set<SyncOperationType> operationTypes,
  }) {
    return _queue
        .where(
          (op) => op.userId == userId && operationTypes.contains(op.type),
        )
        .map((op) => op.entryId)
        .toSet();
  }

  /// Initialize the service and load any persisted queue
  Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);

      if (queueJson != null && queueJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(queueJson);
        _queue.clear();
        for (final item in decoded) {
          try {
            _queue.add(SyncOperation.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            debugPrint('SyncQueueService: Error parsing queued operation: $e');
          }
        }
        debugPrint(
            'SyncQueueService: Loaded ${_queue.length} pending operations from storage');
      }

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('SyncQueueService: Error initializing: $e');
      _initialized = true;
    }
  }

  /// Add a failed operation to the queue
  Future<void> enqueue(SyncOperation operation) async {
    // Check for duplicate operations on the same entry
    final existingIndex = _queue.indexWhere(
      (op) => op.entryId == operation.entryId && op.type == operation.type,
    );

    if (existingIndex != -1) {
      // Replace existing operation with newer one
      _queue[existingIndex] = operation;
      debugPrint(
          'SyncQueueService: Updated existing operation for entry ${operation.entryId}');
    } else {
      _queue.add(operation);
      debugPrint(
          'SyncQueueService: Queued ${operation.type.name} operation for entry ${operation.entryId}');
    }

    await _persist();
    notifyListeners();
  }

  /// Queue a create operation
  Future<void> queueCreate(Entry entry, String userId) async {
    // If a create for this entry already exists, just update its data
    final existingCreate = _queue.indexWhere(
      (op) => op.entryId == entry.id && op.type == SyncOperationType.create,
    );
    if (existingCreate != -1) {
      _queue[existingCreate] = SyncOperation(
        id: _queue[existingCreate].id, // Keep the original ID
        type: SyncOperationType.create,
        entryId: entry.id,
        userId: userId,
        entryData: entry.toJson(),
        createdAt: _queue[existingCreate].createdAt,
        retryCount: _queue[existingCreate].retryCount,
      );
      await _persist();
      notifyListeners();
      debugPrint(
          'SyncQueueService: Updated existing create operation for entry ${entry.id}');
      return;
    }

    await enqueue(SyncOperation(
      id: 'create_${entry.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncOperationType.create,
      entryId: entry.id,
      userId: userId,
      entryData: entry.toJson(),
      createdAt: DateTime.now(),
    ));
  }

  /// Queue an update operation
  Future<void> queueUpdate(Entry entry, String userId) async {
    await enqueue(SyncOperation(
      id: 'update_${entry.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncOperationType.update,
      entryId: entry.id,
      userId: userId,
      entryData: entry.toJson(),
      createdAt: DateTime.now(),
    ));
  }

  /// Queue a delete operation
  Future<void> queueDelete(String entryId, String userId) async {
    // If there's a pending create for this entry, just remove both create and any updates
    // (entry never reached server, so no server-side delete needed)
    final createIndex = _queue.indexWhere(
      (op) => op.entryId == entryId && op.type == SyncOperationType.create,
    );
    if (createIndex != -1) {
      _queue.removeAt(createIndex);
      // Also remove any pending updates for this entry
      _queue.removeWhere(
        (op) => op.entryId == entryId && op.type == SyncOperationType.update,
      );
      debugPrint(
          'SyncQueueService: Removed pending create+updates for deleted entry $entryId');
      await _persist();
      notifyListeners();
      return;
    }

    // Remove any pending updates for this entry
    _queue.removeWhere(
      (op) => op.entryId == entryId && op.type == SyncOperationType.update,
    );

    await enqueue(SyncOperation(
      id: 'delete_${entryId}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncOperationType.delete,
      entryId: entryId,
      userId: userId,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> queueAbsenceCreate(AbsenceEntry absence, String userId) async {
    final absenceId = absence.id;
    if (absenceId == null || absenceId.isEmpty) {
      throw ArgumentError('Absence create queue requires a non-empty id');
    }

    await enqueue(SyncOperation(
      id: 'absence_create_${absenceId}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncOperationType.absenceCreate,
      entryId: absenceId,
      userId: userId,
      entryData: absence.toMap(),
      createdAt: DateTime.now(),
    ));
  }

  Future<void> queueAbsenceUpdate(
    String absenceId,
    AbsenceEntry absence,
    String userId,
  ) async {
    await enqueue(SyncOperation(
      id: 'absence_update_${absenceId}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncOperationType.absenceUpdate,
      entryId: absenceId,
      userId: userId,
      entryData: absence.toMap(),
      createdAt: DateTime.now(),
    ));
  }

  Future<void> queueAbsenceDelete(String absenceId, String userId) async {
    _queue.removeWhere(
      (op) =>
          op.entryId == absenceId &&
          (op.type == SyncOperationType.absenceCreate ||
              op.type == SyncOperationType.absenceUpdate),
    );
    await enqueue(SyncOperation(
      id: 'absence_delete_${absenceId}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncOperationType.absenceDelete,
      entryId: absenceId,
      userId: userId,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> queueAdjustmentCreate(
    BalanceAdjustment adjustment,
    String userId,
  ) async {
    final adjustmentId = adjustment.id;
    if (adjustmentId == null || adjustmentId.isEmpty) {
      throw ArgumentError('Adjustment create queue requires a non-empty id');
    }

    await enqueue(SyncOperation(
      id: 'adjustment_create_${adjustmentId}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncOperationType.adjustmentCreate,
      entryId: adjustmentId,
      userId: userId,
      entryData: adjustment.toMap(),
      createdAt: DateTime.now(),
    ));
  }

  Future<void> queueAdjustmentUpdate(
    String adjustmentId,
    BalanceAdjustment adjustment,
    String userId,
  ) async {
    await enqueue(SyncOperation(
      id: 'adjustment_update_${adjustmentId}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncOperationType.adjustmentUpdate,
      entryId: adjustmentId,
      userId: userId,
      entryData: adjustment.toMap(),
      createdAt: DateTime.now(),
    ));
  }

  Future<void> queueAdjustmentDelete(String adjustmentId, String userId) async {
    _queue.removeWhere(
      (op) =>
          op.entryId == adjustmentId &&
          (op.type == SyncOperationType.adjustmentCreate ||
              op.type == SyncOperationType.adjustmentUpdate),
    );
    await enqueue(SyncOperation(
      id: 'adjustment_delete_${adjustmentId}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncOperationType.adjustmentDelete,
      entryId: adjustmentId,
      userId: userId,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> queueContractUpdate(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    _queue.removeWhere(
      (op) =>
          op.userId == userId && op.type == SyncOperationType.contractUpdate,
    );
    await enqueue(SyncOperation(
      id: 'contract_update_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncOperationType.contractUpdate,
      entryId: userId,
      userId: userId,
      entryData: payload,
      createdAt: DateTime.now(),
    ));
  }

  /// Process all pending operations
  /// [executor] is a function that executes the actual sync operation
  Future<SyncResult> processQueue(
    Future<void> Function(SyncOperation)? executor, {
    String? userId,
    Set<SyncOperationType>? operationTypes,
  }) async {
    final activeFuture = _activeProcessFuture;
    if (activeFuture != null) {
      debugPrint('SyncQueueService: Queue processing already in progress');
      return activeFuture;
    }

    final future = _processQueueInternal(
      executor,
      userId: userId,
      operationTypes: operationTypes,
    );
    _activeProcessFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_activeProcessFuture, future)) {
        _activeProcessFuture = null;
      }
    }
  }

  Future<SyncResult> _processQueueInternal(
    Future<void> Function(SyncOperation)? executor, {
    String? userId,
    Set<SyncOperationType>? operationTypes,
  }) async {
    if (_isProcessing) {
      debugPrint('SyncQueueService: Already processing queue');
      return SyncResult(processed: 0, succeeded: 0, failed: 0);
    }

    final operations = _queue.where((op) {
      if (userId != null && op.userId != userId) return false;
      if (operationTypes != null && !operationTypes.contains(op.type)) {
        return false;
      }
      return true;
    }).toList();

    if (operations.isEmpty) {
      debugPrint('SyncQueueService: No pending operations');
      return SyncResult(processed: 0, succeeded: 0, failed: 0);
    }

    _isProcessing = true;
    notifyListeners();

    int processed = 0;
    int succeeded = 0;
    int failed = 0;
    bool needsFinalPersist = false;

    if (userId == null) {
      debugPrint(
          'SyncQueueService: Processing ${operations.length} pending operations...');
    } else {
      debugPrint(
          'SyncQueueService: Processing ${operations.length} pending operations for user $userId...');
    }

    for (final operation in operations) {
      processed++;
      if (operation.retryCount >= maxRetries) {
        failed++;
        debugPrint(
            'SyncQueueService: Operation ${operation.type.name} for ${operation.entryId} is exhausted (retry ${operation.retryCount}/$maxRetries), keeping in queue');
        continue;
      }

      try {
        await RetryHelper.executeWithRetry(
          () async {
            if (executor != null) {
              await executor(operation);
              return;
            }
            await _executeQueuedOperation(operation);
          },
          maxRetries: 2,
          initialDelay: retryDelay,
          shouldRetry: RetryHelper.shouldRetryNetworkError,
        );

        _queue.removeWhere((op) => op.id == operation.id);
        await _persist();
        succeeded++;
        debugPrint(
            'SyncQueueService: Successfully processed ${operation.type.name} for ${operation.entryId}');
      } catch (e) {
        if (_isCreateLikeOperation(operation.type) &&
            _isDuplicateInsertError(e)) {
          _queue.removeWhere((op) => op.id == operation.id);
          await _persist();
          succeeded++;
          debugPrint(
              'SyncQueueService: Duplicate create detected for ${operation.type.name} ${operation.entryId}; treated as success');
          continue;
        }

        operation.retryCount++;
        operation.lastError = e.toString();
        needsFinalPersist = true;
        failed++;

        if (operation.retryCount >= maxRetries) {
          debugPrint(
              'SyncQueueService: Max retries reached for ${operation.entryId}, keeping operation in queue for manual recovery');
        } else {
          debugPrint(
              'SyncQueueService: Failed to process ${operation.type.name} for ${operation.entryId}: $e (retry ${operation.retryCount}/$maxRetries)');
        }
      }
    }

    if (needsFinalPersist) {
      await _persist();
    }
    _isProcessing = false;
    notifyListeners();

    debugPrint(
        'SyncQueueService: Queue processing complete - Processed: $processed, Succeeded: $succeeded, Failed: $failed');
    return SyncResult(
        processed: processed, succeeded: succeeded, failed: failed);
  }

  bool _isCreateLikeOperation(SyncOperationType type) {
    // Duplicate-as-success is restricted to true create operations only.
    return type == SyncOperationType.create ||
        type == SyncOperationType.absenceCreate ||
        type == SyncOperationType.adjustmentCreate;
  }

  bool _isDuplicateInsertError(Object error) {
    final structuredCode = _extractStructuredErrorCode(error);
    if (structuredCode != null) {
      // If structured code is available, trust it and do not fall back to text.
      return structuredCode == '23505';
    }

    // Last-resort textual fallback for wrapped/untyped errors.
    final lower = error.toString().toLowerCase();
    return lower.contains('duplicate key') ||
        lower.contains('already exists') ||
        lower.contains('unique constraint') ||
        RegExp(r'(^|[^0-9])23505([^0-9]|$)').hasMatch(lower);
  }

  String? _extractStructuredErrorCode(Object error) {
    if (error is PostgrestException) {
      return error.code?.trim();
    }

    if (error is Map) {
      final dynamic code = error['code'];
      if (code != null) {
        return code.toString().trim();
      }
    }

    // Handle typed errors that expose a `code` getter (e.g. wrapped platform/api errors).
    try {
      final dynamic dynamicError = error;
      final dynamic code = dynamicError.code;
      if (code != null) {
        return code.toString().trim();
      }
    } catch (_) {
      // No structured code available.
    }

    return null;
  }

  Future<void> _executeQueuedOperation(SyncOperation operation) async {
    switch (operation.type) {
      case SyncOperationType.create:
        if (operation.entryData == null) return;
        final entry = Entry.fromJson({
          ...operation.entryData!,
          'id': operation.entryId,
          'user_id': operation.userId,
        });
        await (_entryService ??= SupabaseEntryService()).addEntry(entry);
        return;
      case SyncOperationType.update:
        if (operation.entryData == null) return;
        final entry = Entry.fromJson(operation.entryData!);
        await (_entryService ??= SupabaseEntryService()).updateEntry(entry);
        return;
      case SyncOperationType.delete:
        await (_entryService ??= SupabaseEntryService())
            .deleteEntry(operation.entryId, operation.userId);
        return;
      case SyncOperationType.absenceCreate:
        if (operation.entryData == null) return;
        final absence = AbsenceEntry.fromMap({
          ...operation.entryData!,
          'id': operation.entryId,
        });
        await (_absenceService ??= SupabaseAbsenceService())
            .addAbsence(operation.userId, absence);
        return;
      case SyncOperationType.absenceUpdate:
        if (operation.entryData == null) return;
        final absence = AbsenceEntry.fromMap(operation.entryData!);
        await (_absenceService ??= SupabaseAbsenceService())
            .updateAbsence(operation.userId, operation.entryId, absence);
        return;
      case SyncOperationType.absenceDelete:
        await (_absenceService ??= SupabaseAbsenceService())
            .deleteAbsence(operation.userId, operation.entryId);
        return;
      case SyncOperationType.adjustmentCreate:
        if (operation.entryData == null) return;
        final adjustment = BalanceAdjustment.fromMap({
          ...operation.entryData!,
          'id': operation.entryId,
          'user_id': operation.userId,
        });
        await (_adjustmentRepository ??=
                BalanceAdjustmentRepository(Supabase.instance.client))
            .createAdjustment(
          id: operation.entryId,
          userId: operation.userId,
          effectiveDate: adjustment.effectiveDate,
          deltaMinutes: adjustment.deltaMinutes,
          note: adjustment.note,
        );
        return;
      case SyncOperationType.adjustmentUpdate:
        if (operation.entryData == null) return;
        final adjustment = BalanceAdjustment.fromMap({
          ...operation.entryData!,
          'id': operation.entryId,
          'user_id': operation.userId,
        });
        await (_adjustmentRepository ??=
                BalanceAdjustmentRepository(Supabase.instance.client))
            .updateAdjustment(
          id: operation.entryId,
          userId: operation.userId,
          effectiveDate: adjustment.effectiveDate,
          deltaMinutes: adjustment.deltaMinutes,
          note: adjustment.note,
        );
        return;
      case SyncOperationType.adjustmentDelete:
        await (_adjustmentRepository ??=
                BalanceAdjustmentRepository(Supabase.instance.client))
            .deleteAdjustment(
          id: operation.entryId,
          userId: operation.userId,
        );
        return;
      case SyncOperationType.contractUpdate:
        final data = operation.entryData ?? const <String, dynamic>{};
        final trackingStartDateRaw = data['trackingStartDate'] as String?;
        DateTime? trackingStartDate;
        if (trackingStartDateRaw != null && trackingStartDateRaw.isNotEmpty) {
          trackingStartDate = DateTime.tryParse(trackingStartDateRaw);
        }

        await (_profileService ??= ProfileService()).updateContractSettings(
          contractPercent: (data['contractPercent'] as num?)?.toInt() ?? 100,
          fullTimeHours: (data['fullTimeHours'] as num?)?.toInt() ?? 40,
          trackingStartDate: trackingStartDate,
          openingFlexMinutes:
              (data['openingFlexMinutes'] as num?)?.toInt() ?? 0,
          employerMode: (data['employerMode'] as String?) ?? 'standard',
        );
        return;
    }
  }

  /// Remove a specific operation from the queue
  Future<void> remove(String operationId) async {
    _queue.removeWhere((op) => op.id == operationId);
    await _persist();
    notifyListeners();
  }

  /// Clear all pending operations
  Future<void> clearAll() async {
    _queue.clear();
    await _persist();
    notifyListeners();
    debugPrint('SyncQueueService: Cleared all pending operations');
  }

  /// Clear pending operations for a specific user only.
  Future<void> clearForUser(String userId) async {
    final before = _queue.length;
    _queue.removeWhere((op) => op.userId == userId);
    if (_queue.length == before) {
      return;
    }
    await _persist();
    notifyListeners();
    debugPrint(
        'SyncQueueService: Cleared ${before - _queue.length} operations for user $userId');
  }

  /// Keep only pending operations for a specific user.
  Future<void> clearAllExceptUser(String userId) async {
    final before = _queue.length;
    _queue.removeWhere((op) => op.userId != userId);
    if (_queue.length == before) {
      return;
    }
    await _persist();
    notifyListeners();
    debugPrint(
        'SyncQueueService: Removed ${before - _queue.length} operations for non-active users');
  }

  /// Persist the queue to SharedPreferences
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = jsonEncode(_queue.map((op) => op.toJson()).toList());
      await prefs.setString(_queueKey, queueJson);
    } catch (e) {
      debugPrint('SyncQueueService: Error persisting queue: $e');
    }
  }
}

/// Result of processing the sync queue
class SyncResult {
  final int processed;
  final int succeeded;
  final int failed;

  SyncResult({
    required this.processed,
    required this.succeeded,
    required this.failed,
  });

  bool get hasFailures => failed > 0;
  bool get allSucceeded => processed > 0 && failed == 0;
}
