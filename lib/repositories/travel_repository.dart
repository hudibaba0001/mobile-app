import '../models/travel_time_entry.dart';

abstract class TravelRepository {
  Future<List<TravelTimeEntry>> getAllEntries();
  Future<List<TravelTimeEntry>> getEntriesInDateRange(DateTime start, DateTime end);
  Future<void> addEntry(TravelTimeEntry entry);
  Future<void> updateEntry(TravelTimeEntry entry);
  Future<void> deleteEntry(String id);
  Future<List<TravelTimeEntry>> searchEntries(String query);
  Future<TravelTimeEntry?> getEntryById(String id);
  Future<List<String>> getRecentRoutes({int limit = 5});
}