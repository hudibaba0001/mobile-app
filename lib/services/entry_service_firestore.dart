import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/entry.dart';
import '../utils/error_handler.dart';

/// Service for managing unified Entry objects with Firestore backend
/// Handles both travel and work entries with Firebase Cloud Firestore integration
class EntryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection name for entries in Firestore
  static const String _entriesCollection = 'entries';

  /// Create a new entry in Firestore
  /// 
  /// [entry] - The Entry object to create
  /// 
  /// Throws [FirebaseException] on Firestore errors
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
  /// 
  /// [userId] - The user ID to fetch entries for
  /// 
  /// Returns a list of Entry objects sorted by date (newest first)
  /// Throws [FirebaseException] on Firestore errors
  Future<List<Entry>> fetchEntries(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_entriesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Entry.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Update an existing entry in Firestore
  /// 
  /// [entry] - The Entry object to update
  /// 
  /// Throws [FirebaseException] on Firestore errors
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
  /// 
  /// [entryId] - The ID of the entry to delete
  /// 
  /// Throws [FirebaseException] on Firestore errors
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

  /// Fetch entries for a specific user and date range
  /// 
  /// [userId] - The user ID to fetch entries for
  /// [startDate] - Start date of the range
  /// [endDate] - End date of the range
  /// 
  /// Returns a list of Entry objects within the date range
  /// Throws [FirebaseException] on Firestore errors
  Future<List<Entry>> fetchEntriesForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_entriesCollection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Entry.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Fetch entries for a specific user filtered by entry type
  /// 
  /// [userId] - The user ID to fetch entries for
  /// [entryType] - The type of entries to fetch (travel or work)
  /// 
  /// Returns a list of Entry objects of the specified type
  /// Throws [FirebaseException] on Firestore errors
  Future<List<Entry>> fetchEntriesByType(String userId, String entryType) async {
    try {
      final snapshot = await _firestore
          .collection(_entriesCollection)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: entryType)
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Entry.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Get a specific entry by ID
  /// 
  /// [entryId] - The ID of the entry to fetch
  /// 
  /// Returns the Entry object if found, null otherwise
  /// Throws [FirebaseException] on Firestore errors
  Future<Entry?> getEntryById(String entryId) async {
    try {
      final doc = await _firestore
          .collection(_entriesCollection)
          .doc(entryId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return Entry.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleStorageError(error, stackTrace);
      throw appError;
    }
  }

  /// Stream of entries for real-time updates
  /// 
  /// [userId] - The user ID to stream entries for
  /// 
  /// Returns a stream of Entry lists that updates in real-time
  Stream<List<Entry>> streamEntries(String userId) {
    return _firestore
        .collection(_entriesCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Entry.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}
