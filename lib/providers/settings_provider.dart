import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';

class SettingsProvider extends ChangeNotifier {
  Box? _settingsBox;
  bool _isInitialized = false;

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

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    if (_settingsBox != null) {
      await _settingsBox!.put('isDarkMode', value);
    }
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
    notifyListeners();
  }

  Future<void> setTimeBalanceEnabled(bool value) async {
    _isTimeBalanceEnabled = value;
    if (_settingsBox != null) {
      await _settingsBox!.put(_timeBalanceEnabledKey, value);
    }
    notifyListeners();
  }
}
