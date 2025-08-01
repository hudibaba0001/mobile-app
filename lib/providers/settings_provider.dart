import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';

class SettingsProvider extends ChangeNotifier {
  final Box _settingsBox = Hive.box(AppConstants.appSettingsBox);

  bool _isDarkMode = false;
  bool _isFirstLaunch = true;

  bool get isDarkMode => _isDarkMode;
  bool get isFirstLaunch => _isFirstLaunch;

  Future<void> init() async {
    _isDarkMode = _settingsBox.get('isDarkMode', defaultValue: false);
    _isFirstLaunch = _settingsBox.get('isFirstLaunch', defaultValue: true);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _settingsBox.put('isDarkMode', value);
    notifyListeners();
  }

  Future<void> setFirstLaunch(bool value) async {
    _isFirstLaunch = value;
    await _settingsBox.put('isFirstLaunch', value);
    notifyListeners();
  }
}