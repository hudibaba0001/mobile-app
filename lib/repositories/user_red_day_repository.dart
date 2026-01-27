// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_red_day.dart';

/// Repository for user-defined red days
/// 
/// Handles CRUD operations for the `user_red_days` table in Supabase
class UserRedDayRepository {
  final SupabaseClient _supabase;
  static const String _tableName = 'user_red_days';

  UserRedDayRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Get all red days for a user within a date range
  Future<List<UserRedDay>> getForDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .gte('date', startStr)
          .lte('date', endStr)
          .order('date');

      return (response as List)
          .map((json) => UserRedDay.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('UserRedDayRepository: Error fetching red days: $e');
      rethrow;
    }
  }

  /// Get all red days for a specific month
  Future<List<UserRedDay>> getForMonth({
    required String userId,
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // Last day of month
    return getForDateRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get all red days for a specific year
  Future<List<UserRedDay>> getForYear({
    required String userId,
    required int year,
  }) async {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31);
    return getForDateRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get red day for a specific date (if exists)
  Future<UserRedDay?> getForDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('date', dateStr)
          .maybeSingle();

      if (response == null) return null;
      return UserRedDay.fromJson(response);
    } catch (e) {
      debugPrint('UserRedDayRepository: Error fetching red day: $e');
      return null;
    }
  }

  /// Upsert a red day (insert or update based on user_id + date)
  Future<UserRedDay> upsert(UserRedDay redDay) async {
    try {
      final data = redDay.toJson();
      
      final response = await _supabase
          .from(_tableName)
          .upsert(data, onConflict: 'user_id,date')
          .select()
          .single();

      debugPrint('UserRedDayRepository: ✅ Upserted red day for ${redDay.date}');
      return UserRedDay.fromJson(response);
    } catch (e) {
      debugPrint('UserRedDayRepository: ❌ Error upserting red day: $e');
      rethrow;
    }
  }

  /// Delete a red day by ID
  Future<void> delete(String id, String userId) async {
    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      debugPrint('UserRedDayRepository: ✅ Deleted red day $id');
    } catch (e) {
      debugPrint('UserRedDayRepository: ❌ Error deleting red day: $e');
      rethrow;
    }
  }

  /// Delete red day for a specific date
  Future<void> deleteForDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      await _supabase
          .from(_tableName)
          .delete()
          .eq('user_id', userId)
          .eq('date', dateStr);

      debugPrint('UserRedDayRepository: ✅ Deleted red day for $date');
    } catch (e) {
      debugPrint('UserRedDayRepository: ❌ Error deleting red day: $e');
      rethrow;
    }
  }
}
