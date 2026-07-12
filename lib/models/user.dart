class User {
  final int? id;
  final String unified;
  final String name;
  final String location;
  final double total;
  final String type;
  final String createdAt;
  final String updatedAt;
  final int isDeleted;

  const User({
    this.id,
    required this.unified,
    required this.name,
    required this.location,
    required this.total,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = 0,
  });

  User copyWith({
    int? id,
    String? unified,
    String? name,
    String? location,
    double? total,
    String? type,
    String? createdAt,
    String? updatedAt,
    int? isDeleted,
  }) {
    return User(
      id: id ?? this.id,
      unified: unified ?? this.unified,
      name: name ?? this.name,
      location: location ?? this.location,
      total: total ?? this.total,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unified': unified,
      'name': name,
      'location': location,
      'total': total,
      'type': type,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isDeleted': isDeleted,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      unified: map['unified'],
      name: map['name'],
      location: map['location'],
      total: (map['total'] ?? 0).toDouble(),
      type: map['type'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      isDeleted: map['isDeleted'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory User.fromJson(Map<String, dynamic> json) {
    return User.fromMap(json);
  }
}
