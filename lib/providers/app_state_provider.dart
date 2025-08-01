import 'package:flutter/foundation.dart';

class AppStateProvider extends ChangeNotifier {
  bool _isInitialized = false;
  String? _error;

  bool get isInitialized => _isInitialized;
  String? get error => _error;

  Future<void> initialize() async {
    try {
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}