import 'package:naji/core/models/enum_status.dart';

import 'base_model.dart';

class User extends BaseModel {
  final String name;
  final String location;
  final double totalSy;
  final double totalDollar;

  const User({
    super.id,
    required super.unified,
    required this.name,
    required this.location,
    required this.totalSy,
    required this.totalDollar,
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
    double? totalSy,
    double? totalDollar,
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
      totalSy: totalSy ?? this.totalSy,
      totalDollar: totalDollar ?? this.totalDollar,
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
      "totalSy": totalSy,
      "totalDollar": totalDollar,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map["id"] as int?,
      unified: map["unified"] as String,
      name: map["name"] as String,
      location: map["location"] as String,
      totalSy: (map["totalSy"] as num?)?.toDouble() ?? 0.0,
      totalDollar: (map["totalDollar"] as num?)?.toDouble() ?? 0.0,
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
