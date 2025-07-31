import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Helper service for registering users in Firebase
/// This is a simple utility to create real Firebase accounts
class FirebaseRegistrationHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Register a new user with email and password
  static Future<UserRegistrationResult> registerUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      if (kDebugMode) {
        print('🔥 Firebase Registration: Creating account for $email');
      }

      // Create user with Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user == null) {
        return UserRegistrationResult(
          success: false,
          error: 'Failed to create user account',
        );
      }

      // Update display name
      await user.updateDisplayName(displayName);

      // Send email verification
      await user.sendEmailVerification();

      // Create user profile in Firestore
      await _createUserProfile(user, displayName);

      if (kDebugMode) {
        print('✅ Firebase Registration: Account created successfully');
        print('   User ID: ${user.uid}');
        print('   Email: ${user.email}');
        print('   Display Name: $displayName');
        print('   Email Verified: ${user.emailVerified}');
      }

      return UserRegistrationResult(
        success: true,
        user: user,
        message:
            'Account created successfully! Please check your email for verification.',
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e.code);

      if (kDebugMode) {
        print('❌ Firebase Registration Error: ${e.code} - $errorMessage');
      }

      return UserRegistrationResult(
        success: false,
        error: errorMessage,
        errorCode: e.code,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Registration Unexpected Error: $e');
      }

      return UserRegistrationResult(
        success: false,
        error: 'An unexpected error occurred: $e',
      );
    }
  }

  /// Create user profile document in Firestore
  static Future<void> _createUserProfile(User user, String displayName) async {
    final userDoc = _firestore.collection('users').doc(user.uid);

    await userDoc.set({
      'profile': {
        'email': user.email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isEmailVerified': user.emailVerified,
      },
      'subscription': {
        'tier': 'free',
        'status': 'active',
        'usageCount': 0,
        'usageLimit': 50,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'preferences': {
        'theme': 'system',
        'notifications': true,
        'autoSync': true,
      },
    });

    if (kDebugMode) {
      print('📄 Created user profile in Firestore');
    }
  }

  /// Convert Firebase error codes to user-friendly messages
  static String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Registration failed: $errorCode';
    }
  }

  /// Quick registration with predefined test accounts
  static Future<UserRegistrationResult> registerTestAccount({
    required String accountType, // 'free', 'premium', 'pro'
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final email = '${accountType}_user_$timestamp@example.com';
    final password = 'TestPassword123!';
    final displayName = '${accountType.toUpperCase()} Test User';

    return await registerUser(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  /// Get current authenticated user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Sign in with existing credentials
  static Future<UserRegistrationResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      return UserRegistrationResult(
        success: true,
        user: userCredential.user,
        message: 'Signed in successfully!',
      );
    } on FirebaseAuthException catch (e) {
      return UserRegistrationResult(
        success: false,
        error: _getFirebaseErrorMessage(e.code),
        errorCode: e.code,
      );
    }
  }
}

/// Result class for user registration operations
class UserRegistrationResult {
  final bool success;
  final User? user;
  final String? message;
  final String? error;
  final String? errorCode;

  UserRegistrationResult({
    required this.success,
    this.user,
    this.message,
    this.error,
    this.errorCode,
  });

  @override
  String toString() {
    if (success) {
      return 'Success: $message (User: ${user?.email})';
    } else {
      return 'Error: $error${errorCode != null ? ' ($errorCode)' : ''}';
    }
  }
}
