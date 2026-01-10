/// User profile model from Supabase profiles table
class UserProfile {
  final String id;
  final String? email;
  final String? fullName;
  // Consent timestamps (null means not accepted)
  final DateTime? termsAcceptedAt;
  final DateTime? privacyAcceptedAt;
  final String? termsVersion;
  final String? privacyVersion;
  // Stripe subscription fields
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String? subscriptionStatus; // 'pending', 'trialing', 'active', 'past_due', 'canceled'
  final DateTime? currentPeriodEnd;
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    this.email,
    this.fullName,
    this.termsAcceptedAt,
    this.privacyAcceptedAt,
    this.termsVersion,
    this.privacyVersion,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.subscriptionStatus,
    this.currentPeriodEnd,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if user has accepted both terms and privacy
  bool get hasAcceptedLegal => 
      termsAcceptedAt != null && privacyAcceptedAt != null;

  /// Check if subscription is active (including trialing)
  bool get hasActiveSubscription => 
      subscriptionStatus == 'active' || subscriptionStatus == 'trialing';

  /// Check if user can access the app (has accepted legal AND has active subscription)
  bool get canAccessApp => hasAcceptedLegal && hasActiveSubscription;

  /// Check if subscription is past due (payment failed)
  bool get isSubscriptionPastDue => subscriptionStatus == 'past_due';

  /// Check if subscription is canceled
  bool get isSubscriptionCanceled => subscriptionStatus == 'canceled';

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String?,
      fullName: map['full_name'] as String?,
      termsAcceptedAt: map['terms_accepted_at'] != null
          ? DateTime.parse(map['terms_accepted_at'] as String)
          : null,
      privacyAcceptedAt: map['privacy_accepted_at'] != null
          ? DateTime.parse(map['privacy_accepted_at'] as String)
          : null,
      termsVersion: map['terms_version'] as String?,
      privacyVersion: map['privacy_version'] as String?,
      stripeCustomerId: map['stripe_customer_id'] as String?,
      stripeSubscriptionId: map['stripe_subscription_id'] as String?,
      subscriptionStatus: map['subscription_status'] as String?,
      currentPeriodEnd: map['current_period_end'] != null
          ? DateTime.parse(map['current_period_end'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'terms_accepted_at': termsAcceptedAt?.toIso8601String(),
      'privacy_accepted_at': privacyAcceptedAt?.toIso8601String(),
      'terms_version': termsVersion,
      'privacy_version': privacyVersion,
      'stripe_customer_id': stripeCustomerId,
      'stripe_subscription_id': stripeSubscriptionId,
      'subscription_status': subscriptionStatus,
      'current_period_end': currentPeriodEnd?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, subscription: $subscriptionStatus, hasLegal: $hasAcceptedLegal)';
  }
}

