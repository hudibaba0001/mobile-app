/// External links configuration
/// Replace these URLs with your actual production URLs
class ExternalLinks {
  /// Base URL for the web app (update this for production)
  static const String _baseUrl = 'https://your-domain.com';

  /// URL for user signup/registration page
  static const String signupUrl = '$_baseUrl/signup';

  /// URL for managing subscription (Stripe customer portal via web app)
  static const String manageSubscriptionUrl = '$_baseUrl/account';

  /// URL for Terms of Service
  static const String termsUrl = '$_baseUrl/terms';

  /// URL for Privacy Policy
  static const String privacyUrl = '$_baseUrl/privacy';
}

