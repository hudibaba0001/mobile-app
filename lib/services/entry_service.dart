import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/entry.dart';
import '../models/travel_summary.dart';
import '../repositories/location_repository.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';
import '../utils/retry_helper.dart';

/// Service for managing unified Entry objects (replaces TravelService)
/// Handles both travel and work entries, but filters by type for travel-specific operations
class EntryService {
  final LocationRepository _locationRepository;
  
  // Use unified 'entries' box instead of 'travelEntries'
  static const String _entriesBoxName = 'entries';

  EntryService({
    required LocationRepository locationRepository,
  }) : _locationRepository = locationRepository;

  /// Get the Hive box for entries
  Future<Box<Entry>> _getEntriesBox() async {
    return await Hive.openBox<Entry>(_entriesBoxName);
  }

  /// Get all travel entries (filtered by EntryType.travel)
  Future<List<Entry>> getAllTravelEntries() async {
    try {
      return await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          // Filter only travel entries from the unified box
          return box.values
              .where((entry) => entry.type == EntryType.travel)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Get travel entries for a specific date range
  Future<List<Entry>> getEntriesForDateRange(DateTime startDate, DateTime endDate) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          // Filter by travel type AND date range
          return box.values
              .where((entry) => 
                  entry.type == EntryType.travel &&
                  entry.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
                  entry.date.isBefore(endDate.add(const Duration(days: 1))))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Get travel entries for a specific date
  Future<List<Entry>> getEntriesForDate(DateTime date) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          final targetDate = DateTime(date.year, date.month, date.day);
          
          // Filter by travel type AND specific date
          return box.values
              .where((entry) {
                final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
                return entry.type == EntryType.travel && entryDate.isAtSameMomentAs(targetDate);
              })
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Add a new travel entry
  Future<void> addEntry(Entry entry) async {
    try {
      // Ensure this is a travel entry
      if (entry.type != EntryType.travel) {
        throw ArgumentError('EntryService.addEntry only accepts travel entries');
      }

      await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          // Store in unified entries box with entry ID as key
          await box.put(entry.id, entry);
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Update an existing travel entry
  Future<void> updateEntry(Entry entry) async {
    try {
      // Ensure this is a travel entry
      if (entry.type != EntryType.travel) {
        throw ArgumentError('EntryService.updateEntry only accepts travel entries');
      }

      await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          // Update the entry with current timestamp
          final updatedEntry = entry.copyWith(updatedAt: DateTime.now());
          await box.put(updatedEntry.id, updatedEntry);
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Delete a travel entry by ID
  Future<void> deleteEntry(String entryId) async {
    try {
      await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          final entry = box.get(entryId);
          
          // Verify it's a travel entry before deletion
          if (entry != null && entry.type == EntryType.travel) {
            await box.delete(entryId);
          } else if (entry != null) {
            throw ArgumentError('Cannot delete non-travel entry via EntryService');
          }
          // If entry is null, deletion is considered successful (already deleted)
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Get a specific travel entry by ID
  Future<Entry?> getEntryById(String entryId) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          final entry = box.get(entryId);
          
          // Return only if it's a travel entry
          return (entry?.type == EntryType.travel) ? entry : null;
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Search travel entries by query (searches from, to, and notes fields)
  Future<List<Entry>> searchEntries(String query) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          final queryLower = query.toLowerCase();
          
          // Filter by travel type AND search query
          return box.values
              .where((entry) => 
                  entry.type == EntryType.travel &&
                  (entry.from?.toLowerCase().contains(queryLower) == true ||
                   entry.to?.toLowerCase().contains(queryLower) == true ||
                   entry.notes?.toLowerCase().contains(queryLower) == true))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Get recent travel entries (limited count)
  Future<List<Entry>> getRecentEntries({int limit = 10}) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          
          // Get recent travel entries only
          final travelEntries = box.values
              .where((entry) => entry.type == EntryType.travel)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          
          return travelEntries.take(limit).toList();
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Generate travel summary for a date range
  Future<TravelSummary> generateSummary(DateTime startDate, DateTime endDate) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async => _generateSummaryInternal(startDate, endDate),
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Internal method to generate travel summary
  Future<TravelSummary> _generateSummaryInternal(DateTime startDate, DateTime endDate) async {
    // Get only travel entries for the date range
    final entries = await getEntriesForDateRange(startDate, endDate);
    
    if (entries.isEmpty) {
      return TravelSummary(
        totalEntries: 0,
        totalMinutes: 0,
        startDate: startDate,
        endDate: endDate,
        locationFrequency: {},
      );
    }

    // Calculate total minutes from travel entries
    final totalMinutes = entries.fold(0, (sum, entry) => sum + (entry.travelMinutes ?? 0));
    final locationFrequency = <String, int>{};

    // Count location frequency for travel entries
    for (final entry in entries) {
      if (entry.from != null) {
        locationFrequency[entry.from!] = (locationFrequency[entry.from!] ?? 0) + 1;
      }
      if (entry.to != null) {
        locationFrequency[entry.to!] = (locationFrequency[entry.to!] ?? 0) + 1;
      }
    }

    return TravelSummary(
      totalEntries: entries.length,
      totalMinutes: totalMinutes,
      startDate: startDate,
      endDate: endDate,
      locationFrequency: locationFrequency,
    );
  }

  /// Get suggested routes based on frequency
  Future<List<String>> getSuggestedRoutes({int limit = 5}) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          final routeFrequency = <String, int>{};
          
          // Count route frequency for travel entries only
          for (final entry in box.values) {
            if (entry.type == EntryType.travel && 
                entry.from != null && 
                entry.to != null) {
              final route = '${entry.from} → ${entry.to}';
              routeFrequency[route] = (routeFrequency[route] ?? 0) + 1;
            }
          }
          
          // Sort by frequency and return top routes
          final sortedRoutes = routeFrequency.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          return sortedRoutes
              .take(limit)
              .map((entry) => entry.key)
              .toList();
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Export travel entries to CSV format
  Future<String> exportToCSV(List<Entry> entries) async {
    try {
      final buffer = StringBuffer();
      
      // CSV header
      buffer.writeln('Date,From,To,Minutes,Duration,Notes,Journey ID,Segment');
      
      // Filter and export only travel entries
      final travelEntries = entries.where((entry) => entry.type == EntryType.travel);
      
      for (final entry in travelEntries) {
        final duration = entry.formattedDuration;
        final journeyInfo = entry.isMultiSegment 
            ? '${entry.segmentOrder}/${entry.totalSegments}'
            : '';
        
        buffer.writeln([
          entry.date.toIso8601String().split('T')[0], // Date only
          _escapeCsvField(entry.from ?? ''),
          _escapeCsvField(entry.to ?? ''),
          entry.travelMinutes ?? 0,
          duration,
          _escapeCsvField(entry.notes ?? ''),
          entry.journeyId ?? '',
          journeyInfo,
        ].join(','));
      }
      
      return buffer.toString();
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleUnknownError(error, stackTrace);
      throw appError;
    }
  }

  /// Helper method to escape CSV fields
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Get all journey segments for a specific journey ID
  Future<List<Entry>> getJourneySegments(String journeyId) async {
    try {
      return await RetryHelper.executeWithRetry(
        () async {
          final box = await _getEntriesBox();
          
          // Get all travel entries with the specified journey ID
          final segments = box.values
              .where((entry) => 
                  entry.type == EntryType.travel && 
                  entry.journeyId == journeyId)
              .toList();
          
          // Sort by segment order
          segments.sort((a, b) => 
              (a.segmentOrder ?? 0).compareTo(b.segmentOrder ?? 0));
          
          return segments;
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Delete an entire journey (all segments)
  Future<void> deleteJourney(String journeyId) async {
    try {
      await RetryHelper.executeWithRetry(
        () async {
          final segments = await getJourneySegments(journeyId);
          final box = await _getEntriesBox();
          
          // Delete all segments of the journey
          for (final segment in segments) {
            await box.delete(segment.id);
          }
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Check if an entry is part of a multi-segment journey
  bool isMultiSegmentEntry(Entry entry) {
    return entry.type == EntryType.travel && 
           entry.journeyId != null && 
           (entry.totalSegments ?? 0) > 1;
  }

  /// Update an entire journey with new segments
  Future<void> updateJourney(String journeyId, List<Entry> updatedSegments) async {
    try {
      await RetryHelper.executeWithRetry(
        () async {
          // First, delete existing segments
          await deleteJourney(journeyId);
          
          // Then add updated segments
          for (final segment in updatedSegments) {
            if (segment.type == EntryType.travel) {
              await addEntry(segment);
            }
          }
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Get statistics for travel entries
  Future<Map<String, dynamic>> getTravelStatistics() async {
    try {
      return await RetryHelper.executeWithRetry(
        () async {
          final entries = await getAllTravelEntries();
          
          if (entries.isEmpty) {
            return {
              'totalEntries': 0,
              'totalMinutes': 0,
              'averageMinutes': 0.0,
              'mostFrequentRoute': null,
              'totalJourneys': 0,
            };
          }
          
          final totalMinutes = entries.fold(0, (sum, entry) => sum + (entry.travelMinutes ?? 0));
          final averageMinutes = totalMinutes / entries.length;
          
          // Count unique journeys
          final uniqueJourneys = entries
              .where((entry) => entry.journeyId != null)
              .map((entry) => entry.journeyId)
              .toSet()
              .length;
          
          // Find most frequent route
          final routeFrequency = <String, int>{};
          for (final entry in entries) {
            if (entry.from != null && entry.to != null) {
              final route = '${entry.from} → ${entry.to}';
              routeFrequency[route] = (routeFrequency[route] ?? 0) + 1;
            }
          }
          
          String? mostFrequentRoute;
          if (routeFrequency.isNotEmpty) {
            mostFrequentRoute = routeFrequency.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key;
          }
          
          return {
            'totalEntries': entries.length,
            'totalMinutes': totalMinutes,
            'averageMinutes': averageMinutes,
            'mostFrequentRoute': mostFrequentRoute,
            'totalJourneys': uniqueJourneys,
          };
        },
        shouldRetry: RetryHelper.shouldRetryStorageError,
      );
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }
}