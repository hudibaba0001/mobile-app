// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/absence.dart';
import '../services/supabase_absence_service.dart';
import '../services/supabase_auth_service.dart';

/// Provider for managing absence entries (vacation, sick leave, VAB, etc.)
class AbsenceProvider extends ChangeNotifier {
  final SupabaseAuthService _authService;
  final SupabaseAbsenceService _absenceService;

  // In-memory storage: year -> list of absences
  final Map<int, List<AbsenceEntry>> _absencesByYear = {};

  // Hive local cache
  Box<AbsenceEntry>? _hiveBox;

  bool _isLoading = false;
  String? _error;

  AbsenceProvider(this._authService, this._absenceService);

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize Hive box for local caching
  Future<void> initHive(Box<AbsenceEntry> box) async {
    _hiveBox = box;
    _loadFromHive();
  }

  /// Load cached absences from Hive into memory
  void _loadFromHive() {
    if (_hiveBox == null) return;

    for (final absence in _hiveBox!.values) {
      final year = absence.date.year;
      _absencesByYear.putIfAbsent(year, () => []);
      final existing = _absencesByYear[year]!;
      if (!existing.any((a) => a.id == absence.id)) {
        existing.add(absence);
      }
    }
  }

  /// Save absences for a year to Hive
  void _saveToHive(int year) {
    if (_hiveBox == null) return;

    try {
      final absences = _absencesByYear[year] ?? [];
      // Remove old entries for this year
      final keysToRemove = <dynamic>[];
      for (final key in _hiveBox!.keys) {
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
          _hiveBox!.put(absence.id, absence);
        }
      }
    } catch (e) {
      debugPrint('AbsenceProvider: Error saving to Hive: $e');
    }
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

      final absences = await _absenceService.fetchAbsencesForYear(userId, year);
      _absencesByYear[year] = absences;
      _saveToHive(year);

      debugPrint(
          'AbsenceProvider: Loaded ${absences.length} absences for year $year');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load absences: $e';
      debugPrint('AbsenceProvider: Error loading absences: $_error');
      // Fall back to Hive cache (already loaded in _loadFromHive)
      if (_absencesByYear.containsKey(year)) {
        debugPrint('AbsenceProvider: Using cached data for year $year');
        _error = null;
      }
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Get all absences for a specific date
  List<AbsenceEntry> absencesForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final year = normalized.year;
    final absences = _absencesByYear[year] ?? [];

    return absences.where((absence) {
      return absence.date.year == normalized.year &&
          absence.date.month == normalized.month &&
          absence.date.day == normalized.day;
    }).toList();
  }

  /// Calculate paid absence credit minutes for a specific date
  int paidAbsenceMinutesForDate(DateTime date, int scheduledMinutes) {
    final absences = absencesForDate(date);

    if (absences.isEmpty) {
      return 0;
    }

    // Filter to paid absences only
    final paidAbsences = absences.where((a) => a.isPaid).toList();

    if (paidAbsences.isEmpty) {
      return 0;
    }

    // Check if any paid absence has minutes == 0 (full day)
    final hasFullDay = paidAbsences.any((a) => a.minutes == 0);
    if (hasFullDay) {
      return scheduledMinutes;
    }

    // Sum all paid absence minutes
    final totalPaidMinutes = paidAbsences.fold<int>(
      0,
      (sum, absence) => sum + absence.minutes,
    );

    return totalPaidMinutes < scheduledMinutes
        ? totalPaidMinutes
        : scheduledMinutes;
  }

  /// Add an absence entry
  Future<void> addAbsence(AbsenceEntry absence) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _absenceService.addAbsence(userId, absence);
      await loadAbsences(year: absence.date.year, forceRefresh: true);
    } catch (e) {
      _error = 'Failed to add absence: $e';
      debugPrint('AbsenceProvider: Error: $_error');
      notifyListeners();
      rethrow;
    }
  }

  /// Update an absence entry
  Future<void> updateAbsence(String absenceId, AbsenceEntry absence) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _absenceService.updateAbsence(userId, absenceId, absence);
      await loadAbsences(year: absence.date.year, forceRefresh: true);
    } catch (e) {
      _error = 'Failed to update absence: $e';
      debugPrint('AbsenceProvider: Error: $_error');
      notifyListeners();
      rethrow;
    }
  }

  /// Delete an absence entry
  Future<void> deleteAbsence(String absenceId, int year) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _absenceService.deleteAbsence(userId, absenceId);
      await loadAbsences(year: year, forceRefresh: true);
    } catch (e) {
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
