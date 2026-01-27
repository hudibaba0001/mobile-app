import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/work_entry.dart';

class WorkRepository {
  final Box<WorkEntry> _box;
  final _uuid = const Uuid();

  WorkRepository(this._box);

  /// Get all work entries for a user
  List<WorkEntry> getAllForUser(String userId) {
    return _box.values
        .where((entry) => entry.userId == userId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get work entries for a user within a date range
  List<WorkEntry> getForUserInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    throw StateError(
        'LEGACY_READ_BLOCKED: use EntryProvider.entries (Entry) instead of WorkRepository');
  }

  /// Add a new work entry
  /// 
  /// ⚠️ LEGACY WRITE PATH DISABLED: Use EntryProvider.addEntry() instead.
  /// This method will throw in debug mode to prevent data loss from missing break/notes/timezone.
  Future<WorkEntry> add(WorkEntry entry) async {
    throw StateError(
        'LEGACY_WRITE_BLOCKED: use EntryProvider.addEntry/addEntries (Entry)');
  }

  /// Get an entry by ID
  WorkEntry? getById(String id) {
    throw StateError(
        'LEGACY_READ_BLOCKED: use EntryProvider.entries (Entry) instead of WorkRepository');
  }

  /// Update an existing work entry
  Future<WorkEntry> update(WorkEntry entry) async {
    throw StateError(
        'LEGACY_WRITE_BLOCKED: use EntryProvider.updateEntry (Entry)');
  }

  /// Delete a work entry
  /// 
  /// ⚠️ LEGACY WRITE PATH DISABLED: Use EntryProvider.deleteEntry() instead.
  /// This method will throw in debug mode to prevent data loss from missing break/notes/timezone.
  Future<void> delete(String id) async {
    throw StateError(
        'LEGACY_WRITE_BLOCKED: use EntryProvider.deleteEntry (Entry)');
  }

  /// Get total work minutes for a user within a date range
  int getTotalMinutesInRange(String userId, DateTime start, DateTime end) {
    throw StateError(
        'LEGACY_READ_BLOCKED: use EntryProvider.entries (Entry)');
  }

  /// Close the Hive box
  Future<void> close() async {
    await _box.close();
  }
}
