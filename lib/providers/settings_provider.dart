import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';

class SettingsProvider extends ChangeNotifier {
  Box? _settingsBox;
  bool _isInitialized = false;

  bool _isDarkMode = false;
  bool _isFirstLaunch = true;

  bool get isDarkMode => _isDarkMode;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    try {
      _settingsBox = Hive.box(AppConstants.appSettingsBox);
      _isDarkMode = _settingsBox!.get('isDarkMode', defaultValue: false);
      _isFirstLaunch = _settingsBox!.get('isFirstLaunch', defaultValue: true);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // If box is not available yet, use defaults
      _isDarkMode = false;
      _isFirstLaunch = true;
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
}
