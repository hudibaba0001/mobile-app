import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';
import 'auth_http_client.dart';
import 'supabase_auth_service.dart';

class LegalVersions {
  const LegalVersions({
    required this.termsVersion,
    required this.privacyVersion,
  });

  final String termsVersion;
  final String privacyVersion;
}

/// Service for fetching and updating user profile from Supabase
class ProfileService {
  final _supabase = SupabaseConfig.client;
  final AuthHttpClient _authHttpClient;
  static const String _setupCompletedKeyPrefix = 'setupCompleted_';

  ProfileService({
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

  /// Fetch user profile for the current authenticated user
  /// Returns null if user is not authenticated or profile doesn't exist
  Future<UserProfile?> fetchProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      // Merge email from auth user if not in profile
      final profileData = Map<String, dynamic>.from(response);
      if (profileData['email'] == null) {
        profileData['email'] = user.email;
      }

      return UserProfile.fromMap(profileData);
    } catch (e) {
      debugPrint('ProfileService: Error fetching profile: $e');
      rethrow;
    }
  }

  /// Record that the user has accepted terms and privacy policy.
  /// Throws if session is missing or the backend rejects the request.
  Future<UserProfile?> acceptLegal() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw StateError('Cannot accept legal: no authenticated session');
    }

    try {
      final uri = Uri.parse('$_apiBase/api/mobile/legal/accept');
      final response = await _authHttpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(const {}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Legal acceptance failed: ${response.body}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final profile = body['profile'];
      if (profile is! Map<String, dynamic>) {
        return fetchProfile();
      }

      final profileData = Map<String, dynamic>.from(profile);
      profileData['email'] ??= _supabase.auth.currentUser?.email;
      return UserProfile.fromMap(profileData);
    } on AuthExpiredException {
      rethrow;
    } catch (e) {
      debugPrint('ProfileService: Error accepting legal: $e');
      rethrow;
    }
  }

  /// Fetch current legal versions resolved by backend from WordPress.
  Future<LegalVersions?> fetchCurrentLegalVersions() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    try {
      final uri = Uri.parse('$_apiBase/api/mobile/legal/current');
      final response = await _authHttpClient.get(
        uri,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to fetch legal versions: ${response.body}');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final termsVersion = (body['termsVersion'] as String?)?.trim();
      final privacyVersion = (body['privacyVersion'] as String?)?.trim();
      if (termsVersion == null ||
          termsVersion.isEmpty ||
          privacyVersion == null ||
          privacyVersion.isEmpty) {
        return null;
      }

      return LegalVersions(
        termsVersion: termsVersion,
        privacyVersion: privacyVersion,
      );
    } on AuthExpiredException {
      rethrow;
    } catch (e) {
      debugPrint('ProfileService: Error fetching legal versions: $e');
      rethrow;
    }
  }

  /// Check if profile exists for current user
  Future<bool> profileExists() async {
    final profile = await fetchProfile();
    return profile != null;
  }

  /// Update contract settings in the user's profile
  /// Returns the updated profile or null if user is not authenticated
  Future<UserProfile?> updateContractSettings({
    required int contractPercent,
    required int fullTimeHours,
    DateTime? trackingStartDate,
    required int openingFlexMinutes,
    required String employerMode,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint(
          'ProfileService: Cannot update contract settings - user not authenticated');
      return null;
    }

    try {
      final trackingDateStr = trackingStartDate != null
          ? '${trackingStartDate.year}-${trackingStartDate.month.toString().padLeft(2, '0')}-${trackingStartDate.day.toString().padLeft(2, '0')}'
          : null;

      final response = await _supabase
          .from('profiles')
          .update({
            'contract_percent': contractPercent,
            'full_time_hours': fullTimeHours,
            'tracking_start_date': trackingDateStr,
            'opening_flex_minutes': openingFlexMinutes,
            'employer_mode': employerMode,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', user.id)
          .select()
          .maybeSingle();

      if (response == null) {
        debugPrint('ProfileService: Profile not found after update');
        return null;
      }

      debugPrint('ProfileService: ✅ Contract settings saved to Supabase');
      return UserProfile.fromMap(response);
    } catch (e) {
      debugPrint('ProfileService: Error updating contract settings: $e');
      rethrow;
    }
  }

  /// Update only specific contract fields (for granular updates)
  Future<void> updateContractField(String field, dynamic value) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint(
          'ProfileService: Cannot update $field - user not authenticated');
      return;
    }

    try {
      await _supabase.from('profiles').update({
        field: value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', user.id);

      debugPrint('ProfileService: ✅ Updated $field in Supabase');
    } catch (e) {
      debugPrint('ProfileService: Error updating $field: $e');
      rethrow;
    }
  }

  static String setupCompletedCacheKeyForUser(String userId) {
    return '$_setupCompletedKeyPrefix$userId';
  }

  static String _dateOnlyString(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return '${normalized.year.toString().padLeft(4, '0')}-'
        '${normalized.month.toString().padLeft(2, '0')}-'
        '${normalized.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _normalizeProfileUpdatePayload(
      Map<String, dynamic> updates) {
    final normalized = <String, dynamic>{};

    updates.forEach((key, value) {
      if (key == 'tracking_start_date') {
        if (value == null) {
          normalized[key] = null;
        } else if (value is DateTime) {
          normalized[key] = _dateOnlyString(value);
        } else {
          normalized[key] = value.toString();
        }
        return;
      }

      if (key == 'setup_completed_at') {
        if (value == null) {
          normalized[key] = null;
        } else if (value is DateTime) {
          normalized[key] = value.toUtc().toIso8601String();
        } else {
          normalized[key] = value;
        }
        return;
      }

      normalized[key] = value;
    });

    normalized['updated_at'] = DateTime.now().toUtc().toIso8601String();
    return normalized;
  }

  Future<UserProfile?> updateProfileFields(Map<String, dynamic> updates) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint(
          'ProfileService: Cannot update profile - user not authenticated');
      return null;
    }

    final payload = _normalizeProfileUpdatePayload(updates);
    try {
      final response = await _supabase
          .from('profiles')
          .update(payload)
          .eq('id', user.id)
          .select()
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final profileData = Map<String, dynamic>.from(response);
      profileData['email'] ??= user.email;
      return UserProfile.fromMap(profileData);
    } catch (e) {
      debugPrint('ProfileService: Error updating profile fields: $e');
      rethrow;
    }
  }

  Future<void> setLocalSetupCompleted({
    required String userId,
    required bool completed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = setupCompletedCacheKeyForUser(userId);
    await prefs.setBool(key, completed);
  }

  Future<bool> isLocalSetupCompleted(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = setupCompletedCacheKeyForUser(userId);
    return prefs.getBool(key) ?? false;
  }

  Future<UserProfile?> markSetupCompleted({DateTime? at}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return null;
    }

    final completedAt = at ?? DateTime.now();
    final profile = await updateProfileFields({
      'setup_completed_at': completedAt,
    });
    await setLocalSetupCompleted(userId: user.id, completed: true);
    return profile;
  }
}
