// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/map_config.dart';
import 'travel_cache_service.dart';

/// Service for calculating travel time and distance using Mapbox API
///
/// This service uses the Mapbox Directions API to calculate:
/// - Travel time by car
/// - Distance between two addresses
class MapService {
  static const String _baseUrl =
      'https://api.mapbox.com/directions/v5/mapbox/driving';

  /// Calculate travel time and distance between two addresses
  ///
  /// [origin] - Starting address (e.g., "New York, NY")
  /// [destination] - Destination address (e.g., "Boston, MA")
  /// [originPlaceId] - Optional place ID for origin (for better caching)
  /// [destinationPlaceId] - Optional place ID for destination (for better caching)
  /// [useCache] - Whether to check cache first (default: true)
  ///
  /// Returns a Map with:
  /// - 'durationMinutes': Travel time in minutes
  /// - 'distanceMeters': Distance in meters
  /// - 'durationText': Human-readable duration (e.g., "2 hours 30 mins")
  /// - 'distanceText': Human-readable distance (e.g., "200 km")
  ///
  /// Throws an exception if the API call fails
  static Future<Map<String, dynamic>> calculateTravelTime({
    required String origin,
    required String destination,
    String? originPlaceId,
    String? destinationPlaceId,
    bool useCache = true,
  }) async {
    // Check cache first if enabled
    if (useCache) {
      final cacheService = TravelCacheService();
      await cacheService.init();

      final cached = cacheService.getCachedRoute(
        fromPlaceId: originPlaceId,
        toPlaceId: destinationPlaceId,
        fromText: origin,
        toText: destination,
      );

      if (cached != null) {
        debugPrint(
            'MapService: ✅ Using cached route: ${cached.minutes} minutes');
        final distanceMeters = cached.distanceKm != null
            ? (cached.distanceKm! * 1000).round()
            : null;
        return {
          'durationMinutes': cached.minutes,
          'distanceMeters': distanceMeters,
          'durationText': _formatDuration(cached.minutes),
          'distanceText': cached.distanceKm != null
              ? _formatDistance(cached.distanceKm! * 1000)
              : '',
          'distanceKm': cached.distanceKm,
        };
      }
    }
    if (!MapConfig.isConfigured) {
      throw Exception(
          'Mapbox API key not configured. Please add your API key in lib/config/map_config.dart');
    }

    try {
      // First, geocode the addresses to get coordinates
      final originCoords = await _geocodeAddress(origin);
      final destCoords = await _geocodeAddress(destination);

      // Build the directions API URL with coordinates
      final coordinates =
          '${originCoords['lng']},${originCoords['lat']};${destCoords['lng']},${destCoords['lat']}';

      final uri = Uri.parse('$_baseUrl/$coordinates').replace(queryParameters: {
        'access_token': MapConfig.mapboxApiKey,
        'geometries': 'geojson',
        'overview': 'full',
        'steps': 'false',
      });

      debugPrint(
          'MapService: Calculating travel time from "$origin" to "$destination"');

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to calculate travel time: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      if (data['code'] != 'Ok') {
        final errorMessage = data['message'] ?? data['code'];
        throw Exception('Mapbox API error: $errorMessage');
      }

      final routes = data['routes'] as List;
      if (routes.isEmpty) {
        throw Exception('No route found between the addresses');
      }

      final route = routes[0];
      final duration =
          (route['duration'] as num).toDouble(); // Duration in seconds
      final distance =
          (route['distance'] as num).toDouble(); // Distance in meters

      final durationMinutes = (duration / 60).round();
      final durationText = _formatDuration(durationMinutes);
      final distanceText = _formatDistance(distance);
      final distanceKm = distance / 1000;

      debugPrint(
          'MapService: ✅ Calculated travel time: $durationMinutes minutes ($durationText)');
      debugPrint(
          'MapService: ✅ Distance: ${distanceKm.toStringAsFixed(1)} km ($distanceText)');

      // Cache the result
      if (useCache) {
        final cacheService = TravelCacheService();
        await cacheService.init();
        await cacheService.saveRouteNamed(
          fromPlaceId: originPlaceId,
          toPlaceId: destinationPlaceId,
          fromText: origin,
          toText: destination,
          minutes: durationMinutes,
          distanceKm: distanceKm,
        );
      }

      return {
        'durationMinutes': durationMinutes,
        'distanceMeters': distance.round(),
        'durationText': durationText,
        'distanceText': distanceText,
        'distanceKm': distanceKm,
      };
    } catch (e) {
      debugPrint('MapService: ❌ Error calculating travel time: $e');
      rethrow;
    }
  }

  /// Geocode an address to get coordinates using Mapbox Geocoding API
  static Future<Map<String, double>> _geocodeAddress(String address) async {
    final geocodeUrl =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(address)}.json';
    final uri = Uri.parse(geocodeUrl).replace(queryParameters: {
      'access_token': MapConfig.mapboxApiKey,
      'limit': '1',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to geocode address: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final features = data['features'] as List;

    if (features.isEmpty) {
      throw Exception('Address not found: $address');
    }

    final coordinates = features[0]['center'] as List;
    return {
      'lng': (coordinates[0] as num).toDouble(),
      'lat': (coordinates[1] as num).toDouble(),
    };
  }

  /// Format duration in minutes to human-readable string
  static String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min${minutes != 1 ? 's' : ''}';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours hour${hours != 1 ? 's' : ''}';
    }
    return '$hours hour${hours != 1 ? 's' : ''} $mins min${mins != 1 ? 's' : ''}';
  }

  /// Format distance in meters to human-readable string
  static String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = meters / 1000;
    if (km < 10) {
      return '${km.toStringAsFixed(1)} km';
    }
    return '${km.round()} km';
  }

  /// Get address suggestions (autocomplete) using Mapbox Geocoding API
  ///
  /// [query] - The search query (address or place name)
  /// [limit] - Maximum number of suggestions to return (default: 5)
  ///
  /// Returns a list of suggested addresses with their full address strings
  static Future<List<String>> getAddressSuggestions(
    String query, {
    int limit = 5,
  }) async {
    if (!MapConfig.isConfigured) {
      return [];
    }

    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final geocodeUrl =
          'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json';
      final uri = Uri.parse(geocodeUrl).replace(queryParameters: {
        'access_token': MapConfig.mapboxApiKey,
        'limit': limit.toString(),
        'types': 'address,poi,place', // Focus on addresses and places
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint(
            'MapService: Failed to get address suggestions: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final features = data['features'] as List?;

      if (features == null || features.isEmpty) {
        return [];
      }

      // Extract address strings from features
      final suggestions = features
          .map((feature) {
            return feature['place_name'] as String? ?? '';
          })
          .where((address) => address.isNotEmpty)
          .toList();

      debugPrint(
          'MapService: Found ${suggestions.length} address suggestions for "$query"');
      return suggestions;
    } catch (e) {
      debugPrint('MapService: Error getting address suggestions: $e');
      return [];
    }
  }

  /// Check if the service is configured (API key is set)
  static bool get isConfigured => MapConfig.isConfigured;
}
