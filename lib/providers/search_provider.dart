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
  SearchMode _searchMode = SearchMode.contains;
  AppError? _lastError;

  // Search results
  List<TravelTimeEntry> _travelResults = [];
  List<Location> _locationResults = [];
  
  // Saved searches
  final Map<String, SavedSearch> _savedSearches = {};
  
  // Advanced search options
  bool _caseSensitive = false;
  bool _wholeWordsOnly = false;
  bool _useRegex = false;

  // Getters
  String get query => _query;
  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  List<String> get suggestions => List.unmodifiable(_suggestions);
  bool get isSearching => _isSearching;
  SearchType get searchType => _searchType;
  SearchMode get searchMode => _searchMode;
  AppError? get lastError => _lastError;
  List<TravelTimeEntry> get travelResults => List.unmodifiable(_travelResults);
  List<Location> get locationResults => List.unmodifiable(_locationResults);
  Map<String, SavedSearch> get savedSearches => Map.unmodifiable(_savedSearches);
  bool get hasQuery => _query.isNotEmpty;
  bool get hasResults => _travelResults.isNotEmpty || _locationResults.isNotEmpty;
  bool get hasSuggestions => _suggestions.isNotEmpty;
  bool get hasSavedSearches => _savedSearches.isNotEmpty;
  bool get caseSensitive => _caseSensitive;
  bool get wholeWordsOnly => _wholeWordsOnly;
  bool get useRegex => _useRegex;

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

  // Set search mode
  void setSearchMode(SearchMode mode) {
    if (_searchMode != mode) {
      _searchMode = mode;
      notifyListeners();
    }
  }

  // Set advanced search options
  void setCaseSensitive(bool caseSensitive) {
    if (_caseSensitive != caseSensitive) {
      _caseSensitive = caseSensitive;
      notifyListeners();
    }
  }

  void setWholeWordsOnly(bool wholeWordsOnly) {
    if (_wholeWordsOnly != wholeWordsOnly) {
      _wholeWordsOnly = wholeWordsOnly;
      notifyListeners();
    }
  }

  void setUseRegex(bool useRegex) {
    if (_useRegex != useRegex) {
      _useRegex = useRegex;
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
    // Search travel entries
    if (_searchType == SearchType.all || _searchType == SearchType.travel) {
      _travelResults = travelEntries.where((entry) {
        return _matchesQuery(entry.departure) ||
               _matchesQuery(entry.arrival) ||
               _matchesQuery(entry.info ?? '');
      }).toList();
      
      // Sort by relevance (exact matches first, then partial matches)
      _travelResults.sort((a, b) {
        final aScore = _calculateTravelRelevanceScore(a);
        final bScore = _calculateTravelRelevanceScore(b);
        return bScore.compareTo(aScore);
      });
    }

    // Search locations
    if (_searchType == SearchType.all || _searchType == SearchType.location) {
      _locationResults = locations.where((location) {
        return _matchesQuery(location.name) ||
               _matchesQuery(location.address);
      }).toList();
      
      // Sort by relevance and usage
      _locationResults.sort((a, b) {
        final aScore = _calculateLocationRelevanceScore(a);
        final bScore = _calculateLocationRelevanceScore(b);
        return bScore.compareTo(aScore);
      });
    }
  }

  // Advanced matching logic based on search mode and options
  bool _matchesQuery(String text) {
    if (text.isEmpty || _query.isEmpty) return false;

    String searchText = _caseSensitive ? text : text.toLowerCase();
    String searchQuery = _caseSensitive ? _query : _query.toLowerCase();

    if (_useRegex) {
      try {
        final regex = RegExp(searchQuery, caseSensitive: _caseSensitive);
        return regex.hasMatch(searchText);
      } catch (e) {
        // Fall back to contains if regex is invalid
        return searchText.contains(searchQuery);
      }
    }

    if (_wholeWordsOnly) {
      final regex = RegExp(r'\b' + RegExp.escape(searchQuery) + r'\b', 
                          caseSensitive: _caseSensitive);
      return regex.hasMatch(searchText);
    }

    switch (_searchMode) {
      case SearchMode.contains:
        return searchText.contains(searchQuery);
      case SearchMode.startsWith:
        return searchText.startsWith(searchQuery);
      case SearchMode.endsWith:
        return searchText.endsWith(searchQuery);
      case SearchMode.exact:
        return searchText == searchQuery;
    }
  }

  // Calculate relevance score for travel entries
  int _calculateTravelRelevanceScore(TravelTimeEntry entry) {
    int score = 0;
    final queryLower = _caseSensitive ? _query : _query.toLowerCase();
    
    // Exact matches get highest score
    if (_matchesExactly(entry.departure) || _matchesExactly(entry.arrival)) {
      score += 100;
    }
    
    // Starts with query gets high score
    if (_matchesStartsWith(entry.departure) || _matchesStartsWith(entry.arrival)) {
      score += 50;
    }
    
    // Contains query gets medium score
    if (_matchesQuery(entry.departure) || _matchesQuery(entry.arrival)) {
      score += 25;
    }
    
    // Info field matches get lower score
    if (_matchesQuery(entry.info ?? '')) {
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
  int _calculateLocationRelevanceScore(Location location) {
    int score = 0;
    
    // Exact matches get highest score
    if (_matchesExactly(location.name) || _matchesExactly(location.address)) {
      score += 100;
    }
    
    // Starts with query gets high score
    if (_matchesStartsWith(location.name) || _matchesStartsWith(location.address)) {
      score += 50;
    }
    
    // Contains query gets medium score
    if (_matchesQuery(location.name) || _matchesQuery(location.address)) {
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

  // Helper methods for different match types
  bool _matchesExactly(String text) {
    if (text.isEmpty || _query.isEmpty) return false;
    String searchText = _caseSensitive ? text : text.toLowerCase();
    String searchQuery = _caseSensitive ? _query : _query.toLowerCase();
    return searchText == searchQuery;
  }

  bool _matchesStartsWith(String text) {
    if (text.isEmpty || _query.isEmpty) return false;
    String searchText = _caseSensitive ? text : text.toLowerCase();
    String searchQuery = _caseSensitive ? _query : _query.toLowerCase();
    return searchText.startsWith(searchQuery);
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

  // Saved searches functionality
  void saveSearch(String name, {String? description}) {
    if (name.trim().isEmpty || _query.isEmpty) return;
    
    final savedSearch = SavedSearch(
      name: name.trim(),
      query: _query,
      searchType: _searchType,
      searchMode: _searchMode,
      caseSensitive: _caseSensitive,
      wholeWordsOnly: _wholeWordsOnly,
      useRegex: _useRegex,
      description: description?.trim(),
      createdAt: DateTime.now(),
      lastUsed: DateTime.now(),
    );
    
    _savedSearches[name.trim()] = savedSearch;
    notifyListeners();
  }

  void loadSavedSearch(String name) {
    final savedSearch = _savedSearches[name];
    if (savedSearch == null) return;
    
    _query = savedSearch.query;
    _searchType = savedSearch.searchType;
    _searchMode = savedSearch.searchMode;
    _caseSensitive = savedSearch.caseSensitive;
    _wholeWordsOnly = savedSearch.wholeWordsOnly;
    _useRegex = savedSearch.useRegex;
    
    // Update last used timestamp
    _savedSearches[name] = savedSearch.copyWith(lastUsed: DateTime.now());
    
    notifyListeners();
  }

  void deleteSavedSearch(String name) {
    if (_savedSearches.remove(name) != null) {
      notifyListeners();
    }
  }

  void updateSavedSearch(String name, {String? newName, String? description}) {
    final savedSearch = _savedSearches[name];
    if (savedSearch == null) return;
    
    final updatedSearch = savedSearch.copyWith(
      name: newName ?? savedSearch.name,
      description: description,
      lastUsed: DateTime.now(),
    );
    
    if (newName != null && newName != name) {
      _savedSearches.remove(name);
      _savedSearches[newName] = updatedSearch;
    } else {
      _savedSearches[name] = updatedSearch;
    }
    
    notifyListeners();
  }

  List<SavedSearch> getSavedSearchesSorted({SortBy sortBy = SortBy.lastUsed}) {
    final searches = _savedSearches.values.toList();
    
    switch (sortBy) {
      case SortBy.name:
        searches.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortBy.created:
        searches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortBy.lastUsed:
        searches.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
        break;
    }
    
    return searches;
  }

  // Advanced search functionality
  Future<void> performAdvancedSearch({
    required List<TravelTimeEntry> travelEntries,
    required List<Location> locations,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? locationIds,
    int? minDuration,
    int? maxDuration,
  }) async {
    if (_query.isEmpty) {
      clearResults();
      return;
    }

    _setSearching(true);
    try {
      // Filter by date range if specified
      List<TravelTimeEntry> filteredEntries = travelEntries;
      if (startDate != null || endDate != null) {
        filteredEntries = travelEntries.where((entry) {
          if (startDate != null && entry.date.isBefore(startDate)) return false;
          if (endDate != null && entry.date.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      // Filter by location IDs if specified
      if (locationIds != null && locationIds.isNotEmpty) {
        filteredEntries = filteredEntries.where((entry) {
          return locationIds.contains(entry.departureLocationId) ||
                 locationIds.contains(entry.arrivalLocationId);
        }).toList();
      }

      // Filter by duration if specified
      if (minDuration != null || maxDuration != null) {
        filteredEntries = filteredEntries.where((entry) {
          if (minDuration != null && entry.minutes < minDuration) return false;
          if (maxDuration != null && entry.minutes > maxDuration) return false;
          return true;
        }).toList();
      }

      await _performSearch(filteredEntries, locations);
      _addToHistory(_query);
      _clearError();
    } catch (error) {
      _handleError(error);
    } finally {
      _setSearching(false);
    }
  }

  // Search statistics
  Map<String, dynamic> getSearchStatistics() {
    return {
      'totalSearches': _searchHistory.length,
      'savedSearches': _savedSearches.length,
      'lastSearchQuery': _searchHistory.isNotEmpty ? _searchHistory.first : null,
      'mostPopularSearch': getPopularSearches(limit: 1).isNotEmpty 
          ? getPopularSearches(limit: 1).first 
          : null,
      'searchTypes': {
        'all': _searchHistory.where((q) => _searchType == SearchType.all).length,
        'travel': _searchHistory.where((q) => _searchType == SearchType.travel).length,
        'location': _searchHistory.where((q) => _searchType == SearchType.location).length,
      },
    };
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

}

enum SearchType {
  all,
  travel,
  location,
}

enum SearchMode {
  contains,
  startsWith,
  endsWith,
  exact,
}

enum SortBy {
  name,
  created,
  lastUsed,
}

class SavedSearch {
  final String name;
  final String query;
  final SearchType searchType;
  final SearchMode searchMode;
  final bool caseSensitive;
  final bool wholeWordsOnly;
  final bool useRegex;
  final String? description;
  final DateTime createdAt;
  final DateTime lastUsed;

  const SavedSearch({
    required this.name,
    required this.query,
    required this.searchType,
    required this.searchMode,
    required this.caseSensitive,
    required this.wholeWordsOnly,
    required this.useRegex,
    this.description,
    required this.createdAt,
    required this.lastUsed,
  });

  SavedSearch copyWith({
    String? name,
    String? query,
    SearchType? searchType,
    SearchMode? searchMode,
    bool? caseSensitive,
    bool? wholeWordsOnly,
    bool? useRegex,
    String? description,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return SavedSearch(
      name: name ?? this.name,
      query: query ?? this.query,
      searchType: searchType ?? this.searchType,
      searchMode: searchMode ?? this.searchMode,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      wholeWordsOnly: wholeWordsOnly ?? this.wholeWordsOnly,
      useRegex: useRegex ?? this.useRegex,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'query': query,
      'searchType': searchType.index,
      'searchMode': searchMode.index,
      'caseSensitive': caseSensitive,
      'wholeWordsOnly': wholeWordsOnly,
      'useRegex': useRegex,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      name: json['name'] as String,
      query: json['query'] as String,
      searchType: SearchType.values[json['searchType'] as int],
      searchMode: SearchMode.values[json['searchMode'] as int],
      caseSensitive: json['caseSensitive'] as bool,
      wholeWordsOnly: json['wholeWordsOnly'] as bool,
      useRegex: json['useRegex'] as bool,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: DateTime.parse(json['lastUsed'] as String),
    );
  }

  @override
  String toString() {
    return 'SavedSearch(name: $name, query: $query, type: $searchType, mode: $searchMode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SavedSearch &&
        other.name == name &&
        other.query == query &&
        other.searchType == searchType &&
        other.searchMode == searchMode &&
        other.caseSensitive == caseSensitive &&
        other.wholeWordsOnly == wholeWordsOnly &&
        other.useRegex == useRegex;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      query,
      searchType,
      searchMode,
      caseSensitive,
      wholeWordsOnly,
      useRegex,
    );
  }
}