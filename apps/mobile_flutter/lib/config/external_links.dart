/// External links configuration
/// Replace these URLs with your actual production URLs
class ExternalLinks {
  /// Base URL for the web app
  static const String _baseUrl = 'https://app.kviktime.se';

  /// URL for user signup/registration page
  static const String signupUrl = 'https://app.kviktime.se/signup';

  /// URL for managing subscription (Stripe customer portal via web app)
  static const String manageSubscriptionUrl = '$_baseUrl/account';

  /// URL for Terms of Service
  static const String termsUrl = '$_baseUrl/terms';

  /// URL for Privacy Policy
  static const String privacyUrl = '$_baseUrl/privacy';

  /// URL for password reset (web-based)
  static const String resetPasswordUrl = '$_baseUrl/reset-password';
}
