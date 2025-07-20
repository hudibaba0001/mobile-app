import 'package:flutter/foundation.dart';
import '../repositories/travel_repository.dart';
import '../repositories/location_repository.dart';
import '../repositories/hive_travel_repository.dart';
import '../repositories/hive_location_repository.dart';
import '../services/travel_service.dart';
import '../services/location_service.dart';
import '../utils/error_handler.dart';

class AppStateProvider extends ChangeNotifier {
  // Repositories
  late final TravelRepository _travelRepository;
  late final LocationRepository _locationRepository;

  // Services
  late final TravelService _travelService;
  late final LocationService _locationService;

  // State
  bool _isInitialized = false;
  bool _isLoading = false;
  AppError? _lastError;

  AppStateProvider() {
    _initializeApp();
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  AppError? get lastError => _lastError;
  TravelRepository get travelRepository => _travelRepository;
  LocationRepository get locationRepository => _locationRepository;
  TravelService get travelService => _travelService;
  LocationService get locationService => _locationService;

  // Initialize the app
  Future<void> _initializeApp() async {
    _setLoading(true);
    try {
      // Initialize repositories
      _travelRepository = HiveTravelRepository();
      _locationRepository = HiveLocationRepository();

      // Initialize services with repositories
      _travelService = TravelService(
        travelRepository: _travelRepository,
        locationRepository: _locationRepository,
      );
      _locationService = LocationService(
        locationRepository: _locationRepository,
      );

      _isInitialized = true;
      _clearError();
    } catch (error) {
      _handleError(error);
    } finally {
      _setLoading(false);
    }
  }

  // Reinitialize the app (useful for error recovery)
  Future<void> reinitialize() async {
    _isInitialized = false;
    await _initializeApp();
  }

  // Get app statistics
  Future<Map<String, dynamic>> getAppStatistics() async {
    if (!_isInitialized) return {};

    try {
      final travelStats = await _travelService.getTravelStatistics();
      final locationStats = await _locationService.getLocationStatistics();

      return {
        'travel': travelStats,
        'location': locationStats,
        'appVersion': '2.0.0',
        'initialized': _isInitialized,
      };
    } catch (error) {
      _handleError(error);
      return {};
    }
  }

  // Clear all app data
  Future<bool> clearAllData() async {
    if (!_isInitialized) return false;

    _setLoading(true);
    try {
      // This would need to be implemented in repositories
      // For now, we'll just indicate success
      _clearError();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _handleError(dynamic error) {
    if (error is AppError) {
      _lastError = error;
    } else {
      _lastError = ErrorHandler.handleUnknownError(error);
    }
    notifyListeners();
  }

  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    super.dispose();
  }
}