import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../features/reports/analytics_models.dart';

class AnalyticsApi {
  AnalyticsApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  /// Fetches server analytics. Throws if apiBase not configured.
  Future<ServerAnalytics> fetchDashboard({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) async {
    final base = AppConfig.apiBase.trim();
    if (base.isEmpty) {
      throw StateError('KVIKTIME_API_BASE not set');
    }
    final u = Uri.parse('$base/analytics/dashboard').replace(queryParameters: {
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
      if (userId != null && userId.isNotEmpty) 'userId': userId,
    });
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    if (token == null) {
      throw AuthException('No active session');
    }
    final resp = await _client.get(
      u,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));
    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw AuthException('Not authorized (admin only or invalid token)');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw StateError('Server error ${resp.statusCode}: ${resp.body}');
    }
    final map = json.decode(resp.body) as Map<String, dynamic>;
    return ServerAnalytics.fromMap(map);
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
