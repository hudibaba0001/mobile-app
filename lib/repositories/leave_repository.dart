import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/leave_entry.dart';

class LeaveRepository {
  final Box<LeaveEntry> _box;
  final _uuid = const Uuid();

  LeaveRepository(this._box);

  /// Get all leave entries for a user
  List<LeaveEntry> getAllForUser(String userId) {
    return _box.values
        .where((entry) => entry.userId == userId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get leave entries for a user within a date range
  List<LeaveEntry> getForUserInRange(
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

  /// Add a new leave entry
  Future<LeaveEntry> add(LeaveEntry entry) async {
    final newEntry = entry.copyWith(id: _uuid.v4());
    await _box.put(newEntry.id, newEntry);
    return newEntry;
  }

  /// Update an existing leave entry
  Future<LeaveEntry> update(LeaveEntry entry) async {
    final updatedEntry = entry.copyWith(
      updatedAt: DateTime.now(),
    );
    await _box.put(entry.id, updatedEntry);
    return updatedEntry;
  }

  /// Delete a leave entry
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Get total paid leave days used in a year
  int getPaidLeaveDaysInYear(String userId, int year) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31);
    return getForUserInRange(userId, start, end)
        .where((entry) => entry.isPaid)
        .length;
  }

  /// Get leave entries by type for a user within a date range
  List<LeaveEntry> getByTypeInRange(
    String userId,
    LeaveType type,
    DateTime start,
    DateTime end,
  ) {
    return getForUserInRange(userId, start, end)
        .where((entry) => entry.type == type)
        .toList();
  }

  /// Close the Hive box
  Future<void> close() async {
    await _box.close();
  }
}