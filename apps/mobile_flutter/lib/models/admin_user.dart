class AdminUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool disabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? settings;

  AdminUser({
    required this.uid,
    this.email,
    this.displayName,
    required this.disabled,
    required this.createdAt,
    required this.updatedAt,
    this.settings,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      disabled: json['disabled'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'disabled': disabled,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'settings': settings,
  };

  @override
  String toString() =>
      'AdminUser(uid: $uid, email: $email, displayName: $displayName)';
}
