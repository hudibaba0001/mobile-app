import 'package:firebase_auth/firebase_auth.dart';

/// Service class for handling Firebase Authentication operations
/// Provides methods for user sign-in, sign-up, sign-out, and auth state monitoring
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream that emits the current user authentication state
  /// Returns null when user is signed out, User object when signed in
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get the currently signed-in user
  /// Returns null if no user is signed in
  User? get currentUser => _auth.currentUser;

  /// Sign in an existing user with email and password
  /// 
  /// [email] - User's email address
  /// [password] - User's password
  /// 
  /// Returns [UserCredential] on successful sign-in
  /// Throws [FirebaseAuthException] on authentication errors
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Create a new user account with email and password
  /// 
  /// [email] - User's email address
  /// [password] - User's password (should meet security requirements)
  /// 
  /// Returns [UserCredential] on successful account creation
  /// Throws [FirebaseAuthException] on authentication errors
  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send a password reset email to the specified email address
  /// 
  /// [email] - The email address to send the reset link to
  /// 
  /// Throws [FirebaseAuthException] on authentication errors
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out the current user
  /// 
  /// Clears the authentication state and returns user to signed-out state
  /// Throws [FirebaseAuthException] on sign-out errors
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send a password reset email to the specified email address
  /// 
  /// [email] - Email address to send password reset link to
  /// 
  /// Throws [FirebaseAuthException] if email is not found or invalid
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Handle Firebase Auth exceptions and provide user-friendly error messages
  /// 
  /// [e] - The FirebaseAuthException to handle
  /// 
  /// Returns a new Exception with a user-friendly message
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email address.';
        break;
      case 'wrong-password':
        message = 'Incorrect password provided.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists with this email address.';
        break;
      case 'weak-password':
        message = 'Password is too weak. Please choose a stronger password.';
        break;
      case 'invalid-email':
        message = 'Invalid email address format.';
        break;
      case 'user-disabled':
        message = 'This user account has been disabled.';
        break;
      case 'too-many-requests':
        message = 'Too many failed attempts. Please try again later.';
        break;
      default:
        message = 'Authentication failed: ${e.message}';
    }
    return Exception(message);
  }
}
