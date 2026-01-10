import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing contract settings and work hour calculations
/// 
/// Handles contract percentage and full-time hours settings, with automatic
/// calculation of allowed work hours based on contract terms. All settings
/// are persisted to SharedPreferences for consistency across app sessions.
class ContractProvider extends ChangeNotifier {
  // Private fields
  int _contractPercent = 100; // Default to 100% (full-time)
  int _fullTimeHours = 40; // Default to 40 hours per week
  
  // SharedPreferences keys
  static const String _contractPercentKey = 'contract_percent';
  static const String _fullTimeHoursKey = 'full_time_hours';
  
  // Getters
  
  /// Current contract percentage (0-100)
  /// 
  /// Represents what percentage of full-time the contract covers.
  /// For example, 50 means a half-time contract, 100 means full-time.
  int get contractPercent => _contractPercent;
  
  /// Full-time hours per week
  /// 
  /// The number of hours considered full-time work per week.
  /// This is used as the base for calculating allowed hours.
  int get fullTimeHours => _fullTimeHours;
  
  /// Calculated allowed work hours per week based on contract percentage
  /// 
  /// This is computed as: (fullTimeHours * contractPercent / 100)
  /// For example: 40 hours * 75% = 30 allowed hours per week
  /// 
  /// NOTE: This rounds to int for backward compatibility. Use weeklyTargetMinutes
  /// for precise calculations without rounding drift.
  int get allowedHours => (fullTimeHours * contractPercent / 100).round();

  /// Calculated allowed work minutes per week based on contract percentage
  /// 
  /// This is computed as: round(fullTimeHours * 60 * contractPercent / 100)
  /// For example: 40 hours * 60 * 75% / 100 = 1800 minutes per week
  /// 
  /// This is the primary value for calculations to avoid rounding drift.
  int get weeklyTargetMinutes {
    return (fullTimeHours * 60.0 * contractPercent / 100.0).round();
  }

  /// Weekly target hours (for display/backward compatibility)
  /// 
  /// Returns weeklyTargetMinutes / 60.0
  double get weeklyTargetHours => weeklyTargetMinutes / 60.0;
  
  // Setters with validation and persistence
  
  /// Set the contract percentage and persist to SharedPreferences
  /// 
  /// [percent] Contract percentage (must be between 0 and 100)
  /// Throws ArgumentError if percent is outside valid range
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
  
  /// Set the full-time hours and persist to SharedPreferences
  /// 
  /// [hours] Full-time hours per week (must be positive)
  /// Throws ArgumentError if hours is not positive
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
  
  // Initialization and persistence methods
  
  /// Initialize the provider by loading all settings from SharedPreferences
  /// 
  /// Should be called once when the provider is created
  Future<void> init() async {
    await _loadAllSettings();
  }
  
  /// Load all contract settings from SharedPreferences
  Future<void> _loadAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load contract percentage with validation
    final savedPercent = prefs.getInt(_contractPercentKey);
    if (savedPercent != null && savedPercent >= 0 && savedPercent <= 100) {
      _contractPercent = savedPercent;
      debugPrint('ContractProvider: Loaded contract percentage: $_contractPercent%');
    } else {
      debugPrint('ContractProvider: Using default contract percentage: $_contractPercent%');
    }
    
    // Load full-time hours with validation
    final savedHours = prefs.getInt(_fullTimeHoursKey);
    if (savedHours != null && savedHours > 0) {
      _fullTimeHours = savedHours;
      debugPrint('ContractProvider: Loaded full-time hours: $_fullTimeHours');
    } else {
      debugPrint('ContractProvider: Using default full-time hours: $_fullTimeHours');
    }
    
    debugPrint('ContractProvider: Calculated allowed hours: $allowedHours ($_fullTimeHours * $_contractPercent% / 100)');
    
    notifyListeners();
  }
  
  /// Save contract percentage to SharedPreferences
  Future<void> _saveContractPercent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_contractPercentKey, _contractPercent);
  }
  
  /// Save full-time hours to SharedPreferences
  Future<void> _saveFullTimeHours() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fullTimeHoursKey, _fullTimeHours);
  }
  
  // Utility methods
  
  /// Get contract percentage as a decimal (0.0 to 1.0)
  /// 
  /// Useful for calculations where a decimal representation is needed.
  /// For example, 75% becomes 0.75
  double get contractPercentAsDecimal => _contractPercent / 100.0;
  
  /// Get formatted contract percentage string
  /// 
  /// Returns a user-friendly string like "75%" or "100%"
  String get contractPercentString => '$_contractPercent%';
  
  /// Get formatted allowed hours string
  /// 
  /// Returns a user-friendly string like "30 hours/week" or "40 hours/week"
  String get allowedHoursString => '$allowedHours hours/week';
  
  /// Get formatted full-time hours string
  /// 
  /// Returns a user-friendly string like "40 hours/week"
  String get fullTimeHoursString => '$_fullTimeHours hours/week';
  
  /// Check if this is a full-time contract (100%)
  bool get isFullTime => _contractPercent == 100;
  
  /// Check if this is a part-time contract (less than 100%)
  bool get isPartTime => _contractPercent < 100;
  
  /// Calculate daily allowed hours based on a 5-day work week
  /// 
  /// Returns the number of hours allowed per day assuming 5 working days per week.
  /// For example, 40 hours/week = 8 hours/day
  double get allowedHoursPerDay => allowedHours / 5.0;
  
  /// Calculate how many hours over/under the allowed amount for a given week
  /// 
  /// [actualHours] The actual hours worked in a week
  /// Returns positive number if over allowed hours, negative if under
  int calculateHoursDifference(int actualHours) {
    return actualHours - allowedHours;
  }
  
  /// Check if given hours exceed the allowed amount
  /// 
  /// [actualHours] The actual hours to check
  /// Returns true if the hours exceed the contract allowance
  bool isOverAllowedHours(int actualHours) {
    return actualHours > allowedHours;
  }
  
  /// Get a warning message if hours exceed allowance
  /// 
  /// [actualHours] The actual hours worked
  /// Returns a warning message if over allowance, null otherwise
  String? getOverageWarning(int actualHours) {
    if (isOverAllowedHours(actualHours)) {
      final overage = calculateHoursDifference(actualHours);
      return 'You are $overage hours over your contract allowance of $allowedHours hours/week';
    }
    return null;
  }
  
  /// Reset contract settings to default values
  /// 
  /// Resets to 100% contract with 40 hours/week full-time
  Future<void> resetToDefaults() async {
    _contractPercent = 100;
    _fullTimeHours = 40;
    
    // Clear from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_contractPercentKey);
    await prefs.remove(_fullTimeHoursKey);
    
    notifyListeners();
  }
  
  /// Validate and update both contract settings at once
  /// 
  /// [percent] New contract percentage (0-100)
  /// [hours] New full-time hours (must be positive)
  /// 
  /// This is useful when updating both values from a form to avoid
  /// multiple notifications and ensure both values are valid together.
  Future<void> updateContractSettings(int percent, int hours) async {
    if (percent < 0 || percent > 100) {
      throw ArgumentError('Contract percentage must be between 0 and 100');
    }
    if (hours <= 0) {
      throw ArgumentError('Full-time hours must be positive');
    }
    
    bool changed = false;
    
    if (_contractPercent != percent) {
      _contractPercent = percent;
      await _saveContractPercent();
      changed = true;
    }
    
    if (_fullTimeHours != hours) {
      _fullTimeHours = hours;
      await _saveFullTimeHours();
      changed = true;
    }
    
    if (changed) {
      notifyListeners();
    }
  }
  
  /// Get contract summary for display purposes
  /// 
  /// Returns a map with formatted contract information suitable for UI display
  Map<String, String> getContractSummary() {
    return {
      'contractPercent': contractPercentString,
      'fullTimeHours': fullTimeHoursString,
      'allowedHours': allowedHoursString,
      'dailyHours': '${allowedHoursPerDay.toStringAsFixed(1)} hours/day',
      'contractType': isFullTime ? 'Full-time' : 'Part-time',
    };
  }
}