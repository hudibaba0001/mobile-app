import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cached route data with timestamp
class CachedRoute {
  final int minutes;
  final double? distanceKm;
  final DateTime cachedAt;

  CachedRoute({
    required this.minutes,
    this.distanceKm,
    required this.cachedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'minutes': minutes,
      'distance_km': distanceKm,
      'cached_at': cachedAt.toIso8601String(),
    };
  }

  factory CachedRoute.fromJson(Map<String, dynamic> json) {
    return CachedRoute(
      minutes: json['minutes'] as int,
      distanceKm: json['distance_km'] as double?,
      cachedAt: DateTime.parse(json['cached_at'] as String),
    );
  }

  /// Check if cache is stale (older than 7 days)
  bool get isStale {
    final age = DateTime.now().difference(cachedAt);
    return age.inDays > 7;
  }
}

class TravelCacheService {
  static const String _storageKey = 'travel_route_cache';

  // Cache structure: "fromPlaceId|toPlaceId|mode" or "fromText|toText|mode" -> CachedRoute
  Map<String, CachedRoute> _cache = {};
  bool _initialized = false;

  /// Initialize the cache from SharedPreferences
  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        _cache = decoded.map((key, value) {
          final route = CachedRoute.fromJson(value as Map<String, dynamic>);
          // Remove stale entries on load
          if (route.isStale) {
            return MapEntry(key, route); // Will be filtered out
          }
          return MapEntry(key, route);
        });
        // Remove stale entries
        _cache.removeWhere((key, route) => route.isStale);
        await _persistCache(); // Save cleaned cache
      } catch (e) {
        debugPrint('Error parsing travel cache: $e');
      }
    }

    _initialized = true;
  }

  /// Get cached route data for a route
  /// Prefers placeId if available, falls back to text
  /// Returns null if route is not found or stale
  CachedRoute? getCachedRoute({
    String? fromPlaceId,
    String? toPlaceId,
    String? fromText,
    String? toText,
    String mode = 'driving',
  }) {
    if (!_initialized) return null;

    String? key;

    // Prefer placeId-based key if available
    if (fromPlaceId != null && toPlaceId != null) {
      key = _generatePlaceIdKey(fromPlaceId, toPlaceId, mode);
    } else if (fromText != null && toText != null) {
      key = _generateTextKey(fromText, toText, mode);
    }

    if (key == null) return null;

    final cached = _cache[key];
    if (cached == null || cached.isStale) {
      if (cached != null) {
        _cache.remove(key);
        _persistCache();
      }
      return null;
    }

    return cached;
  }

  /// Save a route to cache (positional args for backward compatibility with tests)
  Future<void> saveRoute(
      {required String from, required String to, required int minutes}) async {
    await _saveRouteInternal(
      fromText: from,
      toText: to,
      minutes: minutes,
    );
  }

  /// Save a route to cache (named args for new code)
  Future<void> saveRouteNamed({
    String? fromPlaceId,
    String? toPlaceId,
    String? fromText,
    String? toText,
    required int minutes,
    double? distanceKm,
    String mode = 'driving',
  }) async {
    await _saveRouteInternal(
      fromPlaceId: fromPlaceId,
      toPlaceId: toPlaceId,
      fromText: fromText,
      toText: toText,
      minutes: minutes,
      distanceKm: distanceKm,
      mode: mode,
    );
  }

  /// Internal method to save route (used by both positional and named versions)
  /// Implements reverse caching: saves both A->B and B->A with same minutes
  Future<void> _saveRouteInternal({
    String? fromPlaceId,
    String? toPlaceId,
    String? fromText,
    String? toText,
    required int minutes,
    double? distanceKm,
    String mode = 'driving',
  }) async {
    if (!_initialized) await init();

    final route = CachedRoute(
      minutes: minutes,
      distanceKm: distanceKm,
      cachedAt: DateTime.now(),
    );

    // Save with placeId key if available (both directions)
    if (fromPlaceId != null && toPlaceId != null) {
      final keyForward = _generatePlaceIdKey(fromPlaceId, toPlaceId, mode);
      _cache[keyForward] = route;
      // Save reverse route
      final keyReverse = _generatePlaceIdKey(toPlaceId, fromPlaceId, mode);
      _cache[keyReverse] = route;
    }

    // Also save with text key for fallback (both directions)
    if (fromText != null && toText != null) {
      // Normalize keys (trim + lowercase) for stable lookups
      final normalizedFrom = fromText.trim().toLowerCase();
      final normalizedTo = toText.trim().toLowerCase();

      final keyForward = _generateTextKey(normalizedFrom, normalizedTo, mode);
      _cache[keyForward] = route;
      // Save reverse route
      final keyReverse = _generateTextKey(normalizedTo, normalizedFrom, mode);
      _cache[keyReverse] = route;
    }

    await _persistCache();
  }

  Future<void> _persistCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = _cache.map((key, route) => MapEntry(key, route.toJson()));
    await prefs.setString(_storageKey, jsonEncode(jsonMap));
  }

  String _generatePlaceIdKey(
      String fromPlaceId, String toPlaceId, String mode) {
    return '$fromPlaceId|$toPlaceId|$mode';
  }

  String _generateTextKey(String fromText, String toText, String mode) {
    return '${fromText.trim().toLowerCase()}|${toText.trim().toLowerCase()}|$mode';
  }

  /// Get minutes for a route (checks both directions)
  /// Normalizes input (trim + lowercase) for stable lookups
  int? getMinutes(String from, String to) {
    final normalizedFrom = from.trim().toLowerCase();
    final normalizedTo = to.trim().toLowerCase();

    var cached = getCachedRoute(fromText: normalizedFrom, toText: normalizedTo);
    // Try reverse direction (should be cached if reverse caching is working)
    cached ??= getCachedRoute(fromText: normalizedTo, toText: normalizedFrom);
    return cached?.minutes;
  }

  /// Legacy method for backward compatibility
  int? getRouteDuration(String from, String to) {
    return getMinutes(from, to);
  }

  /// Legacy method for backward compatibility
  Future<void> saveRouteLegacy(String from, String to, int minutes) async {
    await saveRoute(from: from, to: to, minutes: minutes);
  }
}
