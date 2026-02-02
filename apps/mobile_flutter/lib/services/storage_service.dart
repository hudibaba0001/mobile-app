import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for handling Supabase Storage operations
/// Provides methods for uploading and managing files in Supabase Storage
class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload a document or attachment for an entry
  ///
  /// [userId] - The unique identifier for the user
  /// [entryId] - The unique identifier for the entry
  /// [file] - The file to upload
  /// [fileName] - Optional custom filename
  ///
  /// Returns the download URL of the uploaded file
  /// Throws [StorageException] on storage errors
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

      // Read file bytes
      final fileBytes = await file.readAsBytes();

      // Upload to Supabase Storage
      final path = 'entries/$userId/$entryId/$name';
      await _supabase.storage.from('attachments').uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              metadata: {
                'uploadedBy': userId,
                'entryId': entryId,
                'uploadedAt': DateTime.now().toIso8601String(),
              },
            ),
          );

      // Get and return the public URL
      return _supabase.storage.from('attachments').getPublicUrl(path);
    } on StorageException catch (e) {
      throw StorageException('Failed to upload attachment: ${e.message}');
    } catch (e) {
      throw StorageException('Unexpected error uploading attachment: $e');
    }
  }

  /// Upload a profile picture for a user
  ///
  /// [userId] - The unique identifier for the user
  /// [file] - The image file to upload
  /// [fileName] - Optional custom filename
  ///
  /// Returns the download URL of the uploaded image
  /// Throws [StorageException] on storage errors
  Future<String> uploadProfilePicture(
    String userId,
    File file, {
    String? fileName,
  }) async {
    try {
      // Generate filename if not provided
      final name =
          fileName ?? 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Read file bytes
      final fileBytes = await file.readAsBytes();

      // Upload to Supabase Storage
      final path = 'profiles/$userId/$name';
      await _supabase.storage.from('avatars').uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              metadata: {
                'uploadedBy': userId,
                'uploadedAt': DateTime.now().toIso8601String(),
              },
            ),
          );

      // Get and return the public URL
      return _supabase.storage.from('avatars').getPublicUrl(path);
    } on StorageException catch (e) {
      throw StorageException('Failed to upload profile picture: ${e.message}');
    } catch (e) {
      throw StorageException('Unexpected error uploading profile picture: $e');
    }
  }

  /// Delete a file from storage
  ///
  /// [path] - The path of the file in storage
  /// [bucket] - The bucket name (default: 'attachments')
  ///
  /// Throws [StorageException] on storage errors
  Future<void> deleteFile(String path, {String bucket = 'attachments'}) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } on StorageException catch (e) {
      throw StorageException('Failed to delete file: ${e.message}');
    } catch (e) {
      throw StorageException('Unexpected error deleting file: $e');
    }
  }

  /// Get the public URL for a file
  ///
  /// [path] - The path of the file in storage
  /// [bucket] - The bucket name (default: 'attachments')
  ///
  /// Returns the public URL of the file
  String getPublicUrl(String path, {String bucket = 'attachments'}) {
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  /// List all files for a user in a specific bucket
  ///
  /// [userId] - The unique identifier for the user
  /// [bucket] - The bucket name (default: 'attachments')
  ///
  /// Returns a list of file information
  /// Throws [StorageException] on storage errors
  Future<List<FileMetadata>> listUserFiles(
    String userId, {
    String bucket = 'attachments',
  }) async {
    try {
      final response = await _supabase.storage.from(bucket).list(
            path: userId,
          );

      return response.map((item) {
        // Supabase file metadata uses camelCase
        final metadata = item.metadata;
        final size = metadata != null && metadata.containsKey('size')
            ? (metadata['size'] as num?)?.toInt() ?? 0
            : 0;
        
        // Parse dates safely from String?
        final createdAt = item.createdAt != null 
            ? DateTime.tryParse(item.createdAt!) ?? DateTime.now() 
            : DateTime.now();
        final updatedAt = item.updatedAt != null 
            ? DateTime.tryParse(item.updatedAt!) ?? DateTime.now() 
            : DateTime.now();
        
        return FileMetadata(
          name: item.name,
          size: size,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      }).toList();
    } on StorageException catch (e) {
      throw StorageException('Failed to list files: ${e.message}');
    } catch (e) {
      throw StorageException('Unexpected error listing files: $e');
    }
  }
}

/// Custom exception for storage operations
class StorageException implements Exception {
  final String message;
  
  StorageException(this.message);
  
  @override
  String toString() => 'StorageException: $message';
}

/// Metadata for a file in storage
class FileMetadata {
  final String name;
  final int size;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  FileMetadata({
    required this.name,
    required this.size,
    required this.createdAt,
    required this.updatedAt,
  });
  
  @override
  String toString() => 'FileMetadata(name: $name, size: $size, createdAt: $createdAt)';
}
