import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Mock User class for when Firebase Auth is not available
class MockUser {
  final String? uid;
  final String? email;
  final String? displayName;

  MockUser({this.uid, this.email, this.displayName});

  // Mock method to simulate Firebase Auth getIdToken
  Future<String> getIdToken() async {
    return 'mock-token-${DateTime.now().millisecondsSinceEpoch}';
  }
}

// Mock UserCredential class
class MockUserCredential {
  final MockUser? user;
  MockUserCredential({this.user});
}

// Auth service with mock implementation for web
class AuthService extends ChangeNotifier {
  MockUser? _currentUser;
  bool _isAuthenticated = false;
  bool _isInitialized = false;

  MockUser? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  AuthService() {
    _currentUser = null;
    _isAuthenticated = false;
    _isInitialized = false;
  }

  // Initialize the auth service
  Future<void> initialize() async {
    await _loadAuthState();
  }

  // Load saved authentication state
  Future<void> _loadAuthState() async {
    try {
      print('🔐 AuthService: Loading auth state...');

      // Mock implementation - start unauthenticated
      _currentUser = null;
      _isAuthenticated = false;

      print('🔐 AuthService: No authenticated user found');
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
        await prefs.setString('userUid', _currentUser!.uid ?? '');
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

  // Mock sign in with email and password
  Future<MockUserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    print('🔐 AuthService: Signing in with email: $email');

    // SECURITY: Only allow specific test credentials
    if (email == 'admin@test.com' && password == 'password123') {
      print('🔐 AuthService: Valid test credentials accepted');
      _currentUser = MockUser(
        uid: 'mock-admin-uid',
        email: email,
        displayName: 'Test Admin User',
      );
      _isAuthenticated = true;
      await _saveAuthState();
      notifyListeners();
      return MockUserCredential(user: _currentUser);
    } else {
      print('🔐 AuthService: Invalid credentials rejected');
      throw Exception('Invalid email or password');
    }
  }

  // Mock sign up
  Future<MockUserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    print('🔐 AuthService: Creating user with email: $email');

    // SECURITY: Only allow specific test user creation
    if (email == 'test@example.com' && password == 'testpass123') {
      print('🔐 AuthService: Valid test user creation accepted');
      _currentUser = MockUser(
        uid: 'mock-test-uid',
        email: email,
        displayName: 'Test User',
      );
      _isAuthenticated = true;
      await _saveAuthState();
      notifyListeners();
      return MockUserCredential(user: _currentUser);
    } else {
      print('🔐 AuthService: User creation rejected');
      throw Exception('User creation not allowed with these credentials');
    }
  }

  // Mock sign out
  Future<void> signOut() async {
    print('🔐 AuthService: Signing out');

    // Mock implementation
    print('🔐 AuthService: Using mock signout');
    _currentUser = null;
    _isAuthenticated = false;
    await _saveAuthState();
    notifyListeners();
  }

  // Mock password reset
  Future<void> sendPasswordResetEmail({required String email}) async {
    print('🔐 AuthService: Sending password reset email to: $email');

    // Mock implementation
    print('🔐 AuthService: Mock password reset email sent successfully');
  }

  // Mock admin check
  Future<bool> isAdmin() async {
    if (!_isAuthenticated || _currentUser == null) {
      return false;
    }

    // Mock implementation - return true for testing
    print('🔐 AuthService: Mock admin check for ${_currentUser!.email}: true');
    return true;
  }

  // Mock profile update
  Future<void> updateUserProfile({String? displayName}) async {
    // Mock implementation
    print('🔐 AuthService: Using mock profile update');
    if (_currentUser != null && displayName != null) {
      _currentUser = MockUser(
        uid: _currentUser!.uid,
        email: _currentUser!.email,
        displayName: displayName,
      );
      await _saveAuthState();
      notifyListeners();
    }
  }
}
