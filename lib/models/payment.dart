import 'base_model.dart';

enum PaymentMethod {
  cash,
  creditCard,
  bankTransfer;

  String get value => name;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

class Payment extends BaseModel {
  final String userUnified;
  final double amount;
  final int date;
  final PaymentMethod method;
  final String? note;

  const Payment({
    super.id,
    required super.unified,
    required this.userUnified,
    required this.amount,
    required this.date,
    required this.method,
    this.note,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.deviceId,
    required super.syncVersion,
  });

  Payment copyWith({
    int? id,
    String? unified,
    String? userUnified,
    double? amount,
    int? date,
    PaymentMethod? method,
    String? note,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    String? deviceId,
    int? syncVersion,
  }) {
    return Payment(
      id: id ?? this.id,
      unified: unified ?? this.unified,
      userUnified: userUnified ?? this.userUnified,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      method: method ?? this.method,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      syncVersion: syncVersion ?? this.syncVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ...baseMap(),
      "userUnified": userUnified,
      "amount": amount,
      "date": date,
      "method": method.value,
      "note": note,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map["id"] as int?,
      unified: map["unified"] as String,
      userUnified: map["userUnified"] as String,
      amount: (map["amount"] as num).toDouble(),
      date: map["date"] as int,
      method: PaymentMethod.fromString(map["method"] as String),
      note: map["note"] as String?,
      createdAt: map["createdAt"] as int,
      updatedAt: map["updatedAt"] as int,
      deletedAt: map["deletedAt"] as int?,
      deviceId: map["deviceId"] as String,
      syncVersion: map["syncVersion"] as int,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment.fromMap(json);
  }
}
