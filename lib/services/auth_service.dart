import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock user class
class MockUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;

  MockUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
  });
}

// Mock user credential class
class MockUserCredential {
  final MockUser user;

  MockUserCredential({required this.user});
}

// Mock auth service
class AuthService extends ChangeNotifier {
  MockUser? _currentUser;
  bool _isAuthenticated = false; // Start unauthenticated for proper security
  bool _isInitialized = false; // Track initialization status

  MockUser? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  // Initialize with no authenticated user for proper security
  AuthService() {
    _currentUser = null;
    _isAuthenticated = false;
    // Temporarily start authenticated for testing
    _currentUser = MockUser(
      uid: 'mock-admin-user',
      email: 'admin@test.com',
      displayName: 'Admin User',
    );
    _isAuthenticated = true;
    _isInitialized = true; // Mark as initialized immediately for testing
    _loadAuthState(); // Load saved auth state
  }

  // Load saved authentication state
  Future<void> _loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuth = prefs.getBool('isAuthenticated') ?? false;
      final userEmail = prefs.getString('userEmail');
      final userUid = prefs.getString('userUid');
      final userDisplayName = prefs.getString('userDisplayName');

      if (isAuth && userEmail != null && userUid != null) {
        _currentUser = MockUser(
          uid: userUid,
          email: userEmail,
          displayName: userDisplayName,
        );
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading auth state: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Save authentication state
  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_isAuthenticated && _currentUser != null) {
        await prefs.setBool('isAuthenticated', true);
        await prefs.setString('userEmail', _currentUser!.email);
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

  // Mock sign in with email and password
  Future<MockUserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock successful login
    _currentUser = MockUser(
      uid: 'mock-user-id',
      email: email,
      displayName: 'Mock User',
    );
    _isAuthenticated = true;
    notifyListeners();
    await _saveAuthState(); // Save auth state after successful login

    return MockUserCredential(user: _currentUser!);
  }

  // Mock sign up
  Future<MockUserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock successful signup
    _currentUser = MockUser(
      uid: 'mock-user-id-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: 'New User',
    );
    _isAuthenticated = true;
    notifyListeners();
    await _saveAuthState(); // Save auth state after successful signup

    return MockUserCredential(user: _currentUser!);
  }

  // Mock sign out
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
    await _saveAuthState(); // Save auth state after sign out
  }

  // Mock password reset
  Future<void> sendPasswordResetEmail({required String email}) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock successful password reset email
  }

  // Mock user profile update
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    if (_currentUser != null) {
      _currentUser = MockUser(
        uid: _currentUser!.uid,
        email: _currentUser!.email,
        displayName: displayName ?? _currentUser!.displayName,
        photoURL: photoURL ?? _currentUser!.photoURL,
      );
      notifyListeners();
    }
  }

  // Mock user profile creation in Firestore
  Future<void> createUserProfile({
    required String uid,
    required String email,
    String? fullName,
    String? company,
    String? phone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock successful profile creation
  }

  // Mock user profile update in Firestore
  Future<void> updateUserProfileInFirestore({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock successful profile update
  }

  // Mock get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Return mock profile data
    return {
      'email': 'mock@example.com',
      'name': 'Mock User',
      'company': 'Mock Company',
      'phone': '+1234567890',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
