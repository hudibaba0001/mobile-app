import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/travel_entry.dart';

class TravelRepository {
  final Box<TravelEntry> _box;
  final _uuid = const Uuid();

  TravelRepository(this._box);

  /// Get all travel entries for a user
  List<TravelEntry> getAllForUser(String userId) {
    throw StateError(
        'LEGACY_READ_BLOCKED: use EntryProvider.entries (Entry) instead of TravelRepository');
  }

  /// Get travel entries for a user within a date range
  List<TravelEntry> getForUserInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    throw StateError(
        'LEGACY_READ_BLOCKED: use EntryProvider.entries (Entry) instead of TravelRepository');
  }

  /// Add a new travel entry
  /// 
  /// ⚠️ LEGACY WRITE PATH DISABLED: Use EntryProvider.addEntry() instead.
  /// This method will throw in debug mode to prevent data loss from missing break/notes/timezone.
  Future<TravelEntry> add(TravelEntry entry) async {
    throw StateError(
        'LEGACY_WRITE_BLOCKED: use EntryProvider.addEntry/addEntries (Entry)');
  }

  /// Get an entry by ID
  TravelEntry? getById(String id) {
    throw StateError(
        'LEGACY_READ_BLOCKED: use EntryProvider.entries (Entry) instead of TravelRepository');
  }

  /// Update an existing travel entry
  /// 
  /// ⚠️ LEGACY WRITE PATH DISABLED: Use EntryProvider.updateEntry() instead.
  /// This method will throw in debug mode to prevent data loss from missing break/notes/timezone.
  Future<TravelEntry> update(TravelEntry entry) async {
    throw StateError(
        'LEGACY_WRITE_BLOCKED: use EntryProvider.updateEntry (Entry)');
  }

  /// Delete a travel entry
  /// 
  /// ⚠️ LEGACY WRITE PATH DISABLED: Use EntryProvider.deleteEntry() instead.
  /// This method will throw in debug mode to prevent data loss from missing break/notes/timezone.
  Future<void> delete(String id) async {
    throw StateError(
        'LEGACY_WRITE_BLOCKED: use EntryProvider.deleteEntry (Entry)');
  }

  /// Get total travel minutes for a user within a date range
  int getTotalMinutesInRange(String userId, DateTime start, DateTime end) {
    throw StateError(
        'LEGACY_READ_BLOCKED: use EntryProvider.entries (Entry)');
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
