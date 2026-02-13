class UserEntitlement {
  final String userId;
  final String provider;
  final String? productId;
  final String? purchaseToken;
  final String status;
  final DateTime? currentPeriodEnd;
  final DateTime? updatedAt;

  const UserEntitlement({
    required this.userId,
    required this.provider,
    required this.status,
    this.productId,
    this.purchaseToken,
    this.currentPeriodEnd,
    this.updatedAt,
  });

  bool get hasAccess => status == 'active' || status == 'grace';

  bool get isPending => status == 'pending_subscription';

  factory UserEntitlement.fromMap(Map<String, dynamic> map) {
    return UserEntitlement(
      userId: map['user_id'] as String,
      provider: (map['provider'] as String?) ?? 'google_play',
      productId: map['product_id'] as String?,
      purchaseToken: map['purchase_token'] as String?,
      status: (map['status'] as String?) ?? 'pending_subscription',
      currentPeriodEnd: map['current_period_end'] != null
          ? DateTime.parse(map['current_period_end'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
