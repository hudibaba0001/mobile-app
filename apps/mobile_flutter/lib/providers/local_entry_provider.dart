import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/entry.dart';

/// Simple local entry provider that works with Hive storage
/// Handles both travel and work entries locally
class LocalEntryProvider extends ChangeNotifier {
  static const String _entriesBoxName = 'entries';
  Box<Entry>? _entriesBox;

  List<Entry> _entries = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Entry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasEntries => _entries.isNotEmpty;

  // Statistics
  int get totalEntries => _entries.length;
  List<Entry> get travelEntries =>
      _entries.where((e) => e.type == EntryType.travel).toList();
  List<Entry> get workEntries =>
      _entries.where((e) => e.type == EntryType.work).toList();

  /// Initialize the provider and load entries
  Future<void> init() async {
    await _openBox();
    await _loadEntries();
  }

  /// Open the Hive box for entries
  Future<void> _openBox() async {
    try {
      _entriesBox = await Hive.openBox<Entry>(_entriesBoxName);
    } catch (e) {
      _setError('Failed to open entries storage: $e');
    }
  }

  /// Load all entries from Hive
  Future<void> _loadEntries() async {
    if (_entriesBox == null) return;

    _setLoading(true);
    try {
      _entries = _entriesBox!.values.toList();
      // Sort by date, newest first
      _entries.sort((a, b) => b.date.compareTo(a.date));
      _clearError();
    } catch (e) {
      _setError('Failed to load entries: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new entry
  Future<bool> addEntry(Entry entry) async {
    if (_entriesBox == null) {
      _setError('Storage not initialized');
      return false;
    }

    _setLoading(true);
    try {
      await _entriesBox!.put(entry.id, entry);
      await _loadEntries(); // Reload to update the list
      _clearError();

      if (kDebugMode) {
        debugPrint('✅ Entry added: ${entry.type.name} - ${entry.formattedDuration}');
      }

      return true;
    } catch (e) {
      _setError('Failed to add entry: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing entry
  Future<bool> updateEntry(Entry entry) async {
    if (_entriesBox == null) {
      _setError('Storage not initialized');
      return false;
    }

    _setLoading(true);
    try {
      await _entriesBox!.put(entry.id, entry);
      await _loadEntries(); // Reload to update the list
      _clearError();

      if (kDebugMode) {
        debugPrint(
          '✅ Entry updated: ${entry.type.name} - ${entry.formattedDuration}',
        );
      }

      return true;
    } catch (e) {
      _setError('Failed to update entry: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete an entry
  Future<bool> deleteEntry(String entryId) async {
    if (_entriesBox == null) {
      _setError('Storage not initialized');
      return false;
    }

    _setLoading(true);
    try {
      await _entriesBox!.delete(entryId);
      await _loadEntries(); // Reload to update the list
      _clearError();

      if (kDebugMode) {
        debugPrint('✅ Entry deleted: $entryId');
      }

      return true;
    } catch (e) {
      _setError('Failed to delete entry: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get entries for today
  List<Entry> getTodayEntries() {
    final today = DateTime.now();
    return _entries.where((entry) {
      final entryDate = entry.date;
      return entryDate.year == today.year &&
          entryDate.month == today.month &&
          entryDate.day == today.day;
    }).toList();
  }

  /// Get recent entries
  List<Entry> getRecentEntries({int limit = 5}) {
    return _entries.take(limit).toList();
  }

  /// Get entries by type
  List<Entry> getEntriesByType(EntryType type) {
    return _entries.where((entry) => entry.type == type).toList();
  }

  /// Get entries for a date range
  List<Entry> getEntriesInRange(DateTime startDate, DateTime endDate) {
    return _entries.where((entry) {
      final entryDate = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      return (entryDate.isAtSameMomentAs(start) || entryDate.isAfter(start)) &&
          (entryDate.isAtSameMomentAs(end) || entryDate.isBefore(end));
    }).toList();
  }

  /// Search entries
  List<Entry> searchEntries(String query) {
    if (query.isEmpty) return _entries;

    final lowerQuery = query.toLowerCase();
    return _entries.where((entry) {
      return (entry.from?.toLowerCase().contains(lowerQuery) ?? false) ||
          (entry.to?.toLowerCase().contains(lowerQuery) ?? false) ||
          (entry.notes?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Get total duration for a type
  Duration getTotalDuration(EntryType type) {
    final entriesOfType = getEntriesByType(type);
    return entriesOfType.fold(
      Duration.zero,
      (total, entry) => total + entry.totalDuration,
    );
  }

  /// Get today's total duration
  Duration getTodayTotalDuration() {
    final todayEntries = getTodayEntries();
    return todayEntries.fold(
      Duration.zero,
      (total, entry) => total + entry.totalDuration,
    );
  }

  /// Get today's duration by type
  Duration getTodayDurationByType(EntryType type) {
    final todayEntries = getTodayEntries().where((e) => e.type == type);
    return todayEntries.fold(
      Duration.zero,
      (total, entry) => total + entry.totalDuration,
    );
  }

  /// Refresh entries
  Future<void> refresh() async {
    await _loadEntries();
  }

  /// Clear all entries (for testing)
  Future<void> clearAllEntries() async {
    if (_entriesBox == null) return;

    _setLoading(true);
    try {
      await _entriesBox!.clear();
      await _loadEntries();
      _clearError();
    } catch (e) {
      _setError('Failed to clear entries: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    if (kDebugMode) {
      debugPrint('❌ LocalEntryProvider Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Clear error manually
  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    _entriesBox?.close();
    super.dispose();
  }
}

/// Helper extension for formatting durations
extension DurationFormatting on Duration {
  String get formatted {
    if (inMinutes == 0) return '0m';

    final hours = inHours;
    final minutes = inMinutes % 60;

    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }
}
