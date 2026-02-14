import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/external_links.dart';
import '../config/supabase_config.dart';
import 'auth_service.dart';

class SupabaseAuthService extends ChangeNotifier implements AuthService {
  final _supabase = SupabaseConfig.client;
  bool _initialized = false;

  // Callback for session expiry (UI can show re-auth dialog)
  Function()? onSessionExpired;

  // Track if we've already notified about session expiry
  bool _sessionExpiredNotified = false;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Check if user is authenticated
  @override
  bool get isAuthenticated => currentUser != null;

  // Check if session is valid (not expired)
  bool get hasValidSession {
    final session = currentSession;
    if (session == null) return false;

    // Check if token is expired (with 60 second buffer)
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return true; // No expiry = valid

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    final now = DateTime.now();
    final buffer = const Duration(seconds: 60);

    return expiryTime.isAfter(now.add(buffer));
  }

  // Get time until session expires (for UI countdown if needed)
  Duration? get timeUntilExpiry {
    final session = currentSession;
    if (session?.expiresAt == null) return null;

    final expiryTime =
        DateTime.fromMillisecondsSinceEpoch(session!.expiresAt! * 1000);
    final remaining = expiryTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      debugPrint('SupabaseAuthService: Auth event: $event');

      if (data.session != null) {
        debugPrint(
            'SupabaseAuthService: User authenticated');
        _sessionExpiredNotified = false; // Reset on successful auth
      } else {
        debugPrint('SupabaseAuthService: User signed out or session expired');
      }

      // Handle specific auth events
      if (event == AuthChangeEvent.tokenRefreshed) {
        debugPrint('SupabaseAuthService: Token refreshed successfully');
        _sessionExpiredNotified = false;
      } else if (event == AuthChangeEvent.signedOut) {
        // Check if this was due to session expiry vs user action
        if (!_sessionExpiredNotified) {
          _sessionExpiredNotified = true;
          onSessionExpired?.call();
        }
      }

      notifyListeners();
    });

    _initialized = true;
    debugPrint('SupabaseAuthService: Initialized');
  }

  /// Attempt to refresh the session token
  /// Returns true if successful, false if user needs to re-authenticate
  Future<bool> refreshSession() async {
    try {
      final session = currentSession;
      if (session == null) {
        debugPrint('SupabaseAuthService: No session to refresh');
        return false;
      }

      debugPrint('SupabaseAuthService: Attempting to refresh session...');
      final response = await _supabase.auth.refreshSession();

      if (response.session != null) {
        debugPrint('SupabaseAuthService: Session refreshed successfully');
        return true;
      } else {
        debugPrint('SupabaseAuthService: Session refresh failed - no new session');
        return false;
      }
    } catch (e) {
      debugPrint('SupabaseAuthService: Session refresh error: $e');
      return false;
    }
  }

  /// Validate session before making API calls
  /// Attempts refresh if needed, returns false if re-auth required
  Future<bool> ensureValidSession() async {
    if (!isAuthenticated) return false;

    if (hasValidSession) return true;

    // Try to refresh
    final refreshed = await refreshSession();
    if (!refreshed && !_sessionExpiredNotified) {
      _sessionExpiredNotified = true;
      onSessionExpired?.call();
    }
    return refreshed;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    debugPrint('SupabaseAuthService: Attempting sign in');
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('SupabaseAuthService: Sign in successful');
      return response;
    } catch (e) {
      debugPrint('SupabaseAuthService: Sign in failed: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUp(String email, String password) async {
    debugPrint('SupabaseAuthService: Attempting sign up');

    // Avoid repeatedly triggering signup emails for an already-created account.
    // Try password sign-in first; if user exists but is unconfirmed, surface that.
    try {
      final existingSignIn = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint(
          'SupabaseAuthService: Existing account signed in instead of new sign up');
      return existingSignIn;
    } on AuthApiException catch (signInError) {
      final code = signInError.code ?? '';
      if (code == 'email_not_confirmed') {
        debugPrint(
            'SupabaseAuthService: Account exists but email is not confirmed');
        throw AuthApiException(
          'An account with this email already exists. Please sign in.',
          statusCode: signInError.statusCode,
          code: 'user_already_exists',
        );
      }

      const signInNotFoundCodes = {
        'invalid_credentials',
        'invalid_login_credentials',
        'invalid_grant',
        'user_not_found',
      };

      // If sign-in failed for reasons other than "no usable account", abort.
      if (!signInNotFoundCodes.contains(code)) {
        rethrow;
      }
    }

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: ExternalLinks.emailVerifiedUrl,
      );

      // If signup flow did not create a session (email confirmation flows),
      // attempt a password sign-in so in-app signup can continue.
      if (response.session == null) {
        debugPrint(
            'SupabaseAuthService: Sign up created no session, attempting sign in');
        try {
          final signInResponse = await _supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
          debugPrint('SupabaseAuthService: Sign in after sign up successful');
          return signInResponse;
        } on AuthApiException catch (signInError) {
          final code = signInError.code ?? '';
          if (code == 'email_not_confirmed') {
            throw AuthApiException(
              'An account with this email already exists. Please sign in.',
              statusCode: signInError.statusCode,
              code: 'user_already_exists',
            );
          }
          rethrow;
        }
      }

      debugPrint('SupabaseAuthService: Sign up successful');
      return response;
    } catch (e) {
      debugPrint('SupabaseAuthService: Sign up failed: $e');
      rethrow;
    }
  }

  // Sign out (AuthService interface)
  @override
  Future<void> signOut() async {
    debugPrint('SupabaseAuthService: Signing out...');
    try {
      await _supabase.auth.signOut();
      debugPrint('SupabaseAuthService: Sign out successful');
    } catch (e) {
      debugPrint('SupabaseAuthService: Sign out failed: $e');
      rethrow;
    }
  }

  // Reset password (AuthService interface)
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    debugPrint('SupabaseAuthService: Sending password reset email');
    try {
      // Redirect to web-based password reset page
      final redirectTo = ExternalLinks.resetPasswordUrl;

      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo,
      );
      debugPrint('SupabaseAuthService: Password reset email sent');
    } catch (e) {
      debugPrint('SupabaseAuthService: Password reset failed: $e');
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

  // Check if user is admin by querying the profiles table
  @override
  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from('profiles')
          .select('is_admin')
          .eq('id', user.id)
          .maybeSingle();

      return (response?['is_admin'] as bool?) ?? false;
    } catch (e) {
      debugPrint('SupabaseAuthService: Error checking admin status: $e');
      return false;
    }
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

      debugPrint('SupabaseAuthService: Profile updated successfully');
    } catch (e) {
      debugPrint('SupabaseAuthService: Failed to update profile: $e');
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

  // Delete own account and all associated data
  Future<void> deleteAccount() async {
    final session = currentSession;
    if (session == null) throw Exception('Not authenticated');

    final uri = Uri.https('app.kviktime.se', '/api/delete-account');
    final response = await http.delete(uri, headers: {
      'Authorization': 'Bearer ${session.accessToken}',
      'Content-Type': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to delete account');
    }
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
