import '../models/entry.dart';

class EntryService {
  static final EntryService _instance = EntryService._internal();
  factory EntryService() => _instance;
  EntryService._internal();

  Future<List<Entry>> getEntries() async {
    // TODO: Implement actual data fetching
    return [];
  }

  Future<void> addEntry(Entry entry) async {
    // TODO: Implement actual data saving
  }

  Future<void> updateEntry(Entry entry) async {
    // TODO: Implement actual data updating
  }

  Future<void> deleteEntry(String id) async {
    // TODO: Implement actual data deletion
  }
} 