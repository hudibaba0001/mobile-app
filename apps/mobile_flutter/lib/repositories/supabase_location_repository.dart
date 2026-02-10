// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location.dart';

/// Repository for syncing locations to Supabase
class SupabaseLocationRepository {
  final SupabaseClient _supabase;
  static const String _tableName = 'locations';

  SupabaseLocationRepository(this._supabase);

  /// Get all locations for a user
  Future<List<Location>> getAllLocations(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((row) {
        final map = row as Map<String, dynamic>;
        return Location(
          id: map['id'] as String,
          name: map['name'] as String,
          address: (map['address'] as String?) ?? '',
          createdAt: DateTime.parse(map['created_at'] as String),
          usageCount: (map['usage_count'] as int?) ?? 0,
          isFavorite: (map['is_favorite'] as bool?) ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint('SupabaseLocationRepository: Error fetching locations: $e');
      rethrow;
    }
  }

  /// Upsert a location (insert or update)
  Future<void> upsertLocation(String userId, Location location) async {
    try {
      await _supabase.from(_tableName).upsert({
        'id': location.id,
        'user_id': userId,
        'name': location.name,
        'address': location.address,
        'usage_count': location.usageCount,
        'is_favorite': location.isFavorite,
        'created_at': location.createdAt.toIso8601String(),
      }, onConflict: 'id');

      debugPrint('SupabaseLocationRepository: Upserted location ${location.id}');
    } catch (e) {
      debugPrint('SupabaseLocationRepository: Error upserting location: $e');
    }
  }

  /// Delete a location
  Future<void> deleteLocation(String userId, String locationId) async {
    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', locationId)
          .eq('user_id', userId);

      debugPrint('SupabaseLocationRepository: Deleted location $locationId');
    } catch (e) {
      debugPrint('SupabaseLocationRepository: Error deleting location: $e');
    }
  }

  /// Sync all local locations to Supabase (bulk upsert)
  Future<void> syncAllLocations(String userId, List<Location> locations) async {
    try {
      if (locations.isEmpty) return;

      final rows = locations.map((loc) => {
        'id': loc.id,
        'user_id': userId,
        'name': loc.name,
        'address': loc.address,
        'usage_count': loc.usageCount,
        'is_favorite': loc.isFavorite,
        'created_at': loc.createdAt.toIso8601String(),
      }).toList();

      await _supabase.from(_tableName).upsert(rows, onConflict: 'id');

      debugPrint('SupabaseLocationRepository: Synced ${locations.length} locations');
    } catch (e) {
      debugPrint('SupabaseLocationRepository: Error syncing locations: $e');
    }
  }
}
