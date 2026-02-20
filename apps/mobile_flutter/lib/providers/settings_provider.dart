import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class SettingsProvider extends ChangeNotifier {
  Box? _settingsBox;
  bool _isInitialized = false;
  SupabaseClient? _supabase;
  String? _userId;
  String? _activeUserId;

  bool _isDarkMode = false;
  bool _isFirstLaunch = true;
  bool _isTravelLoggingEnabled = true;
  bool _isPaidLeaveTrackingEnabled = true;
  bool _isTimeBalanceEnabled = true;
  bool _isSetupCompleted = false;
  DateTime? _baselineDate;
  bool _isDailyReminderEnabled = false;
  int _dailyReminderHour = 17;
  int _dailyReminderMinute = 0;
  String _dailyReminderText = '';
  Locale? _locale;

  static const String _darkModeKey = 'isDarkMode';
  static const String _firstLaunchKey = 'isFirstLaunch';
  static const String _travelLoggingEnabledKey = 'enableTravelLogging';
  static const String _paidLeaveTrackingEnabledKey = 'enablePaidLeaveTracking';
  static const String _timeBalanceEnabledKey = 'enableTimeBalance';
  static const String _setupCompletedKey = 'setupCompleted';
  static const String _baselineDateKey = 'baselineDate';
  static const String _dailyReminderEnabledKey = 'dailyReminderEnabled';
  static const String _dailyReminderHourKey = 'dailyReminderHour';
  static const String _dailyReminderMinuteKey = 'dailyReminderMinute';
  static const String _dailyReminderTextKey = 'dailyReminderText';
  static const String _localeKey = 'locale_code';
  static const String _systemLocaleValue = 'system';
  static const List<String> _supportedLocaleCodes = ['en', 'sv'];

  bool get isDarkMode => _isDarkMode;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isTravelLoggingEnabled => _isTravelLoggingEnabled;
  bool get isPaidLeaveTrackingEnabled => _isPaidLeaveTrackingEnabled;
  bool get isTimeBalanceEnabled => _isTimeBalanceEnabled;
  bool get isSetupCompleted => _isSetupCompleted;
  DateTime? get baselineDate => _baselineDate;
  bool get isDailyReminderEnabled => _isDailyReminderEnabled;
  int get dailyReminderHour => _dailyReminderHour;
  int get dailyReminderMinute => _dailyReminderMinute;
  String get dailyReminderText => _dailyReminderText;
  bool get isInitialized => _isInitialized;
  Locale? get locale => _locale;
  String? get localeCode => _locale?.languageCode;
  bool get isSystemLocale => _locale == null;

  /// Set Supabase dependencies for cloud sync.
  /// Does NOT push to cloud immediately — call loadFromCloud() first
  /// to avoid overwriting server settings with local defaults.
  void setSupabaseDeps(SupabaseClient supabase, String? userId) {
    _supabase = supabase;
    _userId = userId;
    _activeUserId = userId;
    if (_isInitialized) {
      _loadLocalCacheForCurrentUser();
      notifyListeners();
    }
  }

  String _scopedKey(String baseKey) {
    if (_activeUserId == null) return baseKey;
    return '${baseKey}_${_activeUserId!}';
  }

  void _resetToDefaults() {
    _isDarkMode = false;
    _isTravelLoggingEnabled = true;
    _isPaidLeaveTrackingEnabled = true;
    _isTimeBalanceEnabled = true;
    _isSetupCompleted = false;
    _baselineDate = null;
    _isDailyReminderEnabled = false;
    _dailyReminderHour = 17;
    _dailyReminderMinute = 0;
    _dailyReminderText = '';
  }

  void _loadLocaleFromCache() {
    if (_settingsBox == null) return;
    final storedValue = _settingsBox!.get(_localeKey);
    if (storedValue == _systemLocaleValue) {
      _locale = null;
      return;
    }
    if (storedValue is String && storedValue.isNotEmpty) {
      if (_supportedLocaleCodes.contains(storedValue)) {
        _locale = Locale(storedValue);
        return;
      }
    }
    _locale = null;
  }

  void _loadLocalCacheForCurrentUser() {
    _resetToDefaults();
    _loadLocaleFromCache();
    if (_settingsBox == null) return;

    _isDarkMode =
        _settingsBox!.get(_scopedKey(_darkModeKey), defaultValue: _isDarkMode);
    _isTravelLoggingEnabled = _settingsBox!.get(
      _scopedKey(_travelLoggingEnabledKey),
      defaultValue: _isTravelLoggingEnabled,
    );
    _isPaidLeaveTrackingEnabled = _settingsBox!.get(
      _scopedKey(_paidLeaveTrackingEnabledKey),
      defaultValue: _isPaidLeaveTrackingEnabled,
    );
    _isTimeBalanceEnabled = _settingsBox!.get(
      _scopedKey(_timeBalanceEnabledKey),
      defaultValue: _isTimeBalanceEnabled,
    );
    _isSetupCompleted = _settingsBox!.get(
      _scopedKey(_setupCompletedKey),
      defaultValue: _isSetupCompleted,
    );
    final baselineDateRaw = _settingsBox!.get(_scopedKey(_baselineDateKey));
    if (baselineDateRaw is String && baselineDateRaw.isNotEmpty) {
      _baselineDate = DateTime.tryParse(baselineDateRaw);
      if (_baselineDate != null) {
        _baselineDate = DateTime(
            _baselineDate!.year, _baselineDate!.month, _baselineDate!.day);
      }
    } else {
      _baselineDate = null;
    }
    _isDailyReminderEnabled = _settingsBox!.get(
      _scopedKey(_dailyReminderEnabledKey),
      defaultValue: _isDailyReminderEnabled,
    );
    final savedHour = _settingsBox!.get(
      _scopedKey(_dailyReminderHourKey),
      defaultValue: _dailyReminderHour,
    );
    final savedMinute = _settingsBox!.get(
      _scopedKey(_dailyReminderMinuteKey),
      defaultValue: _dailyReminderMinute,
    );
    if (savedHour is int && savedHour >= 0 && savedHour <= 23) {
      _dailyReminderHour = savedHour;
    }
    if (savedMinute is int && savedMinute >= 0 && savedMinute <= 59) {
      _dailyReminderMinute = savedMinute;
    }
    _dailyReminderText = _settingsBox!.get(
          _scopedKey(_dailyReminderTextKey),
          defaultValue: _dailyReminderText,
        ) ??
        '';
  }

  Future<void> init() async {
    try {
      _settingsBox = await Hive.openBox(AppConstants.appSettingsBox);
      _isFirstLaunch = _settingsBox!.get(_firstLaunchKey, defaultValue: true);
      _loadLocalCacheForCurrentUser();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // If box is not available yet, use defaults
      _resetToDefaults();
      _isFirstLaunch = true;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Clear/reload provider state when authenticated user changes.
  Future<void> handleAuthUserChanged(String? userId) async {
    if (_activeUserId == userId) return;
    _activeUserId = userId;
    _userId = userId;

    _loadLocalCacheForCurrentUser();
    notifyListeners();

    if (userId != null) {
      await loadFromCloud();
    }
  }

  /// Load settings from Supabase profiles table
  Future<void> loadFromCloud() async {
    if (_supabase == null || _userId == null) return;

    try {
      final response = await _supabase!
          .from('profiles')
          .select('is_dark_mode, travel_logging_enabled, time_balance_enabled')
          .eq('id', _userId!)
          .maybeSingle();

      if (response != null) {
        if (response['is_dark_mode'] != null) {
          _isDarkMode = response['is_dark_mode'] as bool;
          _settingsBox?.put(_scopedKey(_darkModeKey), _isDarkMode);
        }
        if (response['travel_logging_enabled'] != null) {
          _isTravelLoggingEnabled = response['travel_logging_enabled'] as bool;
          _settingsBox?.put(
              _scopedKey(_travelLoggingEnabledKey), _isTravelLoggingEnabled);
        }
        if (response['time_balance_enabled'] != null) {
          _isTimeBalanceEnabled = response['time_balance_enabled'] as bool;
          _settingsBox?.put(
              _scopedKey(_timeBalanceEnabledKey), _isTimeBalanceEnabled);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('SettingsProvider: Error loading from cloud: $e');
    }
  }

  /// Fire-and-forget sync to cloud
  void _syncToCloud() {
    if (_supabase == null || _userId == null) return;

    _supabase!
        .from('profiles')
        .update({
          'is_dark_mode': _isDarkMode,
          'travel_logging_enabled': _isTravelLoggingEnabled,
          'time_balance_enabled': _isTimeBalanceEnabled,
        })
        .eq('id', _userId!)
        .then((_) {
          debugPrint('SettingsProvider: Synced settings to cloud');
        })
        .catchError((e) {
          debugPrint('SettingsProvider: Error syncing to cloud: $e');
        });
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    if (_settingsBox != null) {
      await _settingsBox!.put(_scopedKey(_darkModeKey), value);
    }
    _syncToCloud();
    notifyListeners();
  }

  Future<void> setFirstLaunch(bool value) async {
    _isFirstLaunch = value;
    if (_settingsBox != null) {
      await _settingsBox!.put(_firstLaunchKey, value);
    }
    notifyListeners();
  }

  Future<void> setTravelLoggingEnabled(bool value) async {
    _isTravelLoggingEnabled = value;
    if (_settingsBox != null) {
      await _settingsBox!.put(_scopedKey(_travelLoggingEnabledKey), value);
    }
    _syncToCloud();
    notifyListeners();
  }

  Future<void> setPaidLeaveTrackingEnabled(bool value) async {
    _isPaidLeaveTrackingEnabled = value;
    if (_settingsBox != null) {
      await _settingsBox!.put(_scopedKey(_paidLeaveTrackingEnabledKey), value);
    }
    notifyListeners();
  }

  Future<void> setTimeBalanceEnabled(bool value) async {
    _isTimeBalanceEnabled = value;
    if (_settingsBox != null) {
      await _settingsBox!.put(_scopedKey(_timeBalanceEnabledKey), value);
    }
    _syncToCloud();
    notifyListeners();
  }

  Future<void> setSetupCompleted(bool value) async {
    _isSetupCompleted = value;
    if (_settingsBox != null) {
      await _settingsBox!.put(_scopedKey(_setupCompletedKey), value);
    }
    notifyListeners();
  }

  Future<void> setBaselineDate(DateTime? date) async {
    _baselineDate =
        date == null ? null : DateTime(date.year, date.month, date.day);
    if (_settingsBox != null) {
      if (_baselineDate == null) {
        await _settingsBox!.delete(_scopedKey(_baselineDateKey));
      } else {
        final value =
            '${_baselineDate!.year.toString().padLeft(4, '0')}-${_baselineDate!.month.toString().padLeft(2, '0')}-${_baselineDate!.day.toString().padLeft(2, '0')}';
        await _settingsBox!.put(_scopedKey(_baselineDateKey), value);
      }
    }
    notifyListeners();
  }

  Future<void> setDailyReminderEnabled(bool value) async {
    _isDailyReminderEnabled = value;
    if (_settingsBox != null) {
      await _settingsBox!.put(_scopedKey(_dailyReminderEnabledKey), value);
    }
    notifyListeners();
  }

  Future<void> setDailyReminderTime({
    required int hour,
    required int minute,
  }) async {
    if (hour < 0 || hour > 23) return;
    if (minute < 0 || minute > 59) return;

    _dailyReminderHour = hour;
    _dailyReminderMinute = minute;
    if (_settingsBox != null) {
      await _settingsBox!.put(_scopedKey(_dailyReminderHourKey), hour);
      await _settingsBox!.put(_scopedKey(_dailyReminderMinuteKey), minute);
    }
    notifyListeners();
  }

  Future<void> setDailyReminderText(String value) async {
    _dailyReminderText = value;
    if (_settingsBox != null) {
      await _settingsBox!.put(_scopedKey(_dailyReminderTextKey), value);
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale? value) async {
    _locale = value;
    if (_settingsBox != null) {
      if (value == null) {
        await _settingsBox!.put(_localeKey, _systemLocaleValue);
      } else {
        await _settingsBox!.put(_localeKey, value.languageCode);
      }
    }
    notifyListeners();
  }
}
