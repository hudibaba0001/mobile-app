import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitors network connectivity status and notifies listeners of changes.
/// Provides hooks for sync operations when connectivity is restored.
class NetworkStatusProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool _wasOffline = false;
  DateTime? _lastOfflineTime;
  DateTime? _lastOnlineTime;

  // Callbacks for sync operations when network is restored
  final List<Future<void> Function()> _onConnectivityRestoredCallbacks = [];

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  DateTime? get lastOfflineTime => _lastOfflineTime;
  DateTime? get lastOnlineTime => _lastOnlineTime;

  /// Duration spent offline (null if currently online or never went offline)
  Duration? get offlineDuration {
    if (_lastOfflineTime == null) return null;
    if (_isOnline && _lastOnlineTime != null) {
      return _lastOnlineTime!.difference(_lastOfflineTime!);
    }
    return DateTime.now().difference(_lastOfflineTime!);
  }

  NetworkStatusProvider() {
    _init();
  }

  Future<void> _init() async {
    // Check initial connectivity
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivity(results);
    } catch (e) {
      debugPrint('NetworkStatusProvider: Error checking initial connectivity: $e');
      // Assume online if we can't check
      _isOnline = true;
    }

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectivity,
      onError: (error) {
        debugPrint('NetworkStatusProvider: Connectivity stream error: $error');
      },
    );
  }

  void _updateConnectivity(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    // Check if we have any valid connection
    _isOnline = results.any((result) =>
      result != ConnectivityResult.none
    );

    debugPrint('NetworkStatusProvider: Connectivity changed - Online: $_isOnline (was: $wasOnline)');

    if (!_isOnline && wasOnline) {
      // Just went offline
      _wasOffline = true;
      _lastOfflineTime = DateTime.now();
      debugPrint('NetworkStatusProvider: Device went OFFLINE at $_lastOfflineTime');
    } else if (_isOnline && !wasOnline) {
      // Just came back online
      _lastOnlineTime = DateTime.now();
      debugPrint('NetworkStatusProvider: Device came ONLINE at $_lastOnlineTime');

      if (_wasOffline) {
        debugPrint('NetworkStatusProvider: Triggering connectivity restored callbacks...');
        _triggerConnectivityRestoredCallbacks();
      }
    }

    notifyListeners();
  }

  /// Register a callback to be called when connectivity is restored after being offline
  void addOnConnectivityRestoredCallback(Future<void> Function() callback) {
    _onConnectivityRestoredCallbacks.add(callback);
  }

  /// Remove a previously registered callback
  void removeOnConnectivityRestoredCallback(Future<void> Function() callback) {
    _onConnectivityRestoredCallbacks.remove(callback);
  }

  Future<void> _triggerConnectivityRestoredCallbacks() async {
    for (final callback in _onConnectivityRestoredCallbacks) {
      try {
        await callback();
      } catch (e) {
        debugPrint('NetworkStatusProvider: Error in connectivity restored callback: $e');
      }
    }
  }

  /// Manually check connectivity (useful for retry buttons)
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivity(results);
      return _isOnline;
    } catch (e) {
      debugPrint('NetworkStatusProvider: Error checking connectivity: $e');
      return _isOnline;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _onConnectivityRestoredCallbacks.clear();
    super.dispose();
  }
}
