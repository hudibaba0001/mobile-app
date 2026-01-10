import '../config/supabase_config.dart';
import '../models/user_profile.dart';

/// Service for fetching user profile from Supabase
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
}

