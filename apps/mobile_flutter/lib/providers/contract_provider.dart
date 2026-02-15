// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../services/profile_service.dart';

/// Provider for managing contract settings and work hour calculations
///
/// Handles contract percentage and full-time hours settings, with automatic
/// calculation of allowed work hours based on contract terms. Settings are
/// persisted to both Supabase (cloud) and SharedPreferences (local cache).
///
/// Also manages the "starting point" for balance tracking:
/// - trackingStartDate: Date from which balances are calculated
/// - openingFlexMinutes: Opening flex/time bank balance as of start date
class ContractProvider extends ChangeNotifier {
  // Service for Supabase persistence
  final ProfileService _profileService = ProfileService();
  String? _activeUserId;

  // Private fields
  int _contractPercent = 100; // Default to 100% (full-time)
  int _fullTimeHours = 40; // Default to 40 hours per week

  // Starting balance fields (V1: start date = opening balance date)
  DateTime? _trackingStartDate; // Date from which to calculate balances
  int _openingFlexMinutes = 0; // Signed: positive = credit, negative = deficit

  // Employer mode (V1: affects validation strictness, not calculations yet)
  String _employerMode = 'standard'; // 'standard', 'strict', 'flexible'

  // SharedPreferences keys (local cache)
  static const String _contractPercentKey = 'contract_percent';
  static const String _fullTimeHoursKey = 'full_time_hours';
  static const String _trackingStartDateKey = 'tracking_start_date';
  static const String _openingFlexMinutesKey = 'opening_flex_minutes';
  static const String _employerModeKey = 'employer_mode';

  // Getters

  /// Current contract percentage (0-100)
  int get contractPercent => _contractPercent;

  /// Full-time hours per week
  int get fullTimeHours => _fullTimeHours;

  /// Date from which to start tracking balances
  /// Defaults to Jan 1 of current year if not set.
  DateTime get trackingStartDate =>
      _trackingStartDate ?? DateTime(DateTime.now().year, 1, 1);

  /// Whether a custom tracking start date has been set
  bool get hasCustomTrackingStartDate => _trackingStartDate != null;

  /// Opening flex/time bank balance in minutes (signed)
  int get openingFlexMinutes => _openingFlexMinutes;

  /// Opening flex balance in hours (for display)
  double get openingFlexHours => _openingFlexMinutes / 60.0;

  /// Formatted opening flex balance string (e.g., "+12h 30m" or "−3h 15m")
  String get openingFlexFormatted {
    final isNegative = _openingFlexMinutes < 0;
    final absMinutes = _openingFlexMinutes.abs();
    final hours = absMinutes ~/ 60;
    final mins = absMinutes % 60;

    final sign = isNegative ? '−' : '+';
    if (mins == 0) {
      return '$sign${hours}h';
    }
    return '$sign${hours}h ${mins}m';
  }

  /// Whether there is a non-zero opening balance
  bool get hasOpeningBalance => _openingFlexMinutes != 0;

  /// Calculated allowed work hours per week based on contract percentage
  int get allowedHours => (fullTimeHours * contractPercent / 100).round();

  /// Calculated allowed work minutes per week based on contract percentage
  int get weeklyTargetMinutes {
    return (fullTimeHours * 60.0 * contractPercent / 100.0).round();
  }

  /// Weekly target hours (for display/backward compatibility)
  double get weeklyTargetHours => weeklyTargetMinutes / 60.0;

  /// Employer mode setting
  String get employerMode => _employerMode;

  // Initialization methods

  /// Initialize the provider by loading settings from local cache
  /// Call loadFromSupabase() after user is authenticated to sync cloud settings
  Future<void> init() async {
    _activeUserId = SupabaseConfig.client.auth.currentUser?.id;
    await _loadFromLocalCache();
  }

  void _resetInMemoryToDefaults() {
    _contractPercent = 100;
    _fullTimeHours = 40;
    _trackingStartDate = null;
    _openingFlexMinutes = 0;
    _employerMode = 'standard';
  }

  /// Clear/reload provider state when authenticated user changes.
  Future<void> handleAuthUserChanged(String? userId) async {
    if (_activeUserId == userId) return;
    _activeUserId = userId;

    _resetInMemoryToDefaults();
    notifyListeners();

    if (userId != null) {
      await loadFromSupabase();
    }
  }

  /// Load settings from Supabase (call when user is authenticated)
  /// This will overwrite local settings with cloud settings if available
  Future<void> loadFromSupabase() async {
    try {
      final profile = await _profileService.fetchProfile();
      if (profile == null) {
        debugPrint(
            'ContractProvider: No profile found in Supabase, using local/default settings');
        return;
      }

      debugPrint('ContractProvider: Loading settings from Supabase...');

      // Update local state from profile
      _contractPercent = profile.contractPercent;
      _fullTimeHours = profile.fullTimeHours;
      _trackingStartDate = profile.trackingStartDate;
      _openingFlexMinutes = profile.openingFlexMinutes;
      _employerMode = profile.employerMode;

      debugPrint('ContractProvider: ✅ Loaded from Supabase:');
      debugPrint('  contractPercent: $_contractPercent%');
      debugPrint('  fullTimeHours: $_fullTimeHours');
      debugPrint('  trackingStartDate: $_trackingStartDate');
      debugPrint(
          '  openingFlexMinutes: $_openingFlexMinutes ($openingFlexFormatted)');
      debugPrint('  employerMode: $_employerMode');

      // Update local cache to match
      await _saveAllToLocalCache();

      notifyListeners();
    } catch (e) {
      debugPrint('ContractProvider: Error loading from Supabase: $e');
      debugPrint('ContractProvider: Using local/default settings');
    }
  }

  /// Save all current settings to Supabase
  Future<void> saveToSupabase() async {
    try {
      final result = await _profileService.updateContractSettings(
        contractPercent: _contractPercent,
        fullTimeHours: _fullTimeHours,
        trackingStartDate: _trackingStartDate,
        openingFlexMinutes: _openingFlexMinutes,
        employerMode: _employerMode,
      );

      if (result != null) {
        debugPrint('ContractProvider: ✅ All settings saved to Supabase');
      } else {
        debugPrint(
            'ContractProvider: ⚠️ Failed to save to Supabase (user may not be authenticated)');
      }
    } catch (e) {
      debugPrint('ContractProvider: Error saving to Supabase: $e');
    }
  }

  // Setters with validation and persistence

  /// Set the contract percentage and persist
  Future<void> setContractPercent(int percent) async {
    if (percent < 0 || percent > 100) {
      throw ArgumentError('Contract percentage must be between 0 and 100');
    }

    if (_contractPercent != percent) {
      _contractPercent = percent;
      await _saveContractPercent();
      notifyListeners();
    }
  }

  /// Set the full-time hours and persist
  Future<void> setFullTimeHours(int hours) async {
    if (hours <= 0) {
      throw ArgumentError('Full-time hours must be positive');
    }

    if (_fullTimeHours != hours) {
      _fullTimeHours = hours;
      await _saveFullTimeHours();
      notifyListeners();
    }
  }

  /// Set the tracking start date and persist
  Future<void> setTrackingStartDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);

    final maxDate = DateTime.now().add(const Duration(days: 365));
    if (normalized.isAfter(maxDate)) {
      throw ArgumentError(
          'Start date cannot be more than 1 year in the future');
    }

    if (_trackingStartDate != normalized) {
      _trackingStartDate = normalized;
      await _saveTrackingStartDate();
      notifyListeners();
    }
  }

  /// Set the opening flex balance in minutes (signed)
  Future<void> setOpeningFlexMinutes(int minutes) async {
    if (_openingFlexMinutes != minutes) {
      _openingFlexMinutes = minutes;
      await _saveOpeningFlexMinutes();
      notifyListeners();
    }
  }

  /// Set opening flex balance from hours and minutes with sign
  Future<void> setOpeningFlexFromComponents({
    required int hours,
    required int minutes,
    required bool isDeficit,
  }) async {
    if (minutes < 0 || minutes >= 60) {
      throw ArgumentError('Minutes must be between 0 and 59');
    }
    if (hours < 0) {
      throw ArgumentError('Hours must be non-negative');
    }

    final totalMinutes = (hours * 60) + minutes;
    final signedMinutes = isDeficit ? -totalMinutes : totalMinutes;
    await setOpeningFlexMinutes(signedMinutes);
  }

  /// Set employer mode and persist
  Future<void> setEmployerMode(String mode) async {
    if (_employerMode != mode) {
      _employerMode = mode;
      await _saveEmployerMode();
      notifyListeners();
    }
  }

  /// Validate and update all contract settings at once
  Future<void> updateContractSettings(int percent, int hours) async {
    debugPrint(
        'ContractProvider: updateContractSettings called with percent=$percent, hours=$hours');
    debugPrint(
        'ContractProvider: Current values: percent=$_contractPercent, hours=$_fullTimeHours');

    if (percent < 0 || percent > 100) {
      throw ArgumentError('Contract percentage must be between 0 and 100');
    }
    if (hours <= 0) {
      throw ArgumentError('Full-time hours must be positive');
    }

    bool changed = false;

    if (_contractPercent != percent) {
      debugPrint(
          'ContractProvider: Percent changed from $_contractPercent to $percent');
      _contractPercent = percent;
      changed = true;
    }

    if (_fullTimeHours != hours) {
      debugPrint(
          'ContractProvider: Hours changed from $_fullTimeHours to $hours');
      _fullTimeHours = hours;
      changed = true;
    }

    if (changed) {
      // Save to both local cache and Supabase
      await _saveAllToLocalCache();
      await saveToSupabase();
      debugPrint('ContractProvider: Settings updated and saved');
      notifyListeners();
    }
  }

  /// Reset contract settings to default values
  Future<void> resetToDefaults() async {
    _resetInMemoryToDefaults();

    // Clear from local cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_contractPercentKey);
    await prefs.remove(_fullTimeHoursKey);
    await prefs.remove(_trackingStartDateKey);
    await prefs.remove(_openingFlexMinutesKey);
    await prefs.remove(_employerModeKey);

    // Save defaults to Supabase
    await saveToSupabase();

    notifyListeners();
  }

  // Private persistence methods

  /// Load settings from local SharedPreferences cache
  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      debugPrint('ContractProvider: Loading from local cache...');

      // Load contract percentage
      final savedPercent = prefs.getInt(_contractPercentKey);
      if (savedPercent != null && savedPercent >= 0 && savedPercent <= 100) {
        _contractPercent = savedPercent;
      }

      // Load full-time hours
      final savedHours = prefs.getInt(_fullTimeHoursKey);
      if (savedHours != null && savedHours > 0) {
        _fullTimeHours = savedHours;
      }

      // Load tracking start date
      final savedStartDate = prefs.getString(_trackingStartDateKey);
      if (savedStartDate != null) {
        try {
          final parts = savedStartDate.split('-');
          if (parts.length == 3) {
            _trackingStartDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
        } catch (e) {
          _trackingStartDate = null;
        }
      }

      // Load opening flex balance
      final savedOpeningFlex = prefs.getInt(_openingFlexMinutesKey);
      if (savedOpeningFlex != null) {
        _openingFlexMinutes = savedOpeningFlex;
      }

      // Load employer mode
      final savedMode = prefs.getString(_employerModeKey);
      if (savedMode != null &&
          ['standard', 'strict', 'flexible'].contains(savedMode)) {
        _employerMode = savedMode;
      }

      debugPrint('ContractProvider: Loaded from local cache:');
      debugPrint('  contractPercent: $_contractPercent%');
      debugPrint('  fullTimeHours: $_fullTimeHours');
      debugPrint('  trackingStartDate: $_trackingStartDate');
      debugPrint('  openingFlexMinutes: $_openingFlexMinutes');
      debugPrint('  employerMode: $_employerMode');

      notifyListeners();
    } catch (e) {
      debugPrint('ContractProvider: Error loading from local cache: $e');
      notifyListeners();
    }
  }

  /// Save all settings to local SharedPreferences cache
  Future<void> _saveAllToLocalCache() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_contractPercentKey, _contractPercent);
    await prefs.setInt(_fullTimeHoursKey, _fullTimeHours);

    if (_trackingStartDate != null) {
      final dateStr = '${_trackingStartDate!.year}-'
          '${_trackingStartDate!.month.toString().padLeft(2, '0')}-'
          '${_trackingStartDate!.day.toString().padLeft(2, '0')}';
      await prefs.setString(_trackingStartDateKey, dateStr);
    } else {
      await prefs.remove(_trackingStartDateKey);
    }

    await prefs.setInt(_openingFlexMinutesKey, _openingFlexMinutes);
    await prefs.setString(_employerModeKey, _employerMode);

    debugPrint('ContractProvider: Saved all settings to local cache');
  }

  /// Save contract percentage (local + Supabase)
  Future<void> _saveContractPercent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_contractPercentKey, _contractPercent);
    debugPrint(
        'ContractProvider: SAVED contract percentage: $_contractPercent%');

    // Also save to Supabase
    await saveToSupabase();
  }

  /// Save full-time hours (local + Supabase)
  Future<void> _saveFullTimeHours() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fullTimeHoursKey, _fullTimeHours);
    debugPrint('ContractProvider: SAVED full-time hours: $_fullTimeHours');

    await saveToSupabase();
  }

  /// Save tracking start date (local + Supabase)
  Future<void> _saveTrackingStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    if (_trackingStartDate != null) {
      final dateStr = '${_trackingStartDate!.year}-'
          '${_trackingStartDate!.month.toString().padLeft(2, '0')}-'
          '${_trackingStartDate!.day.toString().padLeft(2, '0')}';
      await prefs.setString(_trackingStartDateKey, dateStr);
      debugPrint('ContractProvider: SAVED tracking start date: $dateStr');
    } else {
      await prefs.remove(_trackingStartDateKey);
    }

    await saveToSupabase();
  }

  /// Save opening flex minutes (local + Supabase)
  Future<void> _saveOpeningFlexMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_openingFlexMinutesKey, _openingFlexMinutes);
    debugPrint(
        'ContractProvider: SAVED opening flex minutes: $_openingFlexMinutes');

    await saveToSupabase();
  }

  /// Save employer mode (local + Supabase)
  Future<void> _saveEmployerMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_employerModeKey, _employerMode);
    debugPrint('ContractProvider: SAVED employer mode: $_employerMode');

    await saveToSupabase();
  }

  // Utility methods

  double get contractPercentAsDecimal => _contractPercent / 100.0;
  String get contractPercentString => '$_contractPercent%';
  String get allowedHoursString => '$allowedHours hours/week';
  String get fullTimeHoursString => '$_fullTimeHours hours/week';
  bool get isFullTime => _contractPercent == 100;
  bool get isPartTime => _contractPercent < 100;
  double get allowedHoursPerDay => allowedHours / 5.0;

  int calculateHoursDifference(int actualHours) {
    return actualHours - allowedHours;
  }

  bool isOverAllowedHours(int actualHours) {
    return actualHours > allowedHours;
  }

  String? getOverageWarning(int actualHours) {
    if (isOverAllowedHours(actualHours)) {
      final overage = calculateHoursDifference(actualHours);
      return 'You are $overage hours over your contract allowance of $allowedHours hours/week';
    }
    return null;
  }

  Map<String, String> getContractSummary() {
    return {
      'contractPercent': contractPercentString,
      'fullTimeHours': fullTimeHoursString,
      'allowedHours': allowedHoursString,
      'dailyHours': '${allowedHoursPerDay.toStringAsFixed(1)} hours/day',
      'contractType': isFullTime ? 'Full-time' : 'Part-time',
    };
  }

  /// Debug method to inspect current state
  Future<void> debugInspectPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    debugPrint('=== ContractProvider Debug Inspection ===');
    debugPrint('In-memory state:');
    debugPrint('  _contractPercent: $_contractPercent');
    debugPrint('  _fullTimeHours: $_fullTimeHours');
    debugPrint('  _trackingStartDate: $_trackingStartDate');
    debugPrint('  _openingFlexMinutes: $_openingFlexMinutes');
    debugPrint('  _employerMode: $_employerMode');
    debugPrint('');
    debugPrint('Local cache (SharedPreferences):');
    debugPrint('  $_contractPercentKey: ${prefs.getInt(_contractPercentKey)}');
    debugPrint('  $_fullTimeHoursKey: ${prefs.getInt(_fullTimeHoursKey)}');
    debugPrint(
        '  $_trackingStartDateKey: ${prefs.getString(_trackingStartDateKey)}');
    debugPrint(
        '  $_openingFlexMinutesKey: ${prefs.getInt(_openingFlexMinutesKey)}');
    debugPrint('  $_employerModeKey: ${prefs.getString(_employerModeKey)}');
    debugPrint('=========================================');
  }
}
