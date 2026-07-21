import 'package:naji/core/models/enum_status.dart';

import 'base_model.dart';

enum UserType {
  buyer,
  seller;

  String get value => name;

  static UserType fromString(String value) {
    return UserType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserType.buyer,
    );
  }
}

class User extends BaseModel {
  final String name;
  final String location;
  final double total;
  final UserType type;

  const User({
    super.id,
    required super.unified,
    required this.name,
    required this.location,
    required this.total,
    required this.type,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.deviceId,
    required super.status,
  });

  User copyWith({
    int? id,
    String? unified,
    String? name,
    String? location,
    double? total,
    UserType? type,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    String? deviceId,
    int? syncVersion,
    Status? status,
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
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ...baseMap(),
      "name": name,
      "location": location,
      "total": total,
      "type": type.value,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map["id"] as int?,
      unified: map["unified"] as String,
      name: map["name"] as String,
      location: map["location"] as String,
      total: (map["total"] as num).toDouble(),
      type: UserType.fromString(map["type"] as String),
      createdAt: map["createdAt"] as int,
      updatedAt: map["updatedAt"] as int,
      deletedAt: map["deletedAt"] as int?,
      deviceId: map["deviceId"] as String,
      status: Status.values.byName(map["status"] as String),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory User.fromJson(Map<String, dynamic> json) {
    return User.fromMap(json);
  }
}
