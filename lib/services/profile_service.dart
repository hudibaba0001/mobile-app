// ignore_for_file: avoid_print
import '../config/supabase_config.dart';
import '../models/user_profile.dart';

/// Service for fetching and updating user profile from Supabase
class ProfileService {
  final _supabase = SupabaseConfig.client;

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
      print('ProfileService: Error fetching profile: $e');
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
      print('ProfileService: Cannot update contract settings - user not authenticated');
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
        print('ProfileService: Profile not found after update');
        return null;
      }

      print('ProfileService: ✅ Contract settings saved to Supabase');
      return UserProfile.fromMap(response);
    } catch (e) {
      print('ProfileService: Error updating contract settings: $e');
      rethrow;
    }
  }

  /// Update only specific contract fields (for granular updates)
  Future<void> updateContractField(String field, dynamic value) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('ProfileService: Cannot update $field - user not authenticated');
      return;
    }

    try {
      await _supabase
          .from('profiles')
          .update({
            field: value,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', user.id);

      print('ProfileService: ✅ Updated $field in Supabase');
    } catch (e) {
      print('ProfileService: Error updating $field: $e');
      rethrow;
    }
  }
}
