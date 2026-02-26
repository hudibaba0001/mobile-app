import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../config/supabase_config.dart';
import '../models/user_entitlement.dart';
import 'auth_http_client.dart';
import 'supabase_auth_service.dart';

class EntitlementService {
  final _supabase = SupabaseConfig.client;
  final AuthHttpClient _authHttpClient;

  EntitlementService({
    SupabaseAuthService? authService,
    http.Client? httpClient,
    AuthHttpClient? authHttpClient,
  }) : _authHttpClient = authHttpClient ??
            AuthHttpClient(
              authService: authService,
              client: httpClient,
            );

  String get _apiBase {
    final configured = AppConfig.apiBase.trim();
    if (configured.isNotEmpty) return configured;
    return 'https://app.kviktime.se';
  }

  Future<UserEntitlement?> fetchCurrentEntitlement() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('user_entitlements')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserEntitlement.fromMap(response);
  }

  Future<void> bootstrapProfileAndPendingEntitlement({
    String? firstName,
    String? lastName,
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$_apiBase/api/mobile/profile/bootstrap');
    final payload = <String, dynamic>{};
    if (firstName != null && firstName.trim().isNotEmpty) {
      payload['firstName'] = firstName.trim();
    }
    if (lastName != null && lastName.trim().isNotEmpty) {
      payload['lastName'] = lastName.trim();
    }

    final response = await _authHttpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Bootstrap failed: ${response.body}');
    }

    debugPrint('EntitlementService: Profile bootstrap successful');
  }
}
