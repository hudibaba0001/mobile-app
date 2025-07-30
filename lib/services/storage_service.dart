import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Service class for handling Firebase Storage operations
/// Provides methods for uploading and managing files in Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a document or attachment for an entry
  ///
  /// [userId] - The unique identifier for the user
  /// [entryId] - The unique identifier for the entry
  /// [file] - The file to upload
  /// [fileName] - Optional custom filename
  ///
  /// Returns the download URL of the uploaded file
  /// Throws [FirebaseException] on storage errors
  Future<String> uploadEntryAttachment(
    String userId,
    String entryId,
    File file, {
    String? fileName,
  }) async {
    try {
      // Generate filename if not provided
      final name =
          fileName ??
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      // Create a reference to the storage location
      final ref = _storage.ref('entries/$userId/$entryId/$name');

      // Set metadata for the file
      final metadata = SettableMetadata(
        customMetadata: {
          'uploadedBy': userId,
          'entryId': entryId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload the file
      final uploadTask = ref.putFile(file, metadata);

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get and return the download URL
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Failed to upload attachment: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during upload: $e');
    }
  }

  /// Delete a file from Firebase Storage
  ///
  /// [downloadUrl] - The download URL of the file to delete
  ///
  /// Throws [FirebaseException] on storage errors
  Future<void> deleteFile(String downloadUrl) async {
    try {
      // Get reference from download URL
      final ref = _storage.refFromURL(downloadUrl);

      // Delete the file
      await ref.delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete file: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during deletion: $e');
    }
  }

  /// Get metadata for a file
  ///
  /// [downloadUrl] - The download URL of the file
  ///
  /// Returns the file metadata
  /// Throws [FirebaseException] on storage errors
  Future<FullMetadata> getFileMetadata(String downloadUrl) async {
    try {
      // Get reference from download URL
      final ref = _storage.refFromURL(downloadUrl);

      // Get and return metadata
      return await ref.getMetadata();
    } on FirebaseException catch (e) {
      throw Exception('Failed to get file metadata: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error getting metadata: $e');
    }
  }

  /// Get download URL for a file reference
  ///
  /// [ref] - The storage reference
  ///
  /// Returns the download URL
  /// Throws [FirebaseException] on storage errors
  Future<String> getDownloadUrl(Reference ref) async {
    try {
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Failed to get download URL: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error getting URL: $e');
    }
  }
}
