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
      print(
          '🔐 AuthService: Auth state changed - Authenticated: $_isAuthenticated');
      notifyListeners();
    });
  }

  // Initialize the auth service
  Future<void> initialize() async {
    await _loadAuthState();
  }

  // Load saved authentication state
  Future<void> _loadAuthState() async {
    try {
      print('🔐 AuthService: Loading auth state...');

      // Firebase Auth handles the current user automatically
      _currentUser = _auth.currentUser;
      _isAuthenticated = _currentUser != null;

      if (_isAuthenticated) {
        print(
            '🔐 AuthService: User already authenticated: ${_currentUser!.email}');
      } else {
        print('🔐 AuthService: No authenticated user found');
      }
    } catch (e) {
      print('Error loading auth state: $e');
      _currentUser = null;
      _isAuthenticated = false;
    } finally {
      _isInitialized = true;
      print(
          '🔐 AuthService: Initialized = $_isInitialized, Authenticated = $_isAuthenticated');
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
      print('Error saving auth state: $e');
    }
  }

  // Real Firebase sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    print('🔐 AuthService: Signing in with email: $email');

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print(
          '🔐 AuthService: Sign in successful for: ${credential.user?.email}');
      await _saveAuthState();

      return credential;
    } catch (e) {
      print('🔐 AuthService: Sign in failed: $e');
      rethrow; // Re-throw the error so the UI can handle it
    }
  }

  // Real Firebase sign up
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    print('🔐 AuthService: Creating user with email: $email');

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print(
          '🔐 AuthService: Sign up successful for: ${credential.user?.email}');
      await _saveAuthState();

      return credential;
    } catch (e) {
      print('🔐 AuthService: Sign up failed: $e');
      rethrow;
    }
  }

  // Real Firebase sign out
  Future<void> signOut() async {
    print('🔐 AuthService: Signing out');

    try {
      await _auth.signOut();
      await _saveAuthState();
      print('🔐 AuthService: Sign out successful');
    } catch (e) {
      print('🔐 AuthService: Sign out failed: $e');
      rethrow;
    }
  }

  // Real Firebase password reset
  Future<void> sendPasswordResetEmail({required String email}) async {
    print('🔐 AuthService: Sending password reset email to: $email');

    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('🔐 AuthService: Password reset email sent successfully');
    } catch (e) {
      print('🔐 AuthService: Password reset email failed: $e');
      rethrow;
    }
  }

  // Check if user has admin privileges
  Future<bool> isAdmin() async {
    if (!_isAuthenticated || _currentUser == null) {
      return false;
    }

    try {
      // Get the ID token to check custom claims
      final token = await _currentUser!.getIdTokenResult();
      final claims = token.claims;

      // Check for admin custom claim
      final isAdmin = claims?['admin'] == true;
      print('🔐 AuthService: Admin check for ${_currentUser!.email}: $isAdmin');

      return isAdmin;
    } catch (e) {
      print('🔐 AuthService: Error checking admin status: $e');
      return false;
    }
  }
}
