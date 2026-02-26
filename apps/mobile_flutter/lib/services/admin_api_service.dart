import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin_user.dart';
import '../config/api_config.dart';
import 'auth_http_client.dart';
import 'supabase_auth_service.dart';

class DashboardData {
  final double totalHoursLoggedThisWeek;
  final int activeUsers;
  final double overtimeBalance;
  final double averageDailyHours;
  final List<DailyTrend> dailyTrends;
  final List<UserDistribution> userDistribution;
  final List<AvailableUser> availableUsers;

  DashboardData({
    required this.totalHoursLoggedThisWeek,
    required this.activeUsers,
    required this.overtimeBalance,
    required this.averageDailyHours,
    required this.dailyTrends,
    required this.userDistribution,
    required this.availableUsers,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalHoursLoggedThisWeek:
          (json['totalHoursLoggedThisWeek'] as num).toDouble(),
      activeUsers: json['activeUsers'] as int,
      overtimeBalance: (json['overtimeBalance'] as num).toDouble(),
      averageDailyHours: (json['averageDailyHours'] as num).toDouble(),
      dailyTrends: (json['dailyTrends'] as List)
          .map((item) => DailyTrend.fromJson(item))
          .toList(),
      userDistribution: (json['userDistribution'] as List)
          .map((item) => UserDistribution.fromJson(item))
          .toList(),
      availableUsers: (json['availableUsers'] as List)
          .map((item) => AvailableUser.fromJson(item))
          .toList(),
    );
  }
}

class DailyTrend {
  final String date;
  final double totalHours;
  final double workHours;
  final double travelHours;

  DailyTrend({
    required this.date,
    required this.totalHours,
    required this.workHours,
    required this.travelHours,
  });

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    return DailyTrend(
      date: json['date'] as String,
      totalHours: (json['totalHours'] as num).toDouble(),
      workHours: (json['workHours'] as num).toDouble(),
      travelHours: (json['travelHours'] as num).toDouble(),
    );
  }
}

class UserDistribution {
  final String userId;
  final String userName;
  final double totalHours;
  final double percentage;

  UserDistribution({
    required this.userId,
    required this.userName,
    required this.totalHours,
    required this.percentage,
  });

  factory UserDistribution.fromJson(Map<String, dynamic> json) {
    return UserDistribution(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      totalHours: (json['totalHours'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class AvailableUser {
  final String userId;
  final String userName;

  AvailableUser({
    required this.userId,
    required this.userName,
  });

  factory AvailableUser.fromJson(Map<String, dynamic> json) {
    return AvailableUser(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
    );
  }
}

class AdminApiService {
  final String baseUrl;
  final AuthHttpClient _authHttpClient;

  AdminApiService({
    String? baseUrl,
    http.Client? client,
    SupabaseAuthService? authService,
    AuthHttpClient? authHttpClient,
  })  : baseUrl = baseUrl ?? ApiConfig.functionBaseUrl,
        _authHttpClient = authHttpClient ??
            AuthHttpClient(
              authService: authService,
              client: client,
            );

  /// Fetches all users from the backend
  /// Throws an [ApiException] if the request fails
  Future<List<AdminUser>> fetchUsers() async {
    try {
      final response = await _authHttpClient.get(
        Uri.parse('$baseUrl/users'),
        headers: const {'Content-Type': 'application/json'},
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
    } on AuthExpiredException catch (e) {
      throw ApiException(code: 401, message: e.message);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        code: 500,
        message: 'Failed to fetch users: ${e.toString()}',
      );
    }
  }

  /// Fetches analytics dashboard data from the backend
  /// Throws an [ApiException] if the request fails
  Future<DashboardData> fetchDashboardData({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (userId != null) {
        queryParams['userId'] = userId;
      }

      final uri = Uri.parse('$baseUrl/analytics/dashboard')
          .replace(queryParameters: queryParams);

      final response = await _authHttpClient.get(
        uri,
        headers: const {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return DashboardData.fromJson(data);
      }

      throw ApiException(
        code: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    } on AuthExpiredException catch (e) {
      throw ApiException(code: 401, message: e.message);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        code: 500,
        message: 'Failed to fetch dashboard data: ${e.toString()}',
      );
    }
  }

  /// Disables a user account
  /// Throws an [ApiException] if the request fails
  Future<void> disableUser(String uid) async {
    try {
      final response = await _authHttpClient.post(
        Uri.parse('$baseUrl/users/$uid/disable'),
        headers: const {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw ApiException(
          code: response.statusCode,
          message: _parseErrorMessage(response.body),
        );
      }
    } on AuthExpiredException catch (e) {
      throw ApiException(code: 401, message: e.message);
    } on ApiException {
      rethrow;
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
      final response = await _authHttpClient.post(
        Uri.parse('$baseUrl/users/$uid/enable'),
        headers: const {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw ApiException(
          code: response.statusCode,
          message: _parseErrorMessage(response.body),
        );
      }
    } on AuthExpiredException catch (e) {
      throw ApiException(code: 401, message: e.message);
    } on ApiException {
      rethrow;
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
      final response = await _authHttpClient.delete(
        Uri.parse('$baseUrl/users/$uid'),
        headers: const {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw ApiException(
          code: response.statusCode,
          message: _parseErrorMessage(response.body),
        );
      }
    } on AuthExpiredException catch (e) {
      throw ApiException(code: 401, message: e.message);
    } on ApiException {
      rethrow;
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
