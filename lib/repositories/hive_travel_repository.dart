import 'package:hive/hive.dart';
import '../models/travel_entry.dart';
import '../utils/constants.dart';
import 'travel_repository.dart';

class HiveTravelRepository implements TravelRepository {
  Box<TravelEntry>? _box;

  Future<Box<TravelEntry>> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<TravelEntry>('travel_entries');
    }
    return _box!;
  }

  @override
  Future<void> initialize() async {
    await _getBox();
  }

  @override
  List<TravelEntry> getAllForUser(String userId) {
    final box = _box;
    if (box == null) return [];
    
    return box.values
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
    final box = _box;
    if (box == null) return [];
    
    return box.values
        .where((entry) =>
            entry.userId == userId &&
            entry.date.isAfter(start.subtract(const Duration(days: 1))) &&
            entry.date.isBefore(end.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<TravelEntry> add(TravelEntry entry) async {
    final box = await _getBox();
    final newEntry = entry.copyWith(
      id: entry.id,
      updatedAt: DateTime.now(),
    );
    await box.put(newEntry.id, newEntry);
    return newEntry;
  }

  @override
  Future<TravelEntry> update(TravelEntry entry) async {
    final box = await _getBox();
    final updatedEntry = entry.copyWith(
      updatedAt: DateTime.now(),
    );
    await box.put(entry.id, updatedEntry);
    return updatedEntry;
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  @override
  int getTotalMinutesInRange(String userId, DateTime start, DateTime end) {
    return getForUserInRange(userId, start, end)
        .fold(0, (sum, entry) => sum + entry.travelMinutes);
  }

  @override
  Future<void> close() async {
    await _box?.close();
  }
}
