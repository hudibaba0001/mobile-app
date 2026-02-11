import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

class SettingsProvider extends ChangeNotifier {
  Box? _settingsBox;
  bool _isInitialized = false;
  SupabaseClient? _supabase;
  String? _userId;

  bool _isDarkMode = false;
  bool _isFirstLaunch = true;
  bool _isTravelLoggingEnabled = true;
  bool _isTimeBalanceEnabled = true;

  static const String _travelLoggingEnabledKey = 'enableTravelLogging';
  static const String _timeBalanceEnabledKey = 'enableTimeBalance';

  bool get isDarkMode => _isDarkMode;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isTravelLoggingEnabled => _isTravelLoggingEnabled;
  bool get isTimeBalanceEnabled => _isTimeBalanceEnabled;
  bool get isInitialized => _isInitialized;

  /// Set Supabase dependencies for cloud sync.
  /// Does NOT push to cloud immediately — call loadFromCloud() first
  /// to avoid overwriting server settings with local defaults.
  void setSupabaseDeps(SupabaseClient supabase, String? userId) {
    _supabase = supabase;
    _userId = userId;
  }

  Future<void> init() async {
    try {
      _settingsBox = await Hive.openBox(AppConstants.appSettingsBox);
      _isDarkMode = _settingsBox!.get('isDarkMode', defaultValue: false);
      _isFirstLaunch = _settingsBox!.get('isFirstLaunch', defaultValue: true);
      _isTravelLoggingEnabled =
          _settingsBox!.get(_travelLoggingEnabledKey, defaultValue: true);
      _isTimeBalanceEnabled =
          _settingsBox!.get(_timeBalanceEnabledKey, defaultValue: true);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // If box is not available yet, use defaults
      _isDarkMode = false;
      _isFirstLaunch = true;
      _isTravelLoggingEnabled = true;
      _isTimeBalanceEnabled = true;
      _isInitialized = true;
      notifyListeners();
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
          _settingsBox?.put('isDarkMode', _isDarkMode);
        }
        if (response['travel_logging_enabled'] != null) {
          _isTravelLoggingEnabled = response['travel_logging_enabled'] as bool;
          _settingsBox?.put(_travelLoggingEnabledKey, _isTravelLoggingEnabled);
        }
        if (response['time_balance_enabled'] != null) {
          _isTimeBalanceEnabled = response['time_balance_enabled'] as bool;
          _settingsBox?.put(_timeBalanceEnabledKey, _isTimeBalanceEnabled);
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

    _supabase!.from('profiles').update({
      'is_dark_mode': _isDarkMode,
      'travel_logging_enabled': _isTravelLoggingEnabled,
      'time_balance_enabled': _isTimeBalanceEnabled,
    }).eq('id', _userId!).then((_) {
      debugPrint('SettingsProvider: Synced settings to cloud');
    }).catchError((e) {
      debugPrint('SettingsProvider: Error syncing to cloud: $e');
    });
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    if (_settingsBox != null) {
      await _settingsBox!.put('isDarkMode', value);
    }
    _syncToCloud();
    notifyListeners();
  }

  Future<void> setFirstLaunch(bool value) async {
    _isFirstLaunch = value;
    if (_settingsBox != null) {
      await _settingsBox!.put('isFirstLaunch', value);
    }
    notifyListeners();
  }

  Future<void> setTravelLoggingEnabled(bool value) async {
    _isTravelLoggingEnabled = value;
    if (_settingsBox != null) {
      await _settingsBox!.put(_travelLoggingEnabledKey, value);
    }
    _syncToCloud();
    notifyListeners();
  }

  Future<void> setTimeBalanceEnabled(bool value) async {
    _isTimeBalanceEnabled = value;
    if (_settingsBox != null) {
      await _settingsBox!.put(_timeBalanceEnabledKey, value);
    }
    _syncToCloud();
    notifyListeners();
  }
}
