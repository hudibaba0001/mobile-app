/// External links configuration
/// Replace these URLs with your actual production URLs
class ExternalLinks {
  /// Base URL for the web app
  static const String _baseUrl = 'https://kvik-time.vercel.app';

  /// URL for user signup/registration page
  static const String signupUrl = '$_baseUrl/signup';

  /// URL for managing subscription (Stripe customer portal via web app)
  static const String manageSubscriptionUrl = '$_baseUrl/account';

  /// URL for Terms of Service
  static const String termsUrl = 'https://kvik-time.vercel.app/terms';

  /// URL for Privacy Policy
  static const String privacyUrl = 'https://kvik-time.vercel.app/privacy';

  /// Current version of Terms of Service
  static const String termsVersion = '1.0.0 (2026-02-01)';

  /// Current version of Privacy Policy
  static const String privacyVersion = '1.0.0 (2026-02-01)';
}

