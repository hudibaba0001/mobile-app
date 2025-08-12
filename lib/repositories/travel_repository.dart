import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/travel_entry.dart';

class TravelRepository {
  final Box<TravelEntry> _box;
  final _uuid = const Uuid();

  TravelRepository(this._box);

  /// Get all travel entries for a user
  List<TravelEntry> getAllForUser(String userId) {
    return _box.values
        .where((entry) => entry.userId == userId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get travel entries for a user within a date range
  List<TravelEntry> getForUserInRange(
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

  /// Add a new travel entry
  Future<TravelEntry> add(TravelEntry entry) async {
    final assignedId = (entry.id.isEmpty) ? _uuid.v4() : entry.id;
    final newEntry = entry.copyWith(id: assignedId);
    await _box.put(newEntry.id, newEntry);
    return newEntry;
  }

  /// Get an entry by ID
  TravelEntry? getById(String id) {
    return _box.get(id);
  }

  /// Update an existing travel entry
  Future<TravelEntry> update(TravelEntry entry) async {
    final updatedEntry = entry.copyWith(
      updatedAt: DateTime.now(),
    );
    await _box.put(entry.id, updatedEntry);
    return updatedEntry;
  }

  /// Delete a travel entry
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Get total travel minutes for a user within a date range
  int getTotalMinutesInRange(String userId, DateTime start, DateTime end) {
    return getForUserInRange(userId, start, end)
        .fold(0, (sum, entry) => sum + entry.travelMinutes);
  }

  /// Close the Hive box
  Future<void> close() async {
    await _box.close();
  }

  /// Initialize the repository (for Hive-based implementations)
  Future<void> initialize() async {
    // Default implementation does nothing
  }
}