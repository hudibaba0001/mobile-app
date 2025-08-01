import 'package:flutter/foundation.dart';
import '../models/location.dart';
import '../repositories/location_repository.dart';
import '../repositories/hive_location_repository.dart';
import '../services/location_service.dart';
import '../utils/error_handler.dart';

class LocationProvider extends ChangeNotifier {
  final LocationRepository _repository;
  final LocationService _service;

  List<Location> _locations = [];
  List<Location> _filteredLocations = [];
  List<Location> _favoriteLocations = [];
  List<Location> _frequentLocations = [];
  bool _isLoading = false;
  String _searchQuery = '';
  LocationSortOption _sortOption = LocationSortOption.usage;
  AppError? _lastError;

  LocationProvider({
    LocationRepository? repository,
    LocationService? service,
  }) : _repository = repository ?? HiveLocationRepository(),
        _service = service ?? LocationService(
          locationRepository: repository ?? HiveLocationRepository(),
        ) {
    _loadLocations();
  }

  // Getters
  List<Location> get locations => List.unmodifiable(_locations);
  List<Location> get filteredLocations => List.unmodifiable(_filteredLocations);
  List<Location> get favoriteLocations => List.unmodifiable(_favoriteLocations);
  List<Location> get frequentLocations => List.unmodifiable(_frequentLocations);
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  LocationSortOption get sortOption => _sortOption;
  AppError? get lastError => _lastError;
  bool get hasLocations => _locations.isNotEmpty;
  bool get hasFilteredLocations => _filteredLocations.isNotEmpty;
  bool get hasFavorites => _favoriteLocations.isNotEmpty;

  // Statistics getters
  int get totalLocations => _locations.length;
  int get totalFavorites => _favoriteLocations.length;
  int get totalUsedLocations => _locations.where((loc) => loc.usageCount > 0).length;
  int get totalUnusedLocations => _locations.where((loc) => loc.usageCount == 0).length;
  Location? get mostUsedLocation {
    if (_locations.isEmpty) return null;
    return _locations.reduce((a, b) => a.usageCount > b.usageCount ? a : b);
  }

  // Load all locations
  Future<void> _loadLocations() async {
    _setLoading(true);
    try {
      _locations = await _service.getAllLocations(sortBy: _sortOption);
      _favoriteLocations = await _service.getFavoriteLocations();
      _frequentLocations = await _service.getFrequentLocations();
      _applyFilters();
      _clearError();
    } catch (error) {
      _handleError(error);
    } finally {
      _setLoading(false);
    }
  }

  // Refresh locations
  Future<void> refreshLocations() async {
    await _loadLocations();
  }

  // Add new location
  Future<bool> addLocation(Location location) async {
    _setLoading(true);
    try {
      await _service.addLocation(location);
      await _loadLocations();
      _clearError();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update existing location
  Future<bool> updateLocation(Location location) async {
    _setLoading(true);
    try {
      await _service.updateLocation(location);
      await _loadLocations();
      _clearError();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete location
  Future<bool> deleteLocation(String locationId) async {
    _setLoading(true);
    try {
      await _service.deleteLocation(locationId);
      await _loadLocations();
      _clearError();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(String locationId) async {
    _setLoading(true);
    try {
      await _service.toggleFavorite(locationId);
      await _loadLocations();
      _clearError();
      return true;
    } catch (error) {
      _handleError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Search locations
  void searchLocations(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Set sort option
  void setSortOption(LocationSortOption option) {
    _sortOption = option;
    _loadLocations(); // Reload with new sorting
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  // Apply current filters
  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredLocations = List.from(_locations);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredLocations = _locations.where((location) {
        return location.name.toLowerCase().contains(query) ||
               location.address.toLowerCase().contains(query);
      }).toList();
    }
  }

  // Get location suggestions for autocomplete
  Future<List<String>> getLocationSuggestions(String query, {int limit = 5}) async {
    try {
      return await _service.getLocationSuggestions(query, limit: limit);
    } catch (error) {
      _handleError(error);
      return [];
    }
  }

  // Save location from manual entry
  Future<Location?> saveLocationFromEntry(String address, {String? name}) async {
    try {
      final location = await _service.saveLocationFromEntry(address, name: name);
      if (location != null) {
        await _loadLocations();
      }
      _clearError();
      return location;
    } catch (error) {
      _handleError(error);
      return null;
    }
  }

  // Get location by ID
  Location? getLocationById(String id) {
    try {
      return _locations.firstWhere((location) => location.id == id);
    } catch (e) {
      return null;
    }
  }

  // Find location by address
  Future<Location?> findLocationByAddress(String address) async {
    try {
      return await _service.findLocationByAddress(address);
    } catch (error) {
      _handleError(error);
      return null;
    }
  }

  // Get smart suggestions based on context
  Future<List<Location>> getSmartSuggestions({
    String? currentLocation,
    DateTime? timeOfDay,
    int limit = 5,
  }) async {
    try {
      return await _service.getSmartSuggestions(
        currentLocation: currentLocation,
        timeOfDay: timeOfDay,
        limit: limit,
      );
    } catch (error) {
      _handleError(error);
      return [];
    }
  }

  // Get location statistics
  Future<Map<String, dynamic>> getLocationStatistics() async {
    try {
      return await _service.getLocationStatistics();
    } catch (error) {
      _handleError(error);
      return {};
    }
  }

  // Get locations by usage frequency
  List<Location> getLocationsByUsage({int limit = 10}) {
    final sortedLocations = List<Location>.from(_locations)
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return sortedLocations.take(limit).toList();
  }

  // Get recently added locations
  List<Location> getRecentlyAddedLocations({int limit = 5}) {
    final sortedLocations = List<Location>.from(_locations)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedLocations.take(limit).toList();
  }

  // Check if location exists by address
  bool locationExistsByAddress(String address) {
    return _locations.any((location) => 
        location.address.toLowerCase() == address.toLowerCase());
  }

  // Get location name suggestions for autocomplete
  List<String> getLocationNameSuggestions(String query, {int limit = 5}) {
    if (query.isEmpty) return [];
    
    final queryLower = query.toLowerCase();
    final suggestions = _locations
        .where((location) => location.name.toLowerCase().contains(queryLower))
        .map((location) => location.name)
        .take(limit)
        .toList();
    
    return suggestions;
  }

  // Get address suggestions for autocomplete
  List<String> getAddressSuggestions(String query, {int limit = 5}) {
    if (query.isEmpty) return [];
    
    final queryLower = query.toLowerCase();
    final suggestions = _locations
        .where((location) => location.address.toLowerCase().contains(queryLower))
        .map((location) => location.address)
        .take(limit)
        .toList();
    
    return suggestions;
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

}