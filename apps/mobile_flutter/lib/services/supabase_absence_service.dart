// ignore_for_file: avoid_print
import '../models/absence.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Service for managing absence entries in Supabase
class SupabaseAbsenceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const _uuid = Uuid();

  /// Fetch all absences for a user and year
  ///
  /// Returns list of AbsenceEntry objects
  Future<List<AbsenceEntry>> fetchAbsencesForYear(
      String userId, int year) async {
    try {
      final startDate = '$year-01-01';
      final endDate = '$year-12-31';

      final response = await _supabase
          .from('absences')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate)
          .lte('date', endDate)
          .order('date', ascending: true);

      final List<AbsenceEntry> absences = [];
      for (final row in response) {
        try {
          absences.add(AbsenceEntry.fromMap(row));
        } catch (e) {
          debugPrint('SupabaseAbsenceService: Error parsing absence: $e');
          debugPrint('SupabaseAbsenceService: Row data skipped (PII)');
        }
      }

      return absences;
    } catch (e) {
      throw Exception('Failed to fetch absences: $e');
    }
  }

  /// Add an absence entry
  Future<String> addAbsence(String userId, AbsenceEntry absence) async {
    try {
      final data = absence.toMap();
      data['user_id'] = userId;
      data['id'] = _uuid.v4(); // Generate UUID

      final response =
          await _supabase.from('absences').insert(data).select().single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to add absence: $e');
    }
  }

  /// Update an absence entry
  Future<void> updateAbsence(
      String userId, String absenceId, AbsenceEntry absence) async {
    try {
      final data = absence.toMap();

      await _supabase
          .from('absences')
          .update(data)
          .eq('id', absenceId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update absence: $e');
    }
  }

  /// Delete an absence entry
  Future<void> deleteAbsence(String userId, String absenceId) async {
    try {
      await _supabase
          .from('absences')
          .delete()
          .eq('id', absenceId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete absence: $e');
    }
  }
}
