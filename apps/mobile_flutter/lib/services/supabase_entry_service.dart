// ignore_for_file: avoid_print
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/entry.dart';
import '../config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Service for managing entries in Supabase
/// This is the PRIMARY storage - all data is synced to Supabase first
/// Works with normalized database structure: entries, travel_segments, work_shifts
class SupabaseEntryService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  static const String _tableName = 'entries';
  static const String _travelSegmentsTable = 'travel_segments';
  static const String _workShiftsTable = 'work_shifts';
  static const _uuid = Uuid();

  /// Get all entries for a user from Supabase (with pagination)
  /// Uses batch queries instead of N+1 pattern for performance
  /// [limit] Number of entries per page (default 100, use null for all)
  /// [offset] Number of entries to skip (for pagination)
  Future<List<Entry>> getAllEntries(String userId, {int? limit, int offset = 0}) async {
    try {
      debugPrint('SupabaseEntryService: Fetching entries for user: $userId (limit: $limit, offset: $offset)');

      // Step 1: Fetch entries (with optional pagination)
      var query = _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      // Apply pagination if limit is specified
      if (limit != null) {
        query = query.range(offset, offset + limit - 1);
      }

      final entriesResponse = await query;

      debugPrint('SupabaseEntryService: Found ${entriesResponse.length} entries');

      if (entriesResponse.isEmpty) {
        debugPrint('SupabaseEntryService: No entries found in Supabase for user: $userId');
        return [];
      }

      // Step 2: Collect entry IDs by type for batch queries
      final travelEntryIds = entriesResponse
          .where((e) => e['type'] == 'travel')
          .map((e) => e['id'] as String)
          .toList();
      final workEntryIds = entriesResponse
          .where((e) => e['type'] == 'work')
          .map((e) => e['id'] as String)
          .toList();

      // Step 3: Batch fetch ALL related data in just 2 queries (instead of N queries)
      Map<String, List<Map<String, dynamic>>> segmentsByEntryId = {};
      Map<String, List<Map<String, dynamic>>> shiftsByEntryId = {};

      if (travelEntryIds.isNotEmpty) {
        final segmentsResponse = await _supabase
            .from(_travelSegmentsTable)
            .select()
            .inFilter('entry_id', travelEntryIds)
            .order('segment_order', ascending: true);

        // Group segments by entry_id
        for (final segment in segmentsResponse) {
          final entryId = segment['entry_id'] as String;
          segmentsByEntryId.putIfAbsent(entryId, () => []).add(segment);
        }
        debugPrint('SupabaseEntryService: Batch loaded ${segmentsResponse.length} travel segments');
      }

      if (workEntryIds.isNotEmpty) {
        final shiftsResponse = await _supabase
            .from(_workShiftsTable)
            .select()
            .inFilter('entry_id', workEntryIds)
            .order('start_time', ascending: true);

        // Group shifts by entry_id
        for (final shift in shiftsResponse) {
          final entryId = shift['entry_id'] as String;
          shiftsByEntryId.putIfAbsent(entryId, () => []).add(shift);
        }
        debugPrint('SupabaseEntryService: Batch loaded ${shiftsResponse.length} work shifts');
      }

      // Step 4: Merge data in memory (no more N+1 queries!)
      final List<Entry> entries = [];

      for (final entryRow in entriesResponse) {
        try {
          final entryId = entryRow['id'] as String;
          final entryType = entryRow['type'] as String;

          if (entryType == 'travel') {
            final segments = segmentsByEntryId[entryId];
            if (segments != null && segments.isNotEmpty) {
              final segment = segments.first;
              entryRow['from_location'] = segment['from_location'];
              entryRow['to_location'] = segment['to_location'];
              entryRow['travel_minutes'] = segment['travel_minutes'];
              entryRow['journey_id'] = segment['id'];
              entryRow['segment_order'] = segment['segment_order'];
              entryRow['total_segments'] = segment['total_segments'];
            }
          } else if (entryType == 'work') {
            final shifts = shiftsByEntryId[entryId];
            if (shifts != null && shifts.isNotEmpty) {
              entryRow['shifts'] = shifts.map((shift) => _mapShiftFromDb(shift)).toList();
            }
          }

          entries.add(Entry.fromJson(entryRow));
        } catch (e) {
          debugPrint('SupabaseEntryService: Error parsing entry from Supabase: $e');
          debugPrint('SupabaseEntryService: Entry data: $entryRow');
        }
      }

      debugPrint('SupabaseEntryService: Successfully loaded ${entries.length} entries (3 queries total)');
      return entries;
    } catch (e) {
      debugPrint('SupabaseEntryService: Error fetching entries from Supabase: $e');
      debugPrint('SupabaseEntryService: Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Helper to map DB shift row to Shift.fromJson format
  Map<String, dynamic> _mapShiftFromDb(Map<String, dynamic> shift) {
    final dbNotes = shift['notes'] as String?;
    final startUtc = DateTime.parse(shift['start_time'] as String);
    final endUtc = DateTime.parse(shift['end_time'] as String);
    final startLocal = startUtc.toLocal();
    final endLocal = endUtc.toLocal();

    return {
      'start': startLocal.toIso8601String(),
      'end': endLocal.toIso8601String(),
      'location': shift['location'],
      'unpaid_break_minutes': shift['unpaid_break_minutes'] ?? 0,
      'notes': dbNotes,
      'description': dbNotes,
    };
  }

  /// Get total entry count for pagination
  Future<int> getEntryCount(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('id')
          .eq('user_id', userId);
      return response.length;
    } catch (e) {
      debugPrint('SupabaseEntryService: Error getting entry count: $e');
      return 0;
    }
  }

  /// Get entries for a user within a date range
  /// Uses batch queries for performance (3 queries instead of N+1)
  Future<List<Entry>> getEntriesInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      // Format dates as YYYY-MM-DD for date type column
      final startDateStr = start.toIso8601String().split('T')[0];
      final endDateStr = end.toIso8601String().split('T')[0];

      // Step 1: Fetch all entries in range
      final entriesResponse = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .gte('date', startDateStr)
          .lte('date', endDateStr)
          .order('date', ascending: false);

      if (entriesResponse.isEmpty) {
        return [];
      }

      // Step 2: Collect entry IDs by type for batch queries
      final travelEntryIds = entriesResponse
          .where((e) => e['type'] == 'travel')
          .map((e) => e['id'] as String)
          .toList();
      final workEntryIds = entriesResponse
          .where((e) => e['type'] == 'work')
          .map((e) => e['id'] as String)
          .toList();

      // Step 3: Batch fetch related data
      Map<String, List<Map<String, dynamic>>> segmentsByEntryId = {};
      Map<String, List<Map<String, dynamic>>> shiftsByEntryId = {};

      if (travelEntryIds.isNotEmpty) {
        final segmentsResponse = await _supabase
            .from(_travelSegmentsTable)
            .select()
            .inFilter('entry_id', travelEntryIds)
            .order('segment_order', ascending: true);

        for (final segment in segmentsResponse) {
          final entryId = segment['entry_id'] as String;
          segmentsByEntryId.putIfAbsent(entryId, () => []).add(segment);
        }
      }

      if (workEntryIds.isNotEmpty) {
        final shiftsResponse = await _supabase
            .from(_workShiftsTable)
            .select()
            .inFilter('entry_id', workEntryIds)
            .order('start_time', ascending: true);

        for (final shift in shiftsResponse) {
          final entryId = shift['entry_id'] as String;
          shiftsByEntryId.putIfAbsent(entryId, () => []).add(shift);
        }
      }

      // Step 4: Merge in memory
      final List<Entry> entries = [];
      for (final entryRow in entriesResponse) {
        try {
          final entryId = entryRow['id'] as String;
          final entryType = entryRow['type'] as String;

          if (entryType == 'travel') {
            final segments = segmentsByEntryId[entryId];
            if (segments != null && segments.isNotEmpty) {
              final segment = segments.first;
              entryRow['from_location'] = segment['from_location'];
              entryRow['to_location'] = segment['to_location'];
              entryRow['travel_minutes'] = segment['travel_minutes'];
              entryRow['journey_id'] = segment['id'];
              entryRow['segment_order'] = segment['segment_order'];
              entryRow['total_segments'] = segment['total_segments'];
            }
          } else if (entryType == 'work') {
            final shifts = shiftsByEntryId[entryId];
            if (shifts != null && shifts.isNotEmpty) {
              entryRow['shifts'] = shifts.map((shift) => _mapShiftFromDb(shift)).toList();
            }
          }

          entries.add(Entry.fromJson(entryRow));
        } catch (e) {
          debugPrint('Error parsing entry from Supabase: $e');
        }
      }

      return entries;
    } catch (e) {
      debugPrint('Error fetching entries in range from Supabase: $e');
      rethrow;
    }
  }

  /// Test Supabase connection and table structure
  Future<bool> testConnection() async {
    try {
      // Try a simple query to test connection and table structure
      await _supabase.from(_tableName).select('id').limit(1);
      debugPrint('SupabaseEntryService: ✅ Connection test successful');
      return true;
    } catch (e) {
      debugPrint('SupabaseEntryService: ❌ Connection test failed: $e');
      return false;
    }
  }

  /// Add a new entry to Supabase
  /// Inserts into entries table and related travel_segments or work_shifts tables
  Future<Entry> addEntry(Entry entry) async {
    try {
      // Ensure entry ID is a valid UUID format
      String entryId = entry.id;
      if (!_isValidUUID(entryId)) {
        debugPrint('SupabaseEntryService: ⚠️ Entry ID is not a UUID, generating new UUID');
        entryId = _uuid.v4();
        // Create a new entry with the UUID
        entry = entry.copyWith(id: entryId);
      }

      // Prepare base entry data (without type-specific fields)
      final entryData = {
        'id': entryId,
        'user_id': entry.userId,
        'type': entry.type.toString().split('.').last,
        'date': entry.date.toIso8601String().split('T')[0], // Date only, not timestamp
        'notes': entry.notes,
        'created_at': entry.createdAt.toIso8601String(),
        'updated_at': entry.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };

      debugPrint('SupabaseEntryService: Inserting entry with ID: $entryId');
      debugPrint('SupabaseEntryService: Entry data: $entryData');
      
      // Insert into entries table
      final entryResponse = await _supabase
          .from(_tableName)
          .insert(entryData)
          .select()
          .single();

      debugPrint('SupabaseEntryService: ✅ Entry inserted into entries table');

      // Insert type-specific data
      if (entry.type == EntryType.travel && entry.from != null && entry.to != null) {
        final segmentData = {
          'id': _uuid.v4(), // Generate new ID for segment
          'entry_id': entryId,
          'from_location': entry.from,
          'to_location': entry.to,
          'travel_minutes': entry.travelMinutes ?? 0,
          'segment_order': entry.segmentOrder ?? 1,
          'total_segments': entry.totalSegments ?? 1,
          'created_at': entry.createdAt.toIso8601String(),
          'updated_at': entry.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        };

        await _supabase
            .from(_travelSegmentsTable)
            .insert(segmentData);
        
        debugPrint('SupabaseEntryService: ✅ Travel segment inserted');
        
        // Add travel data to response for Entry.fromJson
        entryResponse['from_location'] = entry.from;
        entryResponse['to_location'] = entry.to;
        entryResponse['travel_minutes'] = entry.travelMinutes;
        entryResponse['journey_id'] = segmentData['id'];
        entryResponse['segment_order'] = entry.segmentOrder;
        entryResponse['total_segments'] = entry.totalSegments;
      } else if (entry.type == EntryType.work && entry.shifts != null && entry.shifts!.isNotEmpty) {
        // Insert work shifts
        // Map Shift model to DB columns: start_time, end_time, location, unpaid_break_minutes, notes
        // DO NOT write 'description' column (doesn't exist in DB schema)
        final shiftsData = entry.shifts!.map((shift) {
          // Use notes if available, otherwise fall back to description for backward compatibility
          final dbNotes = shift.notes ?? shift.description;
          
          // Convert local DateTime to UTC before storing in DB
          // Shift start/end are in local time (constructed from entry.date + TimeOfDay)
          final startLocal = shift.start.isUtc 
              ? shift.start.toLocal() 
              : shift.start; // Already local
          final endLocal = shift.end.isUtc 
              ? shift.end.toLocal() 
              : shift.end; // Already local
          
          final startUtc = startLocal.toUtc();
          final endUtc = endLocal.toUtc();
          
          debugPrint('SupabaseEntryService: Shift timezone conversion - '
              'start local: ${startLocal.toIso8601String()}, UTC: ${startUtc.toIso8601String()}, '
              'break: ${shift.unpaidBreakMinutes}, notes: $dbNotes');
          
          return {
            'id': _uuid.v4(),
            'entry_id': entryId,
            'start_time': startUtc.toIso8601String(), // Store as UTC
            'end_time': endUtc.toIso8601String(), // Store as UTC
            'location': shift.location,
            'unpaid_break_minutes': shift.unpaidBreakMinutes,
            'notes': dbNotes,
            'created_at': entry.createdAt.toIso8601String(),
            'updated_at': entry.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
          };
        }).toList();

        await _supabase
            .from(_workShiftsTable)
            .insert(shiftsData);
        
        debugPrint('SupabaseEntryService: ✅ ${shiftsData.length} work shift(s) inserted');
        
        // Add shifts data to response for Entry.fromJson
        entryResponse['shifts'] = entry.shifts!.map((s) {
          final dbNotes = s.notes ?? s.description;
          return {
            'start': s.start.toIso8601String(),
            'end': s.end.toIso8601String(),
            'location': s.location,
            'unpaid_break_minutes': s.unpaidBreakMinutes,
            'notes': dbNotes,
            // For backward compatibility with Shift.fromJson
            'description': dbNotes,
          };
        }).toList();
      }

      debugPrint('SupabaseEntryService: ✅ Entry inserted successfully: ${entryResponse['id']}');
      
      // Parse the response and ensure it uses the correct entry ID
      final updatedEntry = Entry.fromJson(entryResponse);
      // If we generated a new UUID, make sure the returned entry uses it
      if (entryId != entry.id) {
        return updatedEntry.copyWith(id: entryId);
      }
      return updatedEntry;
    } catch (e) {
      debugPrint('SupabaseEntryService: ❌ Error adding entry to Supabase: $e');
      debugPrint('SupabaseEntryService: Entry data that failed: ${entry.toJson()}');
      debugPrint('SupabaseEntryService: Error type: ${e.runtimeType}');
      debugPrint('SupabaseEntryService: Error details: ${e.toString()}');
      
      // Provide more specific error messages
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('column') || errorStr.contains('pgrst')) {
        debugPrint('SupabaseEntryService: ⚠️ Column/schema issue detected');
        debugPrint('SupabaseEntryService: Make sure you have run the correct schema SQL for your database structure');
      } else if (errorStr.contains('uuid') || errorStr.contains('invalid input')) {
        debugPrint('SupabaseEntryService: ⚠️ UUID format issue - entry ID: ${entry.id}');
      } else if (errorStr.contains('foreign key') || errorStr.contains('constraint')) {
        debugPrint('SupabaseEntryService: ⚠️ Foreign key or constraint violation');
      } else if (errorStr.contains('permission') || errorStr.contains('policy')) {
        debugPrint('SupabaseEntryService: ⚠️ RLS policy issue - check your Supabase RLS policies');
      }
      
      rethrow;
    }
  }

  /// Check if a string is a valid UUID format
  bool _isValidUUID(String? id) {
    if (id == null || id.isEmpty) return false;
    // UUID format: 8-4-4-4-12 hex characters
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    return uuidRegex.hasMatch(id);
  }

  /// Update an existing entry in Supabase
  Future<Entry> updateEntry(Entry entry) async {
    try {
      // Update base entry
      final entryData = {
        'type': entry.type.toString().split('.').last,
        'date': entry.date.toIso8601String().split('T')[0], // Date only
        'notes': entry.notes,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from(_tableName)
          .update(entryData)
          .eq('id', entry.id)
          .eq('user_id', entry.userId);

      // Update type-specific data
      if (entry.type == EntryType.travel) {
        // Delete existing segments and insert new ones
        await _supabase
            .from(_travelSegmentsTable)
            .delete()
            .eq('entry_id', entry.id);

        if (entry.from != null && entry.to != null) {
          final segmentData = {
            'id': _uuid.v4(),
            'entry_id': entry.id,
            'from_location': entry.from,
            'to_location': entry.to,
            'travel_minutes': entry.travelMinutes ?? 0,
            'segment_order': entry.segmentOrder ?? 1,
            'total_segments': entry.totalSegments ?? 1,
            'created_at': entry.createdAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };

          await _supabase
              .from(_travelSegmentsTable)
              .insert(segmentData);
        }
      } else if (entry.type == EntryType.work) {
        // Delete existing shifts and insert new ones
        await _supabase
            .from(_workShiftsTable)
            .delete()
            .eq('entry_id', entry.id);

        if (entry.shifts != null && entry.shifts!.isNotEmpty) {
          // Map Shift model to DB columns (no description column)
          final shiftsData = entry.shifts!.map((shift) {
            final dbNotes = shift.notes ?? shift.description;
            
            // Convert local DateTime to UTC before storing in DB
            final startLocal = shift.start.isUtc ? shift.start.toLocal() : shift.start;
            final endLocal = shift.end.isUtc ? shift.end.toLocal() : shift.end;
            final startUtc = startLocal.toUtc();
            final endUtc = endLocal.toUtc();
            
            debugPrint('SupabaseEntryService: Update shift timezone conversion - '
                'start local: ${startLocal.toIso8601String()}, UTC: ${startUtc.toIso8601String()}, '
                'break: ${shift.unpaidBreakMinutes}, notes: $dbNotes');
            
            return {
              'id': _uuid.v4(),
              'entry_id': entry.id,
              'start_time': startUtc.toIso8601String(), // Store as UTC
              'end_time': endUtc.toIso8601String(), // Store as UTC
              'location': shift.location,
              'unpaid_break_minutes': shift.unpaidBreakMinutes,
              'notes': dbNotes,
              'created_at': entry.createdAt.toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            };
          }).toList();

          await _supabase
              .from(_workShiftsTable)
              .insert(shiftsData);
        }
      }

      // Reload the entry with all related data
      return await getEntryById(entry.id, entry.userId) ?? entry;
    } catch (e) {
      debugPrint('Error updating entry in Supabase: $e');
      debugPrint('Entry data: ${entry.toJson()}');
      rethrow;
    }
  }

  /// Delete an entry from Supabase
  /// Also deletes related travel_segments or work_shifts (CASCADE should handle this, but we do it explicitly)
  Future<void> deleteEntry(String entryId, String userId) async {
    try {
      // Delete related data first (in case CASCADE isn't set up)
      await _supabase
          .from(_travelSegmentsTable)
          .delete()
          .eq('entry_id', entryId);
      
      await _supabase
          .from(_workShiftsTable)
          .delete()
          .eq('entry_id', entryId);

      // Delete the entry
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', entryId)
          .eq('user_id', userId);
      
      debugPrint('SupabaseEntryService: ✅ Deleted entry $entryId and related data');
    } catch (e) {
      debugPrint('SupabaseEntryService: ❌ Error deleting entry from Supabase: $e');
      rethrow;
    }
  }

  /// Get a single entry by ID with related data
  Future<Entry?> getEntryById(String entryId, String userId) async {
    try {
      final entryResponse = await _supabase
          .from(_tableName)
          .select()
          .eq('id', entryId)
          .eq('user_id', userId)
          .maybeSingle();

      if (entryResponse == null) {
        return null;
      }

      final entryType = entryResponse['type'] as String;

      // Fetch related data (single entry, so N+1 is acceptable here)
      if (entryType == 'travel') {
        final segmentsResponse = await _supabase
            .from(_travelSegmentsTable)
            .select()
            .eq('entry_id', entryId)
            .order('segment_order', ascending: true);

        if (segmentsResponse.isNotEmpty) {
          final segment = segmentsResponse.first;
          entryResponse['from_location'] = segment['from_location'];
          entryResponse['to_location'] = segment['to_location'];
          entryResponse['travel_minutes'] = segment['travel_minutes'];
          entryResponse['journey_id'] = segment['id'];
          entryResponse['segment_order'] = segment['segment_order'];
          entryResponse['total_segments'] = segment['total_segments'];
        }
      } else if (entryType == 'work') {
        final shiftsResponse = await _supabase
            .from(_workShiftsTable)
            .select()
            .eq('entry_id', entryId)
            .order('start_time', ascending: true);

        if (shiftsResponse.isNotEmpty) {
          entryResponse['shifts'] = shiftsResponse.map((shift) => _mapShiftFromDb(shift)).toList();
        }
      }

      return Entry.fromJson(entryResponse);
    } catch (e) {
      debugPrint('Error fetching entry by ID from Supabase: $e');
      return null;
    }
  }

  /// Sync all entries for a user (useful for initial load)
  Future<List<Entry>> syncEntries(String userId) async {
    return await getAllEntries(userId);
  }

  /// Batch insert entries (useful for migration)
  /// Uses addEntry for each entry to ensure related data is also inserted
  Future<List<Entry>> batchInsertEntries(List<Entry> entries) async {
    if (entries.isEmpty) return [];

    final List<Entry> insertedEntries = [];
    
    for (final entry in entries) {
      try {
        final inserted = await addEntry(entry);
        insertedEntries.add(inserted);
      } catch (e) {
        debugPrint('Error batch inserting entry ${entry.id}: $e');
        // Continue with other entries
      }
    }

    return insertedEntries;
  }
}

