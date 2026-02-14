import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/app_config.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';

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

  /// Record that the user has accepted terms and privacy policy
  Future<UserProfile?> acceptLegal() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    try {
      final uri = Uri.parse('$_apiBase/api/mobile/legal/accept');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
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
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
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
}
