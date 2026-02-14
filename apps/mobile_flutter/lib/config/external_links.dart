/// External links configuration
/// Replace these URLs with your actual production URLs
class ExternalLinks {
  /// Base URL for the web app
  static const String _baseUrl = 'https://app.kviktime.se';

  /// URL for user signup/registration page
  static const String signupUrl = 'https://app.kviktime.se/signup';

  /// URL where users land after confirming signup email
  static const String emailVerifiedUrl = '$_baseUrl/email-verified';

  /// URL for managing subscription in Google Play
  static const String manageSubscriptionUrl =
      'https://play.google.com/store/account/subscriptions';

  /// URL for Terms of Service
  static const String termsUrl = 'https://www.kviktime.se/terms-and-conditions/';

  /// URL for Privacy Policy
  static const String privacyUrl = 'https://www.kviktime.se/privacy-policy/';

  /// URL for password reset (web-based)
  static const String resetPasswordUrl = '$_baseUrl/reset-password';

  /// Support email address
  static const String supportEmail = 'support@kviktime.se';
}
