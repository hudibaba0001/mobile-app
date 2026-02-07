// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/balance_adjustment.dart';

/// Repository for managing balance adjustments in Supabase
class BalanceAdjustmentRepository {
  final SupabaseClient _supabase;
  static const String _tableName = 'balance_adjustments';

  BalanceAdjustmentRepository(this._supabase);

  /// List adjustments for a date range (inclusive)
  Future<List<BalanceAdjustment>> listAdjustmentsRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startStr = '${startDate.year}-'
          '${startDate.month.toString().padLeft(2, '0')}-'
          '${startDate.day.toString().padLeft(2, '0')}';
      final endStr = '${endDate.year}-'
          '${endDate.month.toString().padLeft(2, '0')}-'
          '${endDate.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .gte('effective_date', startStr)
          .lte('effective_date', endStr)
          .order('effective_date', ascending: true);

      return (response as List)
          .map((row) => BalanceAdjustment.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('BalanceAdjustmentRepository: Error listing adjustments: $e');
      rethrow;
    }
  }

  /// List adjustments for a specific year
  Future<List<BalanceAdjustment>> listAdjustmentsForYear({
    required String userId,
    required int year,
  }) async {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31);
    return listAdjustmentsRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get all adjustments for a user (all time)
  Future<List<BalanceAdjustment>> listAllAdjustments({
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('effective_date', ascending: false);

      return (response as List)
          .map((row) => BalanceAdjustment.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint(
          'BalanceAdjustmentRepository: Error listing all adjustments: $e');
      rethrow;
    }
  }

  /// Create a new adjustment
  Future<BalanceAdjustment> createAdjustment({
    required String userId,
    required DateTime effectiveDate,
    required int deltaMinutes,
    String? note,
  }) async {
    try {
      final adjustment = BalanceAdjustment(
        userId: userId,
        effectiveDate: effectiveDate,
        deltaMinutes: deltaMinutes,
        note: note,
      );

      final response = await _supabase
          .from(_tableName)
          .insert(adjustment.toMap())
          .select()
          .single();

      debugPrint(
          'BalanceAdjustmentRepository: Created adjustment: ${adjustment.deltaFormatted}');
      return BalanceAdjustment.fromMap(response);
    } catch (e) {
      debugPrint('BalanceAdjustmentRepository: Error creating adjustment: $e');
      rethrow;
    }
  }

  /// Update an existing adjustment
  Future<BalanceAdjustment> updateAdjustment({
    required String id,
    required String userId,
    required DateTime effectiveDate,
    required int deltaMinutes,
    String? note,
  }) async {
    try {
      final dateStr = '${effectiveDate.year}-'
          '${effectiveDate.month.toString().padLeft(2, '0')}-'
          '${effectiveDate.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from(_tableName)
          .update({
            'effective_date': dateStr,
            'delta_minutes': deltaMinutes,
            'note': note,
          })
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      debugPrint('BalanceAdjustmentRepository: Updated adjustment: $id');
      return BalanceAdjustment.fromMap(response);
    } catch (e) {
      debugPrint('BalanceAdjustmentRepository: Error updating adjustment: $e');
      rethrow;
    }
  }

  /// Delete an adjustment
  Future<void> deleteAdjustment({
    required String id,
    required String userId,
  }) async {
    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      debugPrint('BalanceAdjustmentRepository: Deleted adjustment: $id');
    } catch (e) {
      debugPrint('BalanceAdjustmentRepository: Error deleting adjustment: $e');
      rethrow;
    }
  }
}
