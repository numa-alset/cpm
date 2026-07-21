import 'package:naji/core/models/enum_status.dart';

import 'base_model.dart';

class FatoraProduct extends BaseModel {
  final String fatoraUnified;
  final String productUnified;
  final String productName;
  final double price;
  final double quantity;
  double get total => quantity * price;

  const FatoraProduct({
    super.id,
    required super.unified,
    required this.fatoraUnified,
    required this.productUnified,
    required this.productName,
    required this.price,
    required this.quantity,
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
    String? productUnified,
    String? productName,
    double? price,
    double? quantity,
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
      productUnified: productUnified ?? this.productUnified,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
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
      "productUnified": productUnified,
      "productName": productName,
      "price": price,
      "quantity": quantity,
    };
  }

  factory FatoraProduct.fromMap(Map<String, dynamic> map) {
    return FatoraProduct(
      id: map["id"] as int?,
      unified: map["unified"] as String,
      fatoraUnified: map["fatoraUnified"] as String,
      productUnified: map["productUnified"] as String,
      productName: map["productName"] as String,
      price: (map["price"] as num).toDouble(),
      quantity: (map["quantity"] as num).toDouble(),
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
