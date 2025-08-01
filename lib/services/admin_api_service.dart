import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_user.dart';
import '../config/api_config.dart';

class AdminApiService {
  final String baseUrl;
  final http.Client _client;

  AdminApiService({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? ApiConfig.functionBaseUrl,
      _client = client ?? http.Client();

  /// Fetches all users from the backend
  /// Throws an [ApiException] if the request fails
  Future<List<AdminUser>> fetchUsers() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final usersList = data['users'] as List;
        return usersList.map((json) => AdminUser.fromJson(json)).toList();
      }

      throw ApiException(
        code: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    } catch (e) {
      throw ApiException(
        code: 500,
        message: 'Failed to fetch users: ${e.toString()}',
      );
    }
  }

  /// Gets the authorization headers for API requests
  Future<Map<String, String>> _getAuthHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ApiException(code: 401, message: 'Not authenticated');
    }

    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Disables a user account
  /// Throws an [ApiException] if the request fails
  Future<void> disableUser(String uid) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users/$uid/disable'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode != 200) {
        throw ApiException(
          code: response.statusCode,
          message: _parseErrorMessage(response.body),
        );
      }
    } catch (e) {
      throw ApiException(
        code: 500,
        message: 'Failed to disable user: ${e.toString()}',
      );
    }
  }

  /// Enables a user account
  /// Throws an [ApiException] if the request fails
  Future<void> enableUser(String uid) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users/$uid/enable'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode != 200) {
        throw ApiException(
          code: response.statusCode,
          message: _parseErrorMessage(response.body),
        );
      }
    } catch (e) {
      throw ApiException(
        code: 500,
        message: 'Failed to enable user: ${e.toString()}',
      );
    }
  }

  /// Permanently deletes a user account and all associated data
  /// Throws an [ApiException] if the request fails
  Future<void> deleteUser(String uid) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/users/$uid'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode != 200) {
        throw ApiException(
          code: response.statusCode,
          message: _parseErrorMessage(response.body),
        );
      }
    } catch (e) {
      throw ApiException(
        code: 500,
        message: 'Failed to delete user: ${e.toString()}',
      );
    }
  }

  String _parseErrorMessage(String body) {
    try {
      final data = json.decode(body) as Map<String, dynamic>;
      return data['error'] ?? 'Unknown error occurred';
    } catch (_) {
      return 'Failed to parse error message';
    }
  }
}

class ApiException implements Exception {
  final int code;
  final String message;

  ApiException({required this.code, required this.message});

  @override
  String toString() => 'ApiException: [$code] $message';
}
