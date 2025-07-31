import 'package:flutter/foundation.dart';

/// Dummy authentication service for testing purposes
/// This bypasses Firebase Auth and creates fake user sessions
class DummyAuthService extends ChangeNotifier {
  static const String _dummyUserId = 'dummy_user_123';
  static const String _dummyUserEmail = 'test@example.com';
  static const String _dummyUserName = 'Test User';

  bool _isAuthenticated = false;
  DummyUser? _currentUser;

  /// Check if user is currently authenticated
  bool get isAuthenticated => _isAuthenticated;

  /// Get current dummy user
  DummyUser? get currentUser => _currentUser;

  /// Get current user ID for database operations
  String get currentUserId => _currentUser?.id ?? _dummyUserId;

  /// Initialize dummy auth - auto-login for testing
  Future<void> initialize() async {
    // Auto-login with dummy user for testing
    await signInWithDummyAccount();
  }

  /// Sign in with dummy account
  Future<bool> signInWithDummyAccount() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      _currentUser = DummyUser(
        id: _dummyUserId,
        email: _dummyUserEmail,
        name: _dummyUserName,
        isVerified: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      _isAuthenticated = true;
      notifyListeners();

      if (kDebugMode) {
        print('🔐 Dummy Auth: Signed in as ${_currentUser!.name}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('🔐 Dummy Auth Error: $e');
      }
      return false;
    }
  }

  /// Sign out dummy user
  Future<void> signOut() async {
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();

    if (kDebugMode) {
      print('🔐 Dummy Auth: Signed out');
    }
  }

  /// Create additional dummy users for testing
  Future<bool> signInWithTestUser(String testUserType) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      switch (testUserType) {
        case 'premium':
          _currentUser = DummyUser(
            id: 'premium_user_456',
            email: 'premium@example.com',
            name: 'Premium User',
            isVerified: true,
            subscriptionTier: 'premium',
            createdAt: DateTime.now().subtract(const Duration(days: 60)),
          );
          break;
        case 'pro':
          _currentUser = DummyUser(
            id: 'pro_user_789',
            email: 'pro@example.com',
            name: 'Pro User',
            isVerified: true,
            subscriptionTier: 'pro',
            createdAt: DateTime.now().subtract(const Duration(days: 90)),
          );
          break;
        default:
          return await signInWithDummyAccount();
      }

      _isAuthenticated = true;
      notifyListeners();

      if (kDebugMode) {
        print(
          '🔐 Dummy Auth: Signed in as ${_currentUser!.name} (${_currentUser!.subscriptionTier})',
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('🔐 Dummy Auth Error: $e');
      }
      return false;
    }
  }

  /// Check if user has premium features
  bool get hasPremiumFeatures =>
      _currentUser?.subscriptionTier == 'premium' ||
      _currentUser?.subscriptionTier == 'pro';

  /// Check if user has pro features
  bool get hasProFeatures => _currentUser?.subscriptionTier == 'pro';
}

/// Dummy user model for testing
class DummyUser {
  final String id;
  final String email;
  final String name;
  final bool isVerified;
  final String subscriptionTier;
  final DateTime createdAt;

  DummyUser({
    required this.id,
    required this.email,
    required this.name,
    this.isVerified = false,
    this.subscriptionTier = 'free',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'isVerified': isVerified,
      'subscriptionTier': subscriptionTier,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'DummyUser(name: $name, email: $email, tier: $subscriptionTier)';
  }
}
