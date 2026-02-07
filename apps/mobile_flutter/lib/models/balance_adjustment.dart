/// Model representing a balance adjustment entry
///
/// Adjustments shift the running balance by +/- minutes without changing
/// worked hours, scheduled hours, or credits. Used for manager corrections
/// or manual balance fixes.
class BalanceAdjustment {
  final String? id;
  final String userId;
  final DateTime effectiveDate;
  final int deltaMinutes; // Signed: positive = credit, negative = deficit
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BalanceAdjustment({
    this.id,
    required this.userId,
    required this.effectiveDate,
    required this.deltaMinutes,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from Supabase row
  factory BalanceAdjustment.fromMap(Map<String, dynamic> map) {
    final dateStr = map['effective_date'] as String;
    final dateParts = dateStr.split('-');
    final effectiveDate = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );

    return BalanceAdjustment(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      effectiveDate: effectiveDate,
      deltaMinutes: map['delta_minutes'] as int,
      note: map['note'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert to map for Supabase insert/update
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'effective_date': '${effectiveDate.year}-'
          '${effectiveDate.month.toString().padLeft(2, '0')}-'
          '${effectiveDate.day.toString().padLeft(2, '0')}',
      'delta_minutes': deltaMinutes,
      'note': note,
    };
  }

  /// Whether this is a positive adjustment (credit)
  bool get isCredit => deltaMinutes >= 0;

  /// Formatted delta string (e.g., "+2h 30m" or "−1h 15m")
  String get deltaFormatted {
    final isNegative = deltaMinutes < 0;
    final absMinutes = deltaMinutes.abs();
    final hours = absMinutes ~/ 60;
    final mins = absMinutes % 60;

    final sign = isNegative ? '−' : '+';
    if (mins == 0) {
      return '$sign${hours}h';
    }
    return '$sign${hours}h ${mins}m';
  }

  /// Copy with new values
  BalanceAdjustment copyWith({
    String? id,
    String? userId,
    DateTime? effectiveDate,
    int? deltaMinutes,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BalanceAdjustment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      deltaMinutes: deltaMinutes ?? this.deltaMinutes,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'BalanceAdjustment(${effectiveDate.year}-${effectiveDate.month}-${effectiveDate.day}, '
        '$deltaFormatted, note: $note)';
  }
}
