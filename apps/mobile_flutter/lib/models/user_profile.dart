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
  final String?
      subscriptionStatus; // 'pending', 'trialing', 'active', 'past_due', 'canceled'
  final DateTime? currentPeriodEnd;
  // Contract settings (synced to cloud)
  final int contractPercent;
  final int fullTimeHours;
  final DateTime? trackingStartDate;
  final int openingFlexMinutes;
  final DateTime? setupCompletedAt;
  final String employerMode;
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
    this.contractPercent = 100,
    this.fullTimeHours = 40,
    this.trackingStartDate,
    this.openingFlexMinutes = 0,
    this.setupCompletedAt,
    this.employerMode = 'standard',
    this.createdAt,
    this.updatedAt,
  });

  /// Check if user has accepted both terms and privacy policy
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
      contractPercent: map['contract_percent'] as int? ?? 100,
      fullTimeHours: map['full_time_hours'] as int? ?? 40,
      trackingStartDate: map['tracking_start_date'] != null
          ? DateTime.parse(map['tracking_start_date'] as String)
          : null,
      openingFlexMinutes: map['opening_flex_minutes'] as int? ?? 0,
      setupCompletedAt: map['setup_completed_at'] != null
          ? DateTime.parse(map['setup_completed_at'] as String)
          : null,
      employerMode: map['employer_mode'] as String? ?? 'standard',
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
      'contract_percent': contractPercent,
      'full_time_hours': fullTimeHours,
      'tracking_start_date': trackingStartDate != null
          ? '${trackingStartDate!.year}-${trackingStartDate!.month.toString().padLeft(2, '0')}-${trackingStartDate!.day.toString().padLeft(2, '0')}'
          : null,
      'opening_flex_minutes': openingFlexMinutes,
      'setup_completed_at': setupCompletedAt?.toUtc().toIso8601String(),
      'employer_mode': employerMode,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, subscription: $subscriptionStatus, hasLegal: $hasAcceptedLegal)';
  }
}
