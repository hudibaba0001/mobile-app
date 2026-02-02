/// Abstract authentication service interface
/// Implementations should provide authentication functionality
abstract class AuthService {
  /// Get current user ID (null if not authenticated)
  String? get currentUserId;

  /// Get current user email (null if not authenticated)
  String? get currentUserEmail;

  /// Sign out the current user
  Future<void> signOut();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Check if user is authenticated
  bool get isAuthenticated;

  /// Check if service is initialized
  bool get isInitialized;

  /// Check if user is admin (optional, can throw if not implemented)
  Future<bool> isAdmin();
}

