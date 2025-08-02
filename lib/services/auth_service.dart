import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // User profile data
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? get userProfile => _userProfile;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  // Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String fullName,
    String? company,
    String? phone,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create user profile in Firestore
      await _createUserProfile(
        userCredential.user!.uid,
        email: email,
        fullName: fullName,
        company: company,
        phone: phone,
      );

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _userProfile = null;
    notifyListeners();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile(
    String uid, {
    required String email,
    required String fullName,
    String? company,
    String? phone,
  }) async {
    final userData = {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'company': company,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'subscriptionStatus': 'free', // free, basic, premium
      'subscriptionExpiry': null,
      'stripeCustomerId': null,
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(uid).set(userData);
    _userProfile = userData;
  }

  // Load user profile from Firestore
  Future<void> _loadUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        _userProfile = doc.data() as Map<String, dynamic>;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? fullName,
    String? company,
    String? phone,
  }) async {
    if (currentUser == null) return;

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (fullName != null) updates['fullName'] = fullName;
    if (company != null) updates['company'] = company;
    if (phone != null) updates['phone'] = phone;

    await _firestore.collection('users').doc(currentUser!.uid).update(updates);
    await _loadUserProfile(currentUser!.uid);
  }

  // Update subscription status
  Future<void> updateSubscriptionStatus({
    required String status,
    DateTime? expiryDate,
    String? stripeCustomerId,
  }) async {
    if (currentUser == null) return;

    final updates = <String, dynamic>{
      'subscriptionStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (expiryDate != null) updates['subscriptionExpiry'] = expiryDate;
    if (stripeCustomerId != null)
      updates['stripeCustomerId'] = stripeCustomerId;

    await _firestore.collection('users').doc(currentUser!.uid).update(updates);
    await _loadUserProfile(currentUser!.uid);
  }

  // Handle authentication errors
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        default:
          return 'Authentication failed. Please try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  // Check if user has active subscription
  bool get hasActiveSubscription {
    if (_userProfile == null) return false;

    final status = _userProfile!['subscriptionStatus'] as String?;
    final expiry = _userProfile!['subscriptionExpiry'] as Timestamp?;

    if (status == 'free') return true; // Free tier is always active

    if (expiry != null) {
      return DateTime.now().isBefore(expiry.toDate());
    }

    return false;
  }

  // Get subscription status
  String get subscriptionStatus {
    return _userProfile?['subscriptionStatus'] ?? 'free';
  }

  // Get subscription expiry date
  DateTime? get subscriptionExpiry {
    final expiry = _userProfile?['subscriptionExpiry'] as Timestamp?;
    return expiry?.toDate();
  }
}
