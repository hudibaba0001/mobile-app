// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import '../models/absence.dart';
import '../services/supabase_absence_service.dart';
import '../services/supabase_auth_service.dart';

/// Provider for managing absence entries (vacation, sick leave, VAB, etc.)
class AbsenceProvider extends ChangeNotifier {
  final SupabaseAuthService _authService;
  final SupabaseAbsenceService _absenceService;

  // In-memory storage: year -> list of absences
  final Map<int, List<AbsenceEntry>> _absencesByYear = {};
  
  bool _isLoading = false;
  String? _error;

  AbsenceProvider(this._authService, this._absenceService);

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load absences for a specific year
  Future<void> loadAbsences({required int year}) async {
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

      debugPrint('AbsenceProvider: Loaded ${absences.length} absences for year $year');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load absences: $e';
      debugPrint('AbsenceProvider: Error loading absences: $_error');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Get all absences for a specific date
  /// 
  /// Returns empty list if no absences exist for that date
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
  /// 
  /// Option A policy:
  /// - If any paid absence exists on that day:
  ///   - If any entry has minutes == 0, treat as full-day → return scheduledMinutes
  ///   - Else return min(scheduledMinutes, sum(paidAbsence.minutes))
  /// - Unpaid absences return 0 credit
  /// 
  /// [date] The date to check
  /// [scheduledMinutes] The scheduled minutes for that day
  /// 
  /// Returns the credit minutes (0 for unpaid or no absence)
  int paidAbsenceMinutesForDate(DateTime date, int scheduledMinutes) {
    final absences = absencesForDate(date);
    
    if (absences.isEmpty) {
      return 0;
    }

    // Filter to paid absences only
    final paidAbsences = absences.where((a) => a.isPaid).toList();
    
    if (paidAbsences.isEmpty) {
      return 0; // Only unpaid absences
    }

    // Check if any paid absence has minutes == 0 (full day)
    final hasFullDay = paidAbsences.any((a) => a.minutes == 0);
    if (hasFullDay) {
      return scheduledMinutes; // Full day credit
    }

    // Sum all paid absence minutes
    final totalPaidMinutes = paidAbsences.fold<int>(
      0,
      (sum, absence) => sum + absence.minutes,
    );

    // Return min(scheduledMinutes, totalPaidMinutes)
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
      
      // Reload the year
      await loadAbsences(year: absence.date.year);
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
      
      // Reload the year
      await loadAbsences(year: absence.date.year);
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
      
      // Reload the year
      await loadAbsences(year: year);
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
    _isLoading = loading;
    notifyListeners();
  }
}

