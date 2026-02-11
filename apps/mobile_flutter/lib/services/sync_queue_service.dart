import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/entry.dart';
import '../utils/retry_helper.dart';

/// Types of sync operations that can be queued
enum SyncOperationType {
  create,
  update,
  delete,
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

  final List<SyncOperation> _queue = [];
  bool _isProcessing = false;
  bool _initialized = false;

  List<SyncOperation> get pendingOperations => List.unmodifiable(_queue);
  int get pendingCount => _queue.length;
  bool get hasPendingOperations => _queue.isNotEmpty;
  bool get isProcessing => _isProcessing;

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

  /// Process all pending operations
  /// [executor] is a function that executes the actual sync operation
  Future<SyncResult> processQueue(
    Future<void> Function(SyncOperation) executor,
  ) async {
    if (_isProcessing) {
      debugPrint('SyncQueueService: Already processing queue');
      return SyncResult(processed: 0, succeeded: 0, failed: 0);
    }

    if (_queue.isEmpty) {
      debugPrint('SyncQueueService: No pending operations');
      return SyncResult(processed: 0, succeeded: 0, failed: 0);
    }

    _isProcessing = true;
    notifyListeners();

    int processed = 0;
    int succeeded = 0;
    int failed = 0;
    final List<SyncOperation> toRemove = [];

    debugPrint(
        'SyncQueueService: Processing ${_queue.length} pending operations...');

    for (final operation in List.from(_queue)) {
      processed++;
      try {
        await RetryHelper.executeWithRetry(
          () => executor(operation),
          maxRetries: 2,
          initialDelay: retryDelay,
          shouldRetry: RetryHelper.shouldRetryNetworkError,
        );

        toRemove.add(operation);
        succeeded++;
        debugPrint(
            'SyncQueueService: Successfully processed ${operation.type.name} for ${operation.entryId}');
      } catch (e) {
        operation.retryCount++;
        operation.lastError = e.toString();
        failed++;

        if (operation.retryCount >= maxRetries) {
          debugPrint(
              'SyncQueueService: Max retries reached for ${operation.entryId}, removing from queue');
          toRemove.add(operation);
        } else {
          debugPrint(
              'SyncQueueService: Failed to process ${operation.type.name} for ${operation.entryId}: $e (retry ${operation.retryCount}/$maxRetries)');
        }
      }
    }

    // Remove processed operations
    for (final op in toRemove) {
      _queue.removeWhere((o) => o.id == op.id);
    }

    await _persist();
    _isProcessing = false;
    notifyListeners();

    debugPrint(
        'SyncQueueService: Queue processing complete - Processed: $processed, Succeeded: $succeeded, Failed: $failed');
    return SyncResult(
        processed: processed, succeeded: succeeded, failed: failed);
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
