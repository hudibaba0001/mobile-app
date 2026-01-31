// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'auth_service.dart';

class SupabaseAuthService extends ChangeNotifier implements AuthService {
  final _supabase = SupabaseConfig.client;
  bool _initialized = false;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Check if user is authenticated
  @override
  bool get isAuthenticated => currentUser != null;

  // Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      print('SupabaseAuthService: Auth state changed - Authenticated: ${data.session != null}');
      if (data.session != null) {
        print('SupabaseAuthService: User authenticated: ${data.session!.user.email}');
      } else {
        print('SupabaseAuthService: User signed out');
      }
    });
    
    _initialized = true;
    print('SupabaseAuthService: Initialized');
  }

  // Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    print('SupabaseAuthService: Attempting sign in for email: $email');
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('SupabaseAuthService: Sign in successful');
      return response;
    } catch (e) {
      print('SupabaseAuthService: Sign in failed: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUp(String email, String password) async {
    print('SupabaseAuthService: Attempting sign up for email: $email');
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      print('SupabaseAuthService: Sign up successful');
      return response;
    } catch (e) {
      print('SupabaseAuthService: Sign up failed: $e');
      rethrow;
    }
  }

  // Sign out (AuthService interface)
  @override
  Future<void> signOut() async {
    print('SupabaseAuthService: Signing out...');
    try {
      await _supabase.auth.signOut();
      print('SupabaseAuthService: Sign out successful');
    } catch (e) {
      print('SupabaseAuthService: Sign out failed: $e');
      rethrow;
    }
  }

  // Reset password (AuthService interface)
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    print('SupabaseAuthService: Sending password reset email to: $email');
    try {
      // Get redirect URL - use a deep link that opens the app
      // For mobile apps, this should be a custom URL scheme or universal link
      // For now, we'll use a placeholder that Supabase will handle
      // The actual redirect URL should be configured in Supabase dashboard
      final redirectTo = 'kviktime://reset-password';
      
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo,
      );
      print('SupabaseAuthService: Password reset email sent');
    } catch (e) {
      print('SupabaseAuthService: Password reset failed: $e');
      rethrow;
    }
  }

  // Alias for backward compatibility
  Future<void> resetPassword(String email) => sendPasswordResetEmail(email);

  // Get user ID
  String? get userId => currentUser?.id;

  // Check if service is initialized
  @override
  bool get isInitialized => _initialized;

  // AuthService interface implementation
  @override
  String? get currentUserId => currentUser?.id;

  @override
  String? get currentUserEmail => currentUser?.email;

  // Check if user is admin (placeholder implementation)
  @override
  Future<bool> isAdmin() async {
    // TODO: Implement admin check based on user metadata or database
    // For now, return false for all users
    return false;
  }

  // Update user profile
  Future<void> updateUserProfile({String? displayName}) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No authenticated user');
      
      final updates = <String, dynamic>{};
      if (displayName != null) {
        updates['data'] = {'full_name': displayName};
      }
      
      await _supabase.auth.updateUser(UserAttributes(
        data: updates['data'],
      ));
      
      print('SupabaseAuthService: Profile updated successfully');
    } catch (e) {
      print('SupabaseAuthService: Failed to update profile: $e');
      rethrow;
    }
  }

  // Sign out with cleanup callback
  Future<void> signOutWithCleanup(Function? cleanup) async {
    await signOut();
    cleanup?.call();
  }

  // Sign in with email and password (alias for signIn)
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await signIn(email, password);
  }

  // Create account for development
  Future<void> createAccountForDevelopment({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await signUp(email, password);
    
    // Update user metadata with display name if provided
    if (displayName != null) {
      await updateUserProfile(displayName: displayName);
    }
  }
}
