import 'base_model.dart';

class Product extends BaseModel {
  final String name;
  final double price;

  const Product({
    super.id,
    required super.unified,
    required this.name,
    required this.price,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.deviceId,
    required super.syncVersion,
  });

  Product copyWith({
    int? id,
    String? unified,
    String? name,
    double? price,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    String? deviceId,
    int? syncVersion,
  }) {
    return Product(
      id: id ?? this.id,
      unified: unified ?? this.unified,
      name: name ?? this.name,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      syncVersion: syncVersion ?? this.syncVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {...baseMap(), "name": name, "price": price};
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map["id"] as int?,
      unified: map["unified"] as String,
      name: map["name"] as String,
      price: (map["price"] as num).toDouble(),
      createdAt: map["createdAt"] as int,
      updatedAt: map["updatedAt"] as int,
      deletedAt: map["deletedAt"] as int?,
      deviceId: map["deviceId"] as String,
      syncVersion: map["syncVersion"] as int,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product.fromMap(json);
  }
}
