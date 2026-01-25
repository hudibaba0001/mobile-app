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
    return _box.values
        .where((entry) =>
            entry.userId == userId &&
            entry.date.isAfter(start.subtract(const Duration(days: 1))) &&
            entry.date.isBefore(end.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Add a new work entry
  /// 
  /// ⚠️ LEGACY WRITE PATH DISABLED: Use EntryProvider.addEntry() instead.
  /// This method will throw in debug mode to prevent data loss from missing break/notes/timezone.
  Future<WorkEntry> add(WorkEntry entry) async {
    assert(() {
      throw StateError(
        'Legacy WorkEntry write path is disabled. Use EntryProvider.addEntry() instead. '
        'This prevents missing break/notes and timezone issues.'
      );
    }());
    final assignedId = (entry.id.isEmpty) ? _uuid.v4() : entry.id;
    final newEntry = entry.copyWith(id: assignedId);
    await _box.put(newEntry.id, newEntry);
    return newEntry;
  }

  /// Get an entry by ID
  WorkEntry? getById(String id) {
    return _box.get(id);
  }

  /// Update an existing work entry
  Future<WorkEntry> update(WorkEntry entry) async {
    final updatedEntry = entry.copyWith(
      updatedAt: DateTime.now(),
    );
    await _box.put(entry.id, updatedEntry);
    return updatedEntry;
  }

  /// Delete a work entry
  /// 
  /// ⚠️ LEGACY WRITE PATH DISABLED: Use EntryProvider.deleteEntry() instead.
  /// This method will throw in debug mode to prevent data loss from missing break/notes/timezone.
  Future<void> delete(String id) async {
    assert(() {
      throw StateError(
        'Legacy WorkEntry write path is disabled. Use EntryProvider.deleteEntry() instead. '
        'This prevents missing break/notes and timezone issues.'
      );
    }());
    await _box.delete(id);
  }

  /// Get total work minutes for a user within a date range
  int getTotalMinutesInRange(String userId, DateTime start, DateTime end) {
    return getForUserInRange(userId, start, end)
        .fold(0, (sum, entry) => sum + entry.workMinutes);
  }

  /// Close the Hive box
  Future<void> close() async {
    await _box.close();
  }
}