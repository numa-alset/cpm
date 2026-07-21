import 'package:naji/core/models/enum_status.dart';

import 'base_model.dart';

class Payment extends BaseModel {
  final String userUnified;
  final double amount;
  final int date;

  const Payment({
    super.id,
    required super.unified,
    required this.userUnified,
    required this.amount,
    required this.date,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.deviceId,
    required super.status,
  });

  Payment copyWith({
    int? id,
    String? unified,
    String? userUnified,
    double? amount,
    int? date,
    String? note,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    String? deviceId,
    int? syncVersion,
    Status? status,
  }) {
    return Payment(
      id: id ?? this.id,
      unified: unified ?? this.unified,
      userUnified: userUnified ?? this.userUnified,
      amount: amount ?? this.amount,
      date: date ?? this.date,
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
      "userUnified": userUnified,
      "amount": amount,
      "date": date,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map["id"] as int?,
      unified: map["unified"] as String,
      userUnified: map["userUnified"] as String,
      amount: (map["amount"] as num).toDouble(),
      date: map["date"] as int,
      createdAt: map["createdAt"] as int,
      updatedAt: map["updatedAt"] as int,
      deletedAt: map["deletedAt"] as int?,
      deviceId: map["deviceId"] as String,
      status: Status.values.byName(map["status"] as String),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment.fromMap(json);
  }
}
