import 'package:naji/core/models/currency.dart';
import 'package:naji/core/models/enum_status.dart';

import 'base_model.dart';

class FatoraProduct extends BaseModel {
  final String fatoraUnified;
  final String productName;
  final double price;
  final double quantity;
  final Currency currency;
  double get total => quantity * price;

  const FatoraProduct({
    super.id,
    required super.unified,
    required this.fatoraUnified,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.currency,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.deviceId,
    required super.status,
  });

  FatoraProduct copyWith({
    int? id,
    String? unified,
    String? fatoraUnified,
    String? productName,
    double? price,
    double? quantity,
    Currency? currency,
    double? total,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    String? deviceId,
    int? syncVersion,
    Status? status,
  }) {
    return FatoraProduct(
      id: id ?? this.id,
      unified: unified ?? this.unified,
      fatoraUnified: fatoraUnified ?? this.fatoraUnified,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      currency: currency ?? this.currency,
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
      "fatoraUnified": fatoraUnified,
      "productName": productName,
      "price": price,
      "quantity": quantity,
      "currency": currency.value,
    };
  }

  factory FatoraProduct.fromMap(Map<String, dynamic> map) {
    return FatoraProduct(
      id: map["id"] as int?,
      unified: map["unified"] as String,
      fatoraUnified: map["fatoraUnified"] as String,
      productName: map["productName"] as String,
      price: (map["price"] as num?)?.toDouble() ?? 0.0,
      quantity: (map["quantity"] as num?)?.toDouble() ?? 0.0,
      currency: Currency.fromString(
        map["currency"] as String? ?? map["currencyCode"] as String? ?? 'SYP',
      ),
      createdAt: map["createdAt"] as int,
      updatedAt: map["updatedAt"] as int,
      deletedAt: map["deletedAt"] as int?,
      deviceId: map["deviceId"] as String,
      status: Status.values.byName(map["status"] as String),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory FatoraProduct.fromJson(Map<String, dynamic> json) {
    return FatoraProduct.fromMap(json);
  }
}
