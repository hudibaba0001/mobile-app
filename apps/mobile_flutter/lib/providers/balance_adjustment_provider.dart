// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import '../models/balance_adjustment.dart';
import '../repositories/balance_adjustment_repository.dart';
import '../services/supabase_auth_service.dart';

/// Provider for managing balance adjustments
class BalanceAdjustmentProvider extends ChangeNotifier {
  final SupabaseAuthService _authService;
  final BalanceAdjustmentRepository _repository;

  // In-memory cache: year -> list of adjustments
  final Map<int, List<BalanceAdjustment>> _adjustmentsByYear = {};

  bool _isLoading = false;
  String? _error;

  BalanceAdjustmentProvider(this._authService, this._repository);

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get current user ID
  String? get _userId => _authService.currentUser?.id;

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

    _setLoading(true);
    _error = null;

    try {
      final adjustments = await _repository.listAdjustmentsForYear(
        userId: userId,
        year: year,
      );
      _adjustmentsByYear[year] = adjustments;

      debugPrint(
          'BalanceAdjustmentProvider: Loaded ${adjustments.length} adjustments for year $year');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load adjustments: $e';
      debugPrint('BalanceAdjustmentProvider: Error: $_error');
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

  /// Add a new adjustment
  Future<void> addAdjustment({
    required DateTime effectiveDate,
    required int deltaMinutes,
    String? note,
  }) async {
    final userId = _userId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _repository.createAdjustment(
        userId: userId,
        effectiveDate: effectiveDate,
        deltaMinutes: deltaMinutes,
        note: note,
      );

      // Reload the year (force refresh since we just modified data)
      await loadAdjustments(year: effectiveDate.year, forceRefresh: true);
    } catch (e) {
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
    final userId = _userId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _repository.updateAdjustment(
        id: id,
        userId: userId,
        effectiveDate: effectiveDate,
        deltaMinutes: deltaMinutes,
        note: note,
      );

      // Reload the year (force refresh since we just modified data)
      await loadAdjustments(year: effectiveDate.year, forceRefresh: true);
    } catch (e) {
      _error = 'Failed to update adjustment: $e';
      debugPrint('BalanceAdjustmentProvider: Error: $_error');
      notifyListeners();
      rethrow;
    }
  }

  /// Delete an adjustment
  Future<void> deleteAdjustment(String id, int year) async {
    final userId = _userId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _repository.deleteAdjustment(id: id, userId: userId);

      // Reload the year (force refresh since we just modified data)
      await loadAdjustments(year: year, forceRefresh: true);
    } catch (e) {
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
