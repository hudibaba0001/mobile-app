import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TravelCacheService {
  static const String _storageKey = 'travel_route_cache';
  
  // Cache structure: "From|To" -> minutes (int)
  Map<String, int> _cache = {};
  bool _initialized = false;

  /// Initialize the cache from SharedPreferences
  Future<void> init() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    
    if (jsonString != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        _cache = decoded.map((key, value) => MapEntry(key, value as int));
      } catch (e) {
        print('Error parsing travel cache: $e');
      }
    }
    
    _initialized = true;
  }

  /// Get cached minutes for a route
  /// Returns null if route is not found
  int? getRouteDuration(String from, String to) {
    if (!_initialized) return null;
    
    final key = _generateKey(from, to);
    return _cache[key];
  }

  /// Save a route duration to cache
  Future<void> saveRoute(String from, String to, int minutes) async {
    if (!_initialized) await init();
    
    final key = _generateKey(from, to);
    _cache[key] = minutes;
    
    // Persist to disk
    await _persistCache();
    
    // Also save the reverse route? Users requested "Swap Route" so reverse might be valid too.
    // But duration might differ slightly (traffic), generally safe to assume similar for caching.
    // Let's explicitly save reverse route too for better UX.
    final reverseKey = _generateKey(to, from);
    _cache[reverseKey] = minutes;
    await _persistCache();
  }

  Future<void> _persistCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_cache));
  }

  String _generateKey(String from, String to) {
    return '${from.trim().toLowerCase()}|${to.trim().toLowerCase()}';
  }
}
