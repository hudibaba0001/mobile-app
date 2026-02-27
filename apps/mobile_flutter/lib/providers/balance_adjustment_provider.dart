import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/balance_adjustment.dart';
import '../models/balance_adjustment_adapter.dart';
import '../repositories/balance_adjustment_repository.dart';
import '../services/supabase_auth_service.dart';
import '../services/sync_queue_service.dart';
import '../utils/error_message_mapper.dart';

/// Provider for managing balance adjustments
class BalanceAdjustmentProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  final SupabaseAuthService _authService;
  final BalanceAdjustmentRepository _repository;
  final SyncQueueService _syncQueue;
  final Future<bool> Function()? _offlineCheck;
  String? _activeUserId;

  // In-memory cache: year -> list of adjustments
  final Map<int, List<BalanceAdjustment>> _adjustmentsByYear = {};

  // Hive local cache
  Box<BalanceAdjustment>? _hiveBox;

  bool _isLoading = false;
  String? _error;
  bool _lastWriteQueuedOffline = false;
  final Set<String> _pendingAdjustmentIds = {};
  late final Future<void> _syncQueueReady;

  BalanceAdjustmentProvider(
    this._authService,
    this._repository, {
    SyncQueueService? syncQueue,
    Future<bool> Function()? offlineCheck,
  })  : _syncQueue = syncQueue ?? SyncQueueService(),
        _offlineCheck = offlineCheck {
    _activeUserId = _authService.currentUser?.id;
    _syncQueueReady = _syncQueue.init();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get lastWriteQueuedOffline => _lastWriteQueuedOffline;
  int get pendingSyncCount => _pendingAdjustmentIds.length;
  bool isAdjustmentPendingSync(String? adjustmentId) {
    if (adjustmentId == null || adjustmentId.isEmpty) return false;
    return _pendingAdjustmentIds.contains(adjustmentId);
  }

  /// Get current user ID
  String? get _userId => _authService.currentUser?.id;

  Future<void> _ensureSyncQueueReady() async {
    await _syncQueueReady;
  }

  Future<bool> _isOfflineNow() async {
    if (_offlineCheck != null) {
      return _offlineCheck!();
    }
    try {
      final results = await Connectivity().checkConnectivity();
      return !results.any((result) => result != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  void _refreshPendingAdjustmentIds(String userId) {
    _pendingAdjustmentIds
      ..clear()
      ..addAll(_syncQueue.pendingEntityIdsForUser(
        userId,
        operationTypes: SyncQueueService.adjustmentOperationTypes,
      ));
  }

  /// Initialize Hive box for local caching
  Future<void> initHive(Box<BalanceAdjustment> box) async {
    _hiveBox = box;
    _adjustmentsByYear.clear();
    _loadFromHive();
    await _ensureSyncQueueReady();
    final userId = _activeUserId ?? _userId;
    if (userId != null) {
      _refreshPendingAdjustmentIds(userId);
    }
  }

  /// Load cached adjustments from Hive into memory
  void _loadFromHive() {
    final userId = _activeUserId ?? _userId;
    if (_hiveBox == null || userId == null) return;

    for (final adj in _hiveBox!.values) {
      // Skip corrupted sentinel records produced by Hive adapter
      if (adj.id == BalanceAdjustmentAdapter.corruptedSentinelId) {
        debugPrint('BalanceAdjustmentProvider: Skipping corrupted Hive record');
        continue;
      }
      if (adj.userId != userId) continue;
      final year = adj.effectiveDate.year;
      _adjustmentsByYear.putIfAbsent(year, () => []);
      final existing = _adjustmentsByYear[year]!;
      if (!existing.any((a) => a.id == adj.id)) {
        existing.add(adj);
      }
    }
  }

  /// Save adjustments for a year to Hive
  void _saveToHive(int year) {
    final userId = _activeUserId ?? _userId;
    if (_hiveBox == null || userId == null) return;

    try {
      final adjustments = _adjustmentsByYear[year] ?? [];
      // Remove old entries for this year
      final keysToRemove = <dynamic>[];
      for (final key in _hiveBox!.keys) {
        final entry = _hiveBox!.get(key);
        if (entry != null &&
            entry.userId == userId &&
            entry.effectiveDate.year == year) {
          keysToRemove.add(key);
        }
      }
      for (final key in keysToRemove) {
        _hiveBox!.delete(key);
      }
      // Add current entries
      for (final adj in adjustments) {
        if (adj.id != null) {
          _hiveBox!.put(adj.id, adj);
        }
      }
    } catch (e) {
      debugPrint('BalanceAdjustmentProvider: Error saving to Hive: $e');
    }
  }

  /// Clear/reload provider state when authenticated user changes.
  Future<void> handleAuthUserChanged({
    required String? previousUserId,
    required String? currentUserId,
  }) async {
    if (_activeUserId == currentUserId) return;
    _activeUserId = currentUserId;

    _adjustmentsByYear.clear();
    _pendingAdjustmentIds.clear();
    _lastWriteQueuedOffline = false;
    _error = null;
    _isLoading = false;

    if (currentUserId == null) {
      notifyListeners();
      return;
    }

    await _ensureSyncQueueReady();
    _refreshPendingAdjustmentIds(currentUserId);
    _loadFromHive();
    notifyListeners();
    await loadAdjustments(year: DateTime.now().year, forceRefresh: true);
  }

  /// Load adjustments for a specific year
  /// Set [forceRefresh] to true to reload even if already cached
  Future<void> loadAdjustments(
      {required int year, bool forceRefresh = false}) async {
    // Skip if already loaded for this year (unless force refresh)
    if (!forceRefresh && _adjustmentsByYear.containsKey(year)) {
      return;
    }

    final userId = _userId;
    if (userId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    await _ensureSyncQueueReady();
    _refreshPendingAdjustmentIds(userId);

    _setLoading(true);
    _error = null;

    try {
      final adjustments = await _repository.listAdjustmentsForYear(
        userId: userId,
        year: year,
      );
      _adjustmentsByYear[year] = adjustments;
      _saveToHive(year);
      _refreshPendingAdjustmentIds(userId);

      debugPrint(
          'BalanceAdjustmentProvider: Loaded ${adjustments.length} adjustments for year $year');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load adjustments: $e';
      debugPrint('BalanceAdjustmentProvider: Error: $_error');
      // Keep cached data in memory if available; do not wipe on offline errors.
      if (_adjustmentsByYear.containsKey(year)) {
        debugPrint(
            'BalanceAdjustmentProvider: Using cached data for year $year');
      }
      _refreshPendingAdjustmentIds(userId);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Get all adjustments for a specific year
  List<BalanceAdjustment> adjustmentsForYear(int year) {
    return _adjustmentsByYear[year] ?? [];
  }

  /// Get all loaded adjustments (sorted by date, most recent first)
  List<BalanceAdjustment> get allAdjustments {
    final all = <BalanceAdjustment>[];
    for (final list in _adjustmentsByYear.values) {
      all.addAll(list);
    }
    all.sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
    return all;
  }

  /// Get adjustments for a date range
  List<BalanceAdjustment> adjustmentsInRange(DateTime start, DateTime end) {
    final all = <BalanceAdjustment>[];
    for (final list in _adjustmentsByYear.values) {
      all.addAll(list.where((adj) {
        final date = adj.effectiveDate;
        return !date.isBefore(start) && !date.isAfter(end);
      }));
    }
    all.sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
    return all;
  }

  /// Get total adjustment minutes for a date range (for balance calculations)
  int totalAdjustmentMinutesInRange(DateTime start, DateTime end) {
    final adjustments = adjustmentsInRange(start, end);
    return adjustments.fold<int>(0, (sum, adj) => sum + adj.deltaMinutes);
  }

  /// Get adjustments for a specific date
  List<BalanceAdjustment> adjustmentsForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final yearAdjustments = _adjustmentsByYear[date.year] ?? [];
    return yearAdjustments.where((adj) {
      return adj.effectiveDate.year == normalized.year &&
          adj.effectiveDate.month == normalized.month &&
          adj.effectiveDate.day == normalized.day;
    }).toList();
  }

  /// Get total adjustment minutes for a specific date
  int adjustmentMinutesForDate(DateTime date) {
    final adjustments = adjustmentsForDate(date);
    return adjustments.fold<int>(0, (sum, adj) => sum + adj.deltaMinutes);
  }

  BalanceAdjustment _normalizeAdjustmentForLocal({
    String? id,
    required String userId,
    required DateTime effectiveDate,
    required int deltaMinutes,
    String? note,
  }) {
    return BalanceAdjustment(
      id: id ?? _uuid.v4(),
      userId: userId,
      effectiveDate:
          DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day),
      deltaMinutes: deltaMinutes,
      note: note,
      updatedAt: DateTime.now(),
    );
  }

  void _upsertLocalAdjustment(BalanceAdjustment adjustment) {
    final year = adjustment.effectiveDate.year;
    final yearAdjustments = _adjustmentsByYear.putIfAbsent(year, () => []);
    final index = yearAdjustments.indexWhere((a) => a.id == adjustment.id);
    if (index == -1) {
      yearAdjustments.add(adjustment);
    } else {
      yearAdjustments[index] = adjustment;
    }
    yearAdjustments.sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
    _saveToHive(year);
  }

  void _deleteLocalAdjustment(String id, int year) {
    final yearAdjustments = _adjustmentsByYear[year];
    if (yearAdjustments == null) {
      _saveToHive(year);
      return;
    }
    yearAdjustments.removeWhere((adjustment) => adjustment.id == id);
    _saveToHive(year);
  }

  Future<SyncResult> processPendingSync() async {
    final userId = _userId;
    if (userId == null) {
      return SyncResult(processed: 0, succeeded: 0, failed: 0);
    }

    await _ensureSyncQueueReady();
    final result = await _syncQueue.processQueue(
      null,
      userId: userId,
      operationTypes: SyncQueueService.adjustmentOperationTypes,
    );
    _refreshPendingAdjustmentIds(userId);
    notifyListeners();
    return result;
  }

  /// Add a new adjustment
  Future<void> addAdjustment({
    required DateTime effectiveDate,
    required int deltaMinutes,
    String? note,
  }) async {
    _lastWriteQueuedOffline = false;
    final userId = _userId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final localAdjustment = _normalizeAdjustmentForLocal(
        userId: userId,
        effectiveDate: effectiveDate,
        deltaMinutes: deltaMinutes,
        note: note,
      );
      await _ensureSyncQueueReady();

      if (await _isOfflineNow()) {
        _upsertLocalAdjustment(localAdjustment);
        await _syncQueue.queueAdjustmentCreate(localAdjustment, userId);
        _refreshPendingAdjustmentIds(userId);
        _error = null;
        _lastWriteQueuedOffline = true;
        notifyListeners();
        return;
      }

      await _repository.createAdjustment(
        id: localAdjustment.id,
        userId: userId,
        effectiveDate: localAdjustment.effectiveDate,
        deltaMinutes: localAdjustment.deltaMinutes,
        note: localAdjustment.note,
      );

      // Reload the year (force refresh since we just modified data)
      await loadAdjustments(year: effectiveDate.year, forceRefresh: true);
    } catch (e) {
      if (ErrorMessageMapper.isOfflineError(e)) {
        final localAdjustment = _normalizeAdjustmentForLocal(
          userId: userId,
          effectiveDate: effectiveDate,
          deltaMinutes: deltaMinutes,
          note: note,
        );
        await _ensureSyncQueueReady();
        _upsertLocalAdjustment(localAdjustment);
        await _syncQueue.queueAdjustmentCreate(localAdjustment, userId);
        _refreshPendingAdjustmentIds(userId);
        _error = null;
        _lastWriteQueuedOffline = true;
        notifyListeners();
        return;
      }
      _error = 'Failed to add adjustment: $e';
      debugPrint('BalanceAdjustmentProvider: Error: $_error');
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing adjustment
  Future<void> updateAdjustment({
    required String id,
    required DateTime effectiveDate,
    required int deltaMinutes,
    String? note,
  }) async {
    _lastWriteQueuedOffline = false;
    final userId = _userId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final localAdjustment = _normalizeAdjustmentForLocal(
        id: id,
        userId: userId,
        effectiveDate: effectiveDate,
        deltaMinutes: deltaMinutes,
        note: note,
      );
      await _ensureSyncQueueReady();

      if (await _isOfflineNow()) {
        _upsertLocalAdjustment(localAdjustment);
        await _syncQueue.queueAdjustmentUpdate(id, localAdjustment, userId);
        _refreshPendingAdjustmentIds(userId);
        _error = null;
        _lastWriteQueuedOffline = true;
        notifyListeners();
        return;
      }

      await _repository.updateAdjustment(
        id: id,
        userId: userId,
        effectiveDate: localAdjustment.effectiveDate,
        deltaMinutes: localAdjustment.deltaMinutes,
        note: localAdjustment.note,
      );

      // Reload the year (force refresh since we just modified data)
      await loadAdjustments(year: effectiveDate.year, forceRefresh: true);
    } catch (e) {
      if (ErrorMessageMapper.isOfflineError(e)) {
        final localAdjustment = _normalizeAdjustmentForLocal(
          id: id,
          userId: userId,
          effectiveDate: effectiveDate,
          deltaMinutes: deltaMinutes,
          note: note,
        );
        await _ensureSyncQueueReady();
        _upsertLocalAdjustment(localAdjustment);
        await _syncQueue.queueAdjustmentUpdate(id, localAdjustment, userId);
        _refreshPendingAdjustmentIds(userId);
        _error = null;
        _lastWriteQueuedOffline = true;
        notifyListeners();
        return;
      }
      _error = 'Failed to update adjustment: $e';
      debugPrint('BalanceAdjustmentProvider: Error: $_error');
      notifyListeners();
      rethrow;
    }
  }

  /// Delete an adjustment
  Future<void> deleteAdjustment(String id, int year) async {
    _lastWriteQueuedOffline = false;
    final userId = _userId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _ensureSyncQueueReady();
      if (await _isOfflineNow()) {
        _deleteLocalAdjustment(id, year);
        await _syncQueue.queueAdjustmentDelete(id, userId);
        _refreshPendingAdjustmentIds(userId);
        _error = null;
        _lastWriteQueuedOffline = true;
        notifyListeners();
        return;
      }

      await _repository.deleteAdjustment(id: id, userId: userId);

      // Reload the year (force refresh since we just modified data)
      await loadAdjustments(year: year, forceRefresh: true);
    } catch (e) {
      if (ErrorMessageMapper.isOfflineError(e)) {
        await _ensureSyncQueueReady();
        _deleteLocalAdjustment(id, year);
        await _syncQueue.queueAdjustmentDelete(id, userId);
        _refreshPendingAdjustmentIds(userId);
        _error = null;
        _lastWriteQueuedOffline = true;
        notifyListeners();
        return;
      }
      _error = 'Failed to delete adjustment: $e';
      debugPrint('BalanceAdjustmentProvider: Error: $_error');
      notifyListeners();
      rethrow;
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
}
