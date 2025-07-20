import 'package:flutter/foundation.dart';
import '../models/travel_time_entry.dart';
import '../models/location.dart';
import '../utils/data_validator.dart';
import '../utils/error_handler.dart';

class SearchProvider extends ChangeNotifier {
  String _query = '';
  List<String> _searchHistory = [];
  List<String> _suggestions = [];
  bool _isSearching = false;
  SearchType _searchType = SearchType.all;
  AppError? _lastError;

  // Search results
  List<TravelTimeEntry> _travelResults = [];
  List<Location> _locationResults = [];

  // Getters
  String get query => _query;
  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  List<String> get suggestions => List.unmodifiable(_suggestions);
  bool get isSearching => _isSearching;
  SearchType get searchType => _searchType;
  AppError? get lastError => _lastError;
  List<TravelTimeEntry> get travelResults => List.unmodifiable(_travelResults);
  List<Location> get locationResults => List.unmodifiable(_locationResults);
  bool get hasQuery => _query.isNotEmpty;
  bool get hasResults => _travelResults.isNotEmpty || _locationResults.isNotEmpty;
  bool get hasSuggestions => _suggestions.isNotEmpty;

  // Set search query
  void setQuery(String query) {
    final sanitizedQuery = DataValidator.sanitizeString(query);
    
    if (_query != sanitizedQuery) {
      _query = sanitizedQuery;
      
      // Validate query
      final validationErrors = DataValidator.validateSearchQuery(_query);
      if (validationErrors.isNotEmpty) {
        _handleError(validationErrors.first);
        return;
      }
      
      _clearError();
      notifyListeners();
    }
  }

  // Set search type
  void setSearchType(SearchType type) {
    if (_searchType != type) {
      _searchType = type;
      notifyListeners();
    }
  }

  // Perform search
  Future<void> search(
    List<TravelTimeEntry> travelEntries,
    List<Location> locations,
  ) async {
    if (_query.isEmpty) {
      clearResults();
      return;
    }

    _setSearching(true);
    try {
      await _performSearch(travelEntries, locations);
      _addToHistory(_query);
      _clearError();
    } catch (error) {
      _handleError(error);
    } finally {
      _setSearching(false);
    }
  }

  // Perform the actual search
  Future<void> _performSearch(
    List<TravelTimeEntry> travelEntries,
    List<Location> locations,
  ) async {
    final queryLower = _query.toLowerCase();
    
    // Search travel entries
    if (_searchType == SearchType.all || _searchType == SearchType.travel) {
      _travelResults = travelEntries.where((entry) {
        return entry.departure.toLowerCase().contains(queryLower) ||
               entry.arrival.toLowerCase().contains(queryLower) ||
               (entry.info?.toLowerCase().contains(queryLower) ?? false);
      }).toList();
      
      // Sort by relevance (exact matches first, then partial matches)
      _travelResults.sort((a, b) {
        final aScore = _calculateTravelRelevanceScore(a, queryLower);
        final bScore = _calculateTravelRelevanceScore(b, queryLower);
        return bScore.compareTo(aScore);
      });
    }

    // Search locations
    if (_searchType == SearchType.all || _searchType == SearchType.location) {
      _locationResults = locations.where((location) {
        return location.name.toLowerCase().contains(queryLower) ||
               location.address.toLowerCase().contains(queryLower);
      }).toList();
      
      // Sort by relevance and usage
      _locationResults.sort((a, b) {
        final aScore = _calculateLocationRelevanceScore(a, queryLower);
        final bScore = _calculateLocationRelevanceScore(b, queryLower);
        return bScore.compareTo(aScore);
      });
    }
  }

  // Calculate relevance score for travel entries
  int _calculateTravelRelevanceScore(TravelTimeEntry entry, String queryLower) {
    int score = 0;
    
    // Exact matches get highest score
    if (entry.departure.toLowerCase() == queryLower ||
        entry.arrival.toLowerCase() == queryLower) {
      score += 100;
    }
    
    // Starts with query gets high score
    if (entry.departure.toLowerCase().startsWith(queryLower) ||
        entry.arrival.toLowerCase().startsWith(queryLower)) {
      score += 50;
    }
    
    // Contains query gets medium score
    if (entry.departure.toLowerCase().contains(queryLower) ||
        entry.arrival.toLowerCase().contains(queryLower)) {
      score += 25;
    }
    
    // Info field matches get lower score
    if (entry.info?.toLowerCase().contains(queryLower) ?? false) {
      score += 10;
    }
    
    // Recent entries get slight boost
    final daysSinceEntry = DateTime.now().difference(entry.date).inDays;
    if (daysSinceEntry < 7) {
      score += 5;
    }
    
    return score;
  }

  // Calculate relevance score for locations
  int _calculateLocationRelevanceScore(Location location, String queryLower) {
    int score = 0;
    
    // Exact matches get highest score
    if (location.name.toLowerCase() == queryLower ||
        location.address.toLowerCase() == queryLower) {
      score += 100;
    }
    
    // Starts with query gets high score
    if (location.name.toLowerCase().startsWith(queryLower) ||
        location.address.toLowerCase().startsWith(queryLower)) {
      score += 50;
    }
    
    // Contains query gets medium score
    if (location.name.toLowerCase().contains(queryLower) ||
        location.address.toLowerCase().contains(queryLower)) {
      score += 25;
    }
    
    // Usage count boosts score
    score += location.usageCount * 2;
    
    // Favorites get boost
    if (location.isFavorite) {
      score += 20;
    }
    
    return score;
  }

  // Generate suggestions based on query
  void generateSuggestions(
    List<TravelTimeEntry> travelEntries,
    List<Location> locations,
  ) {
    if (_query.isEmpty) {
      _suggestions.clear();
      notifyListeners();
      return;
    }

    final queryLower = _query.toLowerCase();
    final suggestionSet = <String>{};

    // Add location suggestions
    for (final location in locations) {
      if (location.name.toLowerCase().contains(queryLower)) {
        suggestionSet.add(location.name);
      }
      if (location.address.toLowerCase().contains(queryLower)) {
        suggestionSet.add(location.address);
      }
    }

    // Add travel entry suggestions
    for (final entry in travelEntries) {
      if (entry.departure.toLowerCase().contains(queryLower)) {
        suggestionSet.add(entry.departure);
      }
      if (entry.arrival.toLowerCase().contains(queryLower)) {
        suggestionSet.add(entry.arrival);
      }
    }

    // Add from search history
    for (final historyItem in _searchHistory) {
      if (historyItem.toLowerCase().contains(queryLower)) {
        suggestionSet.add(historyItem);
      }
    }

    _suggestions = suggestionSet.take(8).toList();
    notifyListeners();
  }

  // Add to search history
  void _addToHistory(String query) {
    if (query.isEmpty) return;
    
    // Remove if already exists
    _searchHistory.remove(query);
    
    // Add to beginning
    _searchHistory.insert(0, query);
    
    // Keep only last 20 searches
    if (_searchHistory.length > 20) {
      _searchHistory = _searchHistory.take(20).toList();
    }
  }

  // Clear search results
  void clearResults() {
    _travelResults.clear();
    _locationResults.clear();
    notifyListeners();
  }

  // Clear search query
  void clearQuery() {
    _query = '';
    clearResults();
    _suggestions.clear();
    _clearError();
    notifyListeners();
  }

  // Clear search history
  void clearHistory() {
    _searchHistory.clear();
    notifyListeners();
  }

  // Remove item from history
  void removeFromHistory(String item) {
    _searchHistory.remove(item);
    notifyListeners();
  }

  // Get recent searches
  List<String> getRecentSearches({int limit = 5}) {
    return _searchHistory.take(limit).toList();
  }

  // Get popular searches (most frequent in history)
  List<String> getPopularSearches({int limit = 5}) {
    final frequency = <String, int>{};
    for (final search in _searchHistory) {
      frequency[search] = (frequency[search] ?? 0) + 1;
    }
    
    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) => e.key).toList();
  }

  // Helper methods
  void _setSearching(bool searching) {
    if (_isSearching != searching) {
      _isSearching = searching;
      notifyListeners();
    }
  }

  void _handleError(dynamic error) {
    if (error is AppError) {
      _lastError = error;
    } else {
      _lastError = ErrorHandler.handleUnknownError(error);
    }
    notifyListeners();
  }

  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

enum SearchType {
  all,
  travel,
  location,
}