import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Real Firebase Auth service
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  AuthService() {
    _currentUser = _auth.currentUser;
    _isAuthenticated = _currentUser != null;
    _isInitialized = false;

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      _isAuthenticated = user != null;
      debugPrint(
          'AuthService: Auth state changed - Authenticated: $_isAuthenticated');
      notifyListeners();
    });
  }

  // Initialize the auth service
  Future<void> initialize() async {
    debugPrint('AuthService: Starting initialization...');
    debugPrint('AuthService: Firebase Auth instance: $_auth');
    debugPrint('AuthService: Firebase Auth app: ${_auth.app}');
    debugPrint('AuthService: Firebase Auth app name: ${_auth.app.name}');
    debugPrint('AuthService: Firebase Auth app options: ${_auth.app.options}');

    await _loadAuthState();
  }

  // Load saved authentication state
  Future<void> _loadAuthState() async {
    try {
      debugPrint('AuthService: Loading auth state...');

      // Firebase Auth handles the current user automatically
      _currentUser = _auth.currentUser;
      _isAuthenticated = _currentUser != null;

      if (_isAuthenticated) {
        debugPrint(
            'AuthService: User already authenticated: ${_currentUser!.email}');
      } else {
        debugPrint('AuthService: No authenticated user found');
      }
    } catch (e) {
      debugPrint('AuthService: Error loading auth state: $e');
      _currentUser = null;
      _isAuthenticated = false;
    } finally {
      _isInitialized = true;
      debugPrint(
          'AuthService: Initialized = $_isInitialized, Authenticated = $_isAuthenticated');
      notifyListeners();
    }
  }

  // Save authentication state
  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_isAuthenticated && _currentUser != null) {
        await prefs.setBool('isAuthenticated', true);
        await prefs.setString('userEmail', _currentUser!.email ?? '');
        await prefs.setString('userUid', _currentUser!.uid);
        await prefs.setString(
            'userDisplayName', _currentUser!.displayName ?? '');
      } else {
        await prefs.setBool('isAuthenticated', false);
        await prefs.remove('userEmail');
        await prefs.remove('userUid');
        await prefs.remove('userDisplayName');
      }
    } catch (e) {
      debugPrint('AuthService: Error saving auth state: $e');
    }
  }

  // Real Firebase sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    debugPrint('AuthService: Attempting sign in for email: $email');

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint(
          'AuthService: Sign in successful for: ${credential.user?.email}');
      await _saveAuthState();

      return credential;
    } catch (e) {
      debugPrint('AuthService: Sign in failed');

      if (e is FirebaseAuthException) {
        debugPrint('AuthService: Error code: ${e.code}');

        // Translate Firebase errors to user-friendly messages
        switch (e.code) {
          case 'user-not-found':
            throw Exception('No account found with this email address.');
          case 'wrong-password':
            throw Exception('Incorrect password. Please try again.');
          case 'invalid-email':
            throw Exception('Invalid email address format.');
          case 'user-disabled':
            throw Exception(
                'This account has been disabled. Please contact support.');
          default:
            throw Exception('Unable to sign in. Please try again later.');
        }
      }

      throw Exception('Unable to sign in. Please try again later.');
    }
  }

  // Real Firebase sign up
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    debugPrint('AuthService: Creating new account for email: $email');

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint(
          'AuthService: Account created successfully for: ${credential.user?.email}');
      await _saveAuthState();

      return credential;
    } catch (e) {
      debugPrint('AuthService: Account creation failed');

      if (e is FirebaseAuthException) {
        debugPrint('AuthService: Error code: ${e.code}');

        switch (e.code) {
          case 'email-already-in-use':
            throw Exception(
                'An account already exists with this email address.');
          case 'invalid-email':
            throw Exception('Invalid email address format.');
          case 'operation-not-allowed':
            throw Exception('Account creation is currently disabled.');
          case 'weak-password':
            throw Exception('Please choose a stronger password.');
          default:
            throw Exception(
                'Unable to create account. Please try again later.');
        }
      }

      throw Exception('Unable to create account. Please try again later.');
    }
  }

  // Real Firebase sign out
  Future<void> signOut() async {
    debugPrint('AuthService: Signing out user');

    try {
      await _auth.signOut();
      await _saveAuthState();
      debugPrint('AuthService: Sign out successful');
    } catch (e) {
      debugPrint('AuthService: Sign out failed: $e');
      throw Exception('Unable to sign out. Please try again later.');
    }
  }

  // Real Firebase password reset
  Future<void> sendPasswordResetEmail({required String email}) async {
    debugPrint('AuthService: Sending password reset email');

    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('AuthService: Password reset email sent successfully');
    } catch (e) {
      debugPrint('AuthService: Password reset failed');

      if (e is FirebaseAuthException) {
        debugPrint('AuthService: Error code: ${e.code}');

        switch (e.code) {
          case 'user-not-found':
            throw Exception('No account found with this email address.');
          case 'invalid-email':
            throw Exception('Invalid email address format.');
          default:
            throw Exception(
                'Unable to send password reset email. Please try again later.');
        }
      }

      throw Exception(
          'Unable to send password reset email. Please try again later.');
    }
  }

  // Check if user has admin privileges
  Future<bool> isAdmin() async {
    if (!_isAuthenticated || _currentUser == null) {
      return false;
    }

    try {
      // Get the ID token to check custom claims
      final token = await _currentUser!.getIdTokenResult(true);
      final claims = token.claims;

      // Check for admin custom claim
      final isAdmin = claims?['admin'] == true;
      debugPrint('AuthService: Admin check result: $isAdmin');

      return isAdmin;
    } catch (e) {
      debugPrint('AuthService: Error checking admin status: $e');
      return false;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({String? displayName}) async {
    if (_currentUser == null) {
      throw Exception('No authenticated user');
    }

    try {
      await _currentUser!.updateDisplayName(displayName);
      debugPrint('AuthService: Profile updated successfully');
    } catch (e) {
      debugPrint('AuthService: Profile update failed: $e');
      throw Exception('Unable to update profile. Please try again later.');
    }
  }

  // Temporary method for development - create account without backend API
  Future<UserCredential> createAccountForDevelopment({
    required String email,
    required String password,
    String? displayName,
  }) async {
    debugPrint('AuthService: Creating development account');

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }

      debugPrint('AuthService: Development account created successfully');
      await _saveAuthState();

      return credential;
    } catch (e) {
      debugPrint('AuthService: Development account creation failed');

      if (e is FirebaseAuthException) {
        debugPrint('AuthService: Error code: ${e.code}');

        switch (e.code) {
          case 'email-already-in-use':
            throw Exception(
                'An account already exists with this email address.');
          case 'invalid-email':
            throw Exception('Invalid email address format.');
          case 'operation-not-allowed':
            throw Exception('Account creation is currently disabled.');
          case 'weak-password':
            throw Exception('Please choose a stronger password.');
          default:
            throw Exception(
                'Unable to create account. Please try again later.');
        }
      }

      throw Exception('Unable to create account. Please try again later.');
    }
  }
}
