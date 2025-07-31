import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/entry.dart';
import '../utils/error_handler.dart';
import '../repositories/location_repository.dart';

/// Service for managing unified Entry objects with Firestore backend
class EntryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationRepository locationRepository;
  static const String _entriesCollection = 'entries';

  /// Default constructor
  EntryService({
    required this.locationRepository,
  });

  /// Create a new entry in Firestore
  Future<void> createEntry(Entry entry) async {
    try {
      await _firestore
          .collection(_entriesCollection)
          .doc(entry.id)
          .set(entry.toFirestore());
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Fetch all entries for a specific user
  Future<List<Entry>> fetchEntries(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_entriesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => Entry.fromFirestore(doc)).toList();
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Update an existing entry in Firestore
  Future<void> updateEntry(Entry entry) async {
    try {
      await _firestore
          .collection(_entriesCollection)
          .doc(entry.id)
          .update(entry.toFirestore());
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Delete an entry from Firestore
  Future<void> deleteEntry(String entryId) async {
    try {
      await _firestore
          .collection(_entriesCollection)
          .doc(entryId)
          .delete();
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Fetch entries by type
  Future<List<Entry>> fetchEntriesByType(String userId, String entryType) async {
    try {
      final snapshot = await _firestore
          .collection(_entriesCollection)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: entryType)
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => Entry.fromFirestore(doc)).toList();
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Get entry by ID
  Future<Entry?> getEntryById(String entryId) async {
    try {
      final doc = await _firestore
          .collection(_entriesCollection)
          .doc(entryId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return Entry.fromFirestore(doc);
      }
      return null;
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  // Provider methods
  Future<List<Entry>> getAllTravelEntries() async {
    const userId = 'current_user';
    return await fetchEntriesByType(userId, 'travel');
  }

  Future<void> addEntry(Entry entry) async {
    await createEntry(entry);
  }

  Future<List<Entry>> getRecentEntries({int limit = 5}) async {
    const userId = 'current_user';
    final entries = await fetchEntries(userId);
    return entries.take(limit).toList();
  }

  Future<List<Entry>> getEntriesForDate(DateTime date) async {
    const userId = 'current_user';
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    try {
      final snapshot = await _firestore
          .collection(_entriesCollection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => Entry.fromFirestore(doc)).toList();
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  // Placeholder methods
  Future<dynamic> generateSummary(DateTime startDate, DateTime endDate) async => null;
  Future<String> exportToCSV(List<Entry> entries) async => '';
  Future<Map<String, dynamic>> getTravelStatistics() async => {};
  Future<List<String>> getSuggestedRoutes({int limit = 5}) async => [];
  bool isMultiSegmentEntry(Entry entry) => entry.isMultiSegment;
  Future<void> updateJourney(String journeyId, List<Entry> segments) async {
    for (final segment in segments) {
      await updateEntry(segment);
    }
  }
  Future<void> deleteJourney(String journeyId) async {}
}