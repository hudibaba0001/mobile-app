import '../models/location.dart';
import '../repositories/location_repository.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';
import '../utils/data_validator.dart';

class LocationService {
  final LocationRepository _locationRepository;

  LocationService({required LocationRepository locationRepository})
      : _locationRepository = locationRepository;

  /// Get frequent locations based on usage
  Future<List<Location>> getFrequentLocations({int limit = 10}) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _locationRepository.getFrequentLocations(limit: limit),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Get location suggestions for autocomplete
  Future<List<String>> getLocationSuggestions(String query, {int limit = 5}) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _getLocationSuggestionsInternal(query, limit),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<List<String>> _getLocationSuggestionsInternal(String query, int limit) async {
    // Validate search query
    final validationErrors = DataValidator.validateSearchQuery(query);
    if (validationErrors.isNotEmpty) {
      throw validationErrors.first;
    }

    final sanitizedQuery = DataValidator.sanitizeString(query);
    if (sanitizedQuery.isEmpty) {
      // Return frequent locations if query is empty
      final frequentLocations = await _locationRepository.getFrequentLocations(limit: limit);
      return frequentLocations.map((loc) => loc.address).toList();
    }

    final matchingLocations = await _locationRepository.searchLocations(sanitizedQuery);
    return matchingLocations.take(limit).map((loc) => loc.address).toList();
  }

  /// Save location from manual entry
  Future<Location?> saveLocationFromEntry(String address, {String? name}) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _saveLocationFromEntryInternal(address, name),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<Location?> _saveLocationFromEntryInternal(String address, String? name) async {
    final sanitizedAddress = DataValidator.sanitizeString(address);
    if (sanitizedAddress.isEmpty) {
      throw ErrorHandler.handleValidationError('Address cannot be empty');
    }

    // Check if location already exists
    final existingLocation = await _locationRepository.findLocationByAddress(sanitizedAddress);
    if (existingLocation != null) {
      return existingLocation;
    }

    // Create new location
    final locationName = name ?? _generateLocationName(sanitizedAddress);
    final newLocation = Location(
      name: locationName,
      address: sanitizedAddress,
    );

    // Validate before saving
    final validationErrors = DataValidator.validateLocation(newLocation);
    if (validationErrors.isNotEmpty) {
      throw validationErrors.first;
    }

    await _locationRepository.addLocation(newLocation);
    return newLocation;
  }

  String _generateLocationName(String address) {
    // Extract a reasonable name from the address
    final parts = address.split(',');
    if (parts.isNotEmpty) {
      final firstPart = parts.first.trim();
      // If it looks like a street address, use it
      if (firstPart.length <= 50) {
        return firstPart;
      }
    }
    
    // Fallback to first 50 characters
    return address.length <= 50 ? address : '${address.substring(0, 47)}...';
  }

  /// Get all locations with sorting options
  Future<List<Location>> getAllLocations({LocationSortOption sortBy = LocationSortOption.usage}) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _getAllLocationsInternal(sortBy),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<List<Location>> _getAllLocationsInternal(LocationSortOption sortBy) async {
    final locations = await _locationRepository.getAllLocations();
    
    switch (sortBy) {
      case LocationSortOption.name:
        locations.sort((a, b) => a.name.compareTo(b.name));
        break;
      case LocationSortOption.usage:
        locations.sort((a, b) => b.usageCount.compareTo(a.usageCount));
        break;
      case LocationSortOption.recent:
        locations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case LocationSortOption.favorite:
        locations.sort((a, b) {
          if (a.isFavorite && !b.isFavorite) return -1;
          if (!a.isFavorite && b.isFavorite) return 1;
          return b.usageCount.compareTo(a.usageCount);
        });
        break;
    }
    
    return locations;
  }

  /// Add new location
  Future<void> addLocation(Location location) async {
    try {
      await RetryHelper.executeWithRetry(
        () async => _addLocationInternal(location),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<void> _addLocationInternal(Location location) async {
    // Validate location
    final validationErrors = DataValidator.validateLocation(location);
    if (validationErrors.isNotEmpty) {
      throw validationErrors.first;
    }

    // Check for duplicates
    final existingLocation = await _locationRepository.findLocationByAddress(location.address);
    if (existingLocation != null) {
      throw ErrorHandler.handleValidationError('A location with this address already exists');
    }

    await _locationRepository.addLocation(location);
  }

  /// Update location
  Future<void> updateLocation(Location location) async {
    try {
      await RetryHelper.executeWithRetry(
        () async => _updateLocationInternal(location),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<void> _updateLocationInternal(Location location) async {
    // Validate location
    final validationErrors = DataValidator.validateLocation(location);
    if (validationErrors.isNotEmpty) {
      throw validationErrors.first;
    }

    await _locationRepository.updateLocation(location);
  }

  /// Delete location
  Future<void> deleteLocation(String locationId) async {
    try {
      await RetryHelper.executeWithRetry(
        () async => _locationRepository.deleteLocation(locationId),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String locationId) async {
    try {
      await RetryHelper.executeWithRetry(
        () async => _toggleFavoriteInternal(locationId),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<void> _toggleFavoriteInternal(String locationId) async {
    final location = await _locationRepository.getLocationById(locationId);
    if (location == null) {
      throw ErrorHandler.handleValidationError('Location not found');
    }

    final updatedLocation = location.toggleFavorite();
    await _locationRepository.updateLocation(updatedLocation);
  }

  /// Search locations
  Future<List<Location>> searchLocations(String query) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _searchLocationsInternal(query),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<List<Location>> _searchLocationsInternal(String query) async {
    // Validate search query
    final validationErrors = DataValidator.validateSearchQuery(query);
    if (validationErrors.isNotEmpty) {
      throw validationErrors.first;
    }

    final sanitizedQuery = DataValidator.sanitizeString(query);
    return await _locationRepository.searchLocations(sanitizedQuery);
  }

  /// Get favorite locations
  Future<List<Location>> getFavoriteLocations() async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _locationRepository.getFavoriteLocations(),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Get location statistics
  Future<Map<String, dynamic>> getLocationStatistics() async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _getLocationStatisticsInternal(),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<Map<String, dynamic>> _getLocationStatisticsInternal() async {
    final allLocations = await _locationRepository.getAllLocations();
    
    if (allLocations.isEmpty) {
      return {
        'totalLocations': 0,
        'favoriteLocations': 0,
        'mostUsedLocation': 'None',
        'averageUsageCount': 0.0,
        'unusedLocations': 0,
      };
    }

    final favoriteCount = allLocations.where((loc) => loc.isFavorite).length;
    final unusedCount = allLocations.where((loc) => loc.usageCount == 0).length;
    final totalUsage = allLocations.fold(0, (sum, loc) => sum + loc.usageCount);
    
    final mostUsedLocation = allLocations.reduce((a, b) => 
        a.usageCount > b.usageCount ? a : b);

    return {
      'totalLocations': allLocations.length,
      'favoriteLocations': favoriteCount,
      'mostUsedLocation': mostUsedLocation.name,
      'averageUsageCount': totalUsage / allLocations.length,
      'unusedLocations': unusedCount,
    };
  }

  /// Get location by ID
  Future<Location?> getLocationById(String id) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _locationRepository.getLocationById(id),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Find location by address
  Future<Location?> findLocationByAddress(String address) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _locationRepository.findLocationByAddress(address),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Get smart location suggestions based on context
  Future<List<Location>> getSmartSuggestions({
    String? currentLocation,
    DateTime? timeOfDay,
    int limit = 5,
  }) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _getSmartSuggestionsInternal(currentLocation, timeOfDay, limit),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  Future<List<Location>> _getSmartSuggestionsInternal(
    String? currentLocation,
    DateTime? timeOfDay,
    int limit,
  ) async {
    final allLocations = await _locationRepository.getAllLocations();
    
    // Score locations based on various factors
    final scoredLocations = allLocations.map((location) {
      double score = location.usageCount.toDouble();
      
      // Boost favorite locations
      if (location.isFavorite) {
        score *= 1.5;
      }
      
      // Boost recently used locations
      final daysSinceCreated = DateTime.now().difference(location.createdAt).inDays;
      if (daysSinceCreated < 7) {
        score *= 1.2;
      }
      
      return MapEntry(location, score);
    }).toList();
    
    // Sort by score and return top suggestions
    scoredLocations.sort((a, b) => b.value.compareTo(a.value));
    return scoredLocations.take(limit).map((e) => e.key).toList();
  }
}

enum LocationSortOption {
  name,
  usage,
  recent,
  favorite,
}