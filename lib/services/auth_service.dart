import 'package:flutter/foundation.dart';

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

  MockUser? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  // Initialize with no authenticated user for proper security
  AuthService() {
    _currentUser = null;
    _isAuthenticated = false;
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

    return MockUserCredential(user: _currentUser!);
  }

  // Mock sign out
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
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
