// ignore_for_file: avoid_print
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/absence.dart';
import '../models/absence_entry_adapter.dart';
import '../services/supabase_absence_service.dart';
import '../services/supabase_auth_service.dart';
import '../services/sync_queue_service.dart';
import '../utils/error_message_mapper.dart';

/// Provider for managing absence entries (vacation, sick leave, VAB, etc.)
class AbsenceProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  final SupabaseAuthService _authService;
  final SupabaseAbsenceService _absenceService;
  final SyncQueueService _syncQueue;
  final Future<bool> Function()? _offlineCheck;
  String? _activeUserId;

  // In-memory storage: year -> list of absences
  final Map<int, List<AbsenceEntry>> _absencesByYear = {};

  // Secondary index: year -> dayKey -> absences for O(1) date lookup
  // dayKey = year*10000 + month*100 + day (e.g. 20260215 for Feb 15 2026)
  final Map<int, Map<int, List<AbsenceEntry>>> _absencesByDate = {};

  // Hive local cache
  Box<AbsenceEntry>? _hiveBox;

  bool _isLoading = false;
  String? _error;
  bool _lastWriteQueuedOffline = false;
  final Set<String> _pendingAbsenceIds = {};
  late final Future<void> _syncQueueReady;

  AbsenceProvider(
    this._authService,
    this._absenceService, {
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
  int get pendingSyncCount => _pendingAbsenceIds.length;
  bool isAbsencePendingSync(String? absenceId) {
    if (absenceId == null || absenceId.isEmpty) return false;
    return _pendingAbsenceIds.contains(absenceId);
  }

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

  void _refreshPendingAbsenceIds(String userId) {
    _pendingAbsenceIds
      ..clear()
      ..addAll(_syncQueue.pendingEntityIdsForUser(
        userId,
        operationTypes: SyncQueueService.absenceOperationTypes,
      ));
  }

  /// Initialize Hive box for local caching
  Future<void> initHive(Box<AbsenceEntry> box) async {
    _hiveBox = box;
    _absencesByYear.clear();
    _absencesByDate.clear();
    _loadFromHive();
    await _ensureSyncQueueReady();
    final userId = _activeUserId ?? _authService.currentUser?.id;
    if (userId != null) {
      _refreshPendingAbsenceIds(userId);
    }
  }

  String _cacheKey(String userId, String absenceId) => '$userId:$absenceId';

  static int _dateKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  /// Rebuild the date-indexed map for a given year from _absencesByYear.
  void _rebuildDateIndex(int year) {
    final absences = _absencesByYear[year];
    if (absences == null || absences.isEmpty) {
      _absencesByDate.remove(year);
      return;
    }
    final map = <int, List<AbsenceEntry>>{};
    for (final a in absences) {
      (map[_dateKey(a.date)] ??= []).add(a);
    }
    _absencesByDate[year] = map;
  }

  /// Load cached absences from Hive into memory
  void _loadFromHive() {
    final userId = _activeUserId ?? _authService.currentUser?.id;
    if (_hiveBox == null || userId == null) return;

    for (final key in _hiveBox!.keys) {
      if (key is! String || !key.startsWith('$userId:')) {
        continue;
      }
      final absence = _hiveBox!.get(key);
      if (absence == null) continue;

      // Skip corrupted sentinel records produced by Hive adapter
      if (absence.id == AbsenceEntryAdapter.corruptedSentinelId) {
        debugPrint('AbsenceProvider: Skipping corrupted Hive record key=$key');
        continue;
      }

      final year = absence.date.year;
      _absencesByYear.putIfAbsent(year, () => []);
      final existing = _absencesByYear[year]!;
      if (!existing.any((a) => a.id == absence.id)) {
        existing.add(absence);
      }
    }

    // Rebuild date index for all loaded years
    for (final year in _absencesByYear.keys) {
      _rebuildDateIndex(year);
    }
  }

  /// Save absences for a year to Hive
  void _saveToHive(int year) {
    final userId = _activeUserId ?? _authService.currentUser?.id;
    if (_hiveBox == null || userId == null) return;

    try {
      final absences = _absencesByYear[year] ?? [];
      // Remove old entries for this year
      final keysToRemove = <dynamic>[];
      for (final key in _hiveBox!.keys) {
        if (key is! String || !key.startsWith('$userId:')) {
          continue;
        }
        final entry = _hiveBox!.get(key);
        if (entry != null && entry.date.year == year) {
          keysToRemove.add(key);
        }
      }
      for (final key in keysToRemove) {
        _hiveBox!.delete(key);
      }
      // Add current entries
      for (final absence in absences) {
        if (absence.id != null) {
          _hiveBox!.put(_cacheKey(userId, absence.id!), absence);
        }
      }
    } catch (e) {
      debugPrint('AbsenceProvider: Error saving to Hive: $e');
    }
  }

  /// Clear/reload provider state when authenticated user changes.
  Future<void> handleAuthUserChanged({
    required String? previousUserId,
    required String? currentUserId,
  }) async {
    if (_activeUserId == currentUserId) return;
    _activeUserId = currentUserId;

    _absencesByYear.clear();
    _absencesByDate.clear();
    _pendingAbsenceIds.clear();
    _lastWriteQueuedOffline = false;
    _error = null;
    _isLoading = false;

    if (currentUserId == null) {
      notifyListeners();
      return;
    }

    await _ensureSyncQueueReady();
    _refreshPendingAbsenceIds(currentUserId);
    _loadFromHive();
    notifyListeners();
    await loadAbsences(year: DateTime.now().year, forceRefresh: true);
  }

  /// Load absences for a specific year
  /// Set [forceRefresh] to true to reload even if already cached
  Future<void> loadAbsences(
      {required int year, bool forceRefresh = false}) async {
    // Skip if already loaded for this year (unless force refresh)
    if (!forceRefresh && _absencesByYear.containsKey(year)) {
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        _error = 'User not authenticated';
        _setLoading(false);
        return;
      }
      await _ensureSyncQueueReady();
      _refreshPendingAbsenceIds(userId);

      final absences = await _absenceService.fetchAbsencesForYear(userId, year);
      _absencesByYear[year] = absences;
      _rebuildDateIndex(year);
      _saveToHive(year);
      _refreshPendingAbsenceIds(userId);

      debugPrint(
          'AbsenceProvider: Loaded ${absences.length} absences for year $year');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load absences: $e';
      debugPrint('AbsenceProvider: Error loading absences: $_error');
      // Keep cached data in memory if available; do not wipe on offline errors.
      if (_absencesByYear.containsKey(year)) {
        debugPrint('AbsenceProvider: Using cached data for year $year');
      }
      final userId = _authService.currentUser?.id;
      if (userId != null) {
        await _ensureSyncQueueReady();
        _refreshPendingAbsenceIds(userId);
      }
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Get all absences for a specific date (O(1) hash lookup)
  List<AbsenceEntry> absencesForDate(DateTime date) {
    final yearMap = _absencesByDate[date.year];
    if (yearMap == null) return const [];
    return yearMap[_dateKey(date)] ?? const [];
  }

  /// Shared paid-credit rule used by all balance/reporting calculations.
  static int paidAbsenceMinutesForAbsences({
    required Iterable<AbsenceEntry> absencesForDate,
    required int scheduledMinutes,
  }) {
    final paidAbsences = absencesForDate.where((absence) => absence.isPaid);
    if (paidAbsences.isEmpty) {
      return 0;
    }

    final hasFullDay = paidAbsences.any((absence) => absence.minutes == 0);
    if (hasFullDay) {
      return scheduledMinutes;
    }

    final totalPaidMinutes = paidAbsences.fold<int>(
      0,
      (sum, absence) => sum + absence.minutes,
    );

    return totalPaidMinutes < scheduledMinutes
        ? totalPaidMinutes
        : scheduledMinutes;
  }

  /// Calculate paid absence credit minutes for a specific date
  int paidAbsenceMinutesForDate(DateTime date, int scheduledMinutes) {
    return paidAbsenceMinutesForAbsences(
      absencesForDate: absencesForDate(date),
      scheduledMinutes: scheduledMinutes,
    );
  }

  AbsenceEntry _normalizeAbsenceForLocal(AbsenceEntry absence) {
    final id = absence.id ?? _uuid.v4();
    return AbsenceEntry(
      id: id,
      date: DateTime(absence.date.year, absence.date.month, absence.date.day),
      minutes: absence.minutes,
      type: absence.type,
      rawType: absence.rawType,
    );
  }

  void _upsertLocalAbsence(AbsenceEntry absence) {
    final year = absence.date.year;
    final yearAbsences = _absencesByYear.putIfAbsent(year, () => []);
    final index = yearAbsences.indexWhere((a) => a.id == absence.id);
    if (index == -1) {
      yearAbsences.add(absence);
    } else {
      yearAbsences[index] = absence;
    }
    _rebuildDateIndex(year);
    _saveToHive(year);
  }

  void _deleteLocalAbsence(String absenceId, int year) {
    final yearAbsences = _absencesByYear[year];
    if (yearAbsences == null) {
      _saveToHive(year);
      return;
    }
    yearAbsences.removeWhere((absence) => absence.id == absenceId);
    _rebuildDateIndex(year);
    _saveToHive(year);
  }

  Future<SyncResult> processPendingSync() async {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      return SyncResult(processed: 0, succeeded: 0, failed: 0);
    }

    await _ensureSyncQueueReady();
    final result = await _syncQueue.processQueue(
      null,
      userId: userId,
      operationTypes: SyncQueueService.absenceOperationTypes,
    );
    _refreshPendingAbsenceIds(userId);
    notifyListeners();
    return result;
  }

  /// Add an absence entry
  Future<void> addAbsence(AbsenceEntry absence) async {
    _lastWriteQueuedOffline = false;
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final localAbsence = _normalizeAbsenceForLocal(absence);
      await _ensureSyncQueueReady();

      if (await _isOfflineNow()) {
        _upsertLocalAbsence(localAbsence);
        await _syncQueue.queueAbsenceCreate(localAbsence, userId);
        _refreshPendingAbsenceIds(userId);
        _error = null;
        _lastWriteQueuedOffline = true;
        notifyListeners();
        return;
      }

      await _absenceService.addAbsence(userId, localAbsence);
      await loadAbsences(year: localAbsence.date.year, forceRefresh: true);
    } catch (e) {
      final userId = _authService.currentUser?.id;
      if (userId != null && ErrorMessageMapper.isOfflineError(e)) {
        final localAbsence = _normalizeAbsenceForLocal(absence);
        await _ensureSyncQueueReady();
        _upsertLocalAbsence(localAbsence);
        await _syncQueue.queueAbsenceCreate(localAbsence, userId);
        _refreshPendingAbsenceIds(userId);
        _error = null;
        _lastWriteQueuedOffline = true;
        notifyListeners();
        return;
      }
      _error = 'Failed to add absence: $e';
      debugPrint('AbsenceProvider: Error: $_error');
      notifyListeners();
      rethrow;
    }
  }

  /// Update an absence entry
  Future<void> updateAbsence(String absenceId, AbsenceEntry absence) async {
    _lastWriteQueuedOffline = false;
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final localAbsence = AbsenceEntry(
        id: absenceId,
        date: DateTime(absence.date.year, absence.date.month, absence.date.day),
        minutes: absence.minutes,
        type: absence.type,
        rawType: absence.rawType,
      );
      await _ensureSyncQueueReady();

      if (await _isOfflineNow()) {
        _upsertLocalAbsence(localAbsence);
        await _syncQueue.queueAbsenceUpdate(absenceId, localAbsence, userId);
        _refreshPendingAbsenceIds(userId);
        _error = null;
        _lastWriteQueuedOffline = true;
        notifyListeners();
        return;
      }

      await _absenceService.updateAbsence(userId, absenceId, localAbsence);
      await loadAbsences(year: localAbsence.date.year, forceRefresh: true);
    } catch (e) {
      final userId = _authService.currentUser?.id;
      if (userId != null && ErrorMessageMapper.isOfflineError(e)) {
        final localAbsence = AbsenceEntry(
          id: absenceId,
          date:
              DateTime(absence.date.year, absence.date.month, absence.date.day),
          minutes: absence.minutes,
          type: absence.type,
          rawType: absence.rawType,
        );
        await _ensureSyncQueueReady();
        _upsertLocalAbsence(localAbsence);
        await _syncQueue.queueAbsenceUpdate(absenceId, localAbsence, userId);
        _refreshPendingAbsenceIds(userId);
        _error = null;
        _lastWriteQueuedOffline = true;
        notifyListeners();
        return;
      }
      _error = 'Failed to update absence: $e';
      debugPrint('AbsenceProvider: Error: $_error');
      notifyListeners();
      rethrow;
    }
  }

  /// Delete an absence entry
  Future<void> deleteAbsence(String absenceId, int year) async {
    _lastWriteQueuedOffline = false;
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _ensureSyncQueueReady();
      if (await _isOfflineNow()) {
        _deleteLocalAbsence(absenceId, year);
        await _syncQueue.queueAbsenceDelete(absenceId, userId);
        _refreshPendingAbsenceIds(userId);
        _error = null;
        _lastWriteQueuedOffline = true;
        notifyListeners();
        return;
      }

      await _absenceService.deleteAbsence(userId, absenceId);
      await loadAbsences(year: year, forceRefresh: true);
    } catch (e) {
      final userId = _authService.currentUser?.id;
      if (userId != null && ErrorMessageMapper.isOfflineError(e)) {
        await _ensureSyncQueueReady();
        _deleteLocalAbsence(absenceId, year);
        await _syncQueue.queueAbsenceDelete(absenceId, userId);
        _refreshPendingAbsenceIds(userId);
        _error = null;
        _lastWriteQueuedOffline = true;
        notifyListeners();
        return;
      }
      _error = 'Failed to delete absence: $e';
      debugPrint('AbsenceProvider: Error: $_error');
      notifyListeners();
      rethrow;
    }
  }

  /// Get all absences for a specific year
  List<AbsenceEntry> absencesForYear(int year) {
    return _absencesByYear[year] ?? [];
  }

  /// Add an absence entry (wrapper for consistency)
  Future<void> addAbsenceEntry(AbsenceEntry absence) async {
    return addAbsence(absence);
  }

  /// Update an absence entry (wrapper for consistency)
  Future<void> updateAbsenceEntry(AbsenceEntry absence) async {
    if (absence.id == null) {
      throw Exception('Absence ID is required for update');
    }
    return updateAbsence(absence.id!, absence);
  }

  /// Delete an absence entry (wrapper for consistency)
  Future<void> deleteAbsenceEntry(String absenceId, int year) async {
    return deleteAbsence(absenceId, year);
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
}
