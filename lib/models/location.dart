class Location {
  final String id;
  final String name;
  final String address;
  final DateTime createdAt;
  final int usageCount;
  final bool isFavorite;

  const Location({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
    this.usageCount = 0,
    this.isFavorite = false,
  });

  Location copyWith({
    String? id,
    String? name,
    String? address,
    DateTime? createdAt,
    int? usageCount,
    bool? isFavorite,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      usageCount: usageCount ?? this.usageCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'usageCount': usageCount,
      'isFavorite': isFavorite,
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      usageCount: json['usageCount'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}
