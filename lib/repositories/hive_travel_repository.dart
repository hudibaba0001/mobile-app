import 'package:hive/hive.dart';
import '../models/travel_entry.dart';
import 'travel_repository.dart';

class HiveTravelRepository implements TravelRepository {
  final Box<TravelEntry> _box;

  HiveTravelRepository(this._box);

  @override
  Future<void> initialize() async {
    // Box is already provided in constructor, no need to open
  }

  @override
  List<TravelEntry> getAllForUser(String userId) {
    return _box.values
        .where((entry) => entry.userId == userId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
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

  @override
  Future<TravelEntry> add(TravelEntry entry) async {
    assert(() {
      throw StateError(
        'Legacy TravelEntry write path (HiveTravelRepository) is disabled. Use EntryProvider.addEntry() instead. '
        'This prevents missing break/notes and timezone issues.'
      );
    }());
    final newEntry = entry.copyWith(
      id: entry.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : entry.id,
      updatedAt: DateTime.now(),
    );
    await _box.put(newEntry.id, newEntry);
    return newEntry;
  }

  @override
  Future<TravelEntry> update(TravelEntry entry) async {
    assert(() {
      throw StateError(
        'Legacy TravelEntry write path (HiveTravelRepository) is disabled. Use EntryProvider.updateEntry() instead. '
        'This prevents missing break/notes and timezone issues.'
      );
    }());
    final updatedEntry = entry.copyWith(
      updatedAt: DateTime.now(),
    );
    await _box.put(entry.id, updatedEntry);
    return updatedEntry;
  }

  @override
  Future<void> delete(String id) async {
    assert(() {
      throw StateError(
        'Legacy TravelEntry write path (HiveTravelRepository) is disabled. Use EntryProvider.deleteEntry() instead. '
        'This prevents missing break/notes and timezone issues.'
      );
    }());
    await _box.delete(id);
  }

  @override
  TravelEntry? getById(String id) {
    return _box.get(id);
  }

  @override
  int getTotalMinutesInRange(String userId, DateTime start, DateTime end) {
    return getForUserInRange(userId, start, end)
        .fold(0, (sum, entry) => sum + entry.travelMinutes);
  }

  @override
  Future<void> close() async {
    // Box is managed by RepositoryProvider, don't close here
  }
}
