import 'package:flutter/foundation.dart';
import '../models/entry.dart';

class EntryProvider extends ChangeNotifier {
  List<Entry> _entries = [];
  bool _isLoading = false;
  String? _error;

  List<Entry> get entries => _entries;
  List<Entry> get filteredEntries => _entries; // Basic implementation
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // TODO: Implement actual data loading
      _entries = [];
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEntry(Entry entry) async {
    _entries.add(entry);
    notifyListeners();
  }

  Future<void> updateEntry(Entry entry) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = entry;
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }
} 