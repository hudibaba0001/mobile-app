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
    throw StateError(
        'LEGACY_READ_BLOCKED: use EntryProvider.entries (Entry) instead of HiveTravelRepository');
  }

  @override
  List<TravelEntry> getForUserInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    throw StateError(
        'LEGACY_READ_BLOCKED: use EntryProvider.entries (Entry) instead of HiveTravelRepository');
  }

  @override
  Future<TravelEntry> add(TravelEntry entry) async {
    throw StateError(
        'LEGACY_WRITE_BLOCKED: use EntryProvider.addEntry/addEntries (Entry)');
  }

  @override
  Future<TravelEntry> update(TravelEntry entry) async {
    throw StateError(
        'LEGACY_WRITE_BLOCKED: use EntryProvider.updateEntry (Entry)');
  }

  @override
  Future<void> delete(String id) async {
    throw StateError(
        'LEGACY_WRITE_BLOCKED: use EntryProvider.deleteEntry (Entry)');
  }

  @override
  TravelEntry? getById(String id) {
    throw StateError(
        'LEGACY_READ_BLOCKED: use EntryProvider.entries (Entry) instead of HiveTravelRepository');
  }

  @override
  int getTotalMinutesInRange(String userId, DateTime start, DateTime end) {
    throw StateError(
        'LEGACY_READ_BLOCKED: use EntryProvider.entries (Entry)');
  }

  @override
  Future<void> close() async {
    // Box is managed by RepositoryProvider, don't close here
  }
}
