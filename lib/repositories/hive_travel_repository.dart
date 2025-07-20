import 'package:hive/hive.dart';
import '../models/travel_time_entry.dart';
import '../utils/constants.dart';
import 'travel_repository.dart';

class HiveTravelRepository implements TravelRepository {
  late Box<TravelTimeEntry> _box;

  HiveTravelRepository() {
    _box = Hive.box<TravelTimeEntry>(AppConstants.travelEntriesBox);
  }

  @override
  Future<List<TravelTimeEntry>> getAllEntries() async {
    final entries = _box.values.toList();
    // Sort by date descending (newest first)
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  @override
  Future<List<TravelTimeEntry>> getEntriesInDateRange(DateTime start, DateTime end) async {
    final allEntries = await getAllEntries();
    return allEntries.where((entry) {
      return entry.date.isAfter(start.subtract(const Duration(days: 1))) &&
             entry.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Future<void> addEntry(TravelTimeEntry entry) async {
    await _box.add(entry);
  }

  @override
  Future<void> updateEntry(TravelTimeEntry entry) async {
    final index = _box.values.toList().indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      await _box.putAt(index, entry);
    } else {
      throw Exception('Entry not found for update');
    }
  }

  @override
  Future<void> deleteEntry(String id) async {
    final entries = _box.values.toList();
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].id == id) {
        await _box.deleteAt(i);
        return;
      }
    }
    throw Exception('Entry not found for deletion');
  }

  @override
  Future<List<TravelTimeEntry>> searchEntries(String query) async {
    if (query.trim().isEmpty) {
      return getAllEntries();
    }

    final allEntries = await getAllEntries();
    final lowercaseQuery = query.toLowerCase();

    return allEntries.where((entry) {
      return entry.departure.toLowerCase().contains(lowercaseQuery) ||
             entry.arrival.toLowerCase().contains(lowercaseQuery) ||
             (entry.info?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  @override
  Future<TravelTimeEntry?> getEntryById(String id) async {
    final entries = _box.values.toList();
    try {
      return entries.firstWhere((entry) => entry.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<String>> getRecentRoutes({int limit = 5}) async {
    final entries = await getAllEntries();
    final routes = <String>{};
    
    for (final entry in entries) {
      final route = '${entry.departure} → ${entry.arrival}';
      routes.add(route);
      if (routes.length >= limit) break;
    }
    
    return routes.toList();
  }

  // Helper method to get entries count
  Future<int> getEntriesCount() async {
    return _box.length;
  }

  // Helper method to get total minutes
  Future<int> getTotalMinutes() async {
    final entries = await getAllEntries();
    return entries.fold(0, (sum, entry) => sum + entry.minutes);
  }

  // Helper method to get entries by location
  Future<List<TravelTimeEntry>> getEntriesByLocation(String locationId) async {
    final allEntries = await getAllEntries();
    return allEntries.where((entry) {
      return entry.departureLocationId == locationId || 
             entry.arrivalLocationId == locationId;
    }).toList();
  }
}