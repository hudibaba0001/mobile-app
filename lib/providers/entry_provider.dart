import 'package:flutter/foundation.dart';
import '../models/entry.dart';

class EntryProvider extends ChangeNotifier {
  List<Entry> _entries = [];
  List<Entry> _filteredEntries = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  EntryType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  List<Entry> get entries => _entries;
  List<Entry> get filteredEntries => _filteredEntries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  EntryType? get selectedType => _selectedType;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // TODO: Implement actual data loading
      _entries = [];
      _filteredEntries = _entries;
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
    _applyFilters();
    notifyListeners();
  }

  Future<void> updateEntry(Entry entry) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = entry;
      _applyFilters();
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    _applyFilters();
    notifyListeners();
  }

  void filterEntries({
    String? searchQuery,
    EntryType? selectedType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _searchQuery = searchQuery ?? _searchQuery;
    _selectedType = selectedType ?? _selectedType;
    _startDate = startDate ?? _startDate;
    _endDate = endDate ?? _endDate;
    
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredEntries = _entries.where((entry) {
      // Type filter
      if (_selectedType != null && entry.type != _selectedType) {
        return false;
      }

      // Date range filter
      if (_startDate != null && entry.date.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && entry.date.isAfter(_endDate!)) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch = entry.notes?.toLowerCase().contains(query) == true ||
            (entry.type == EntryType.travel && 
             ((entry.from?.toLowerCase().contains(query) == true) ||
              (entry.to?.toLowerCase().contains(query) == true)));
        
        if (!matchesSearch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedType = null;
    _startDate = null;
    _endDate = null;
    _filteredEntries = _entries;
    notifyListeners();
  }

  List<Entry> getRecentEntries({int limit = 10}) {
    final sortedEntries = List<Entry>.from(_entries)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedEntries.take(limit).toList();
  }
} 