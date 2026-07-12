class FatoraProduct {
  final int? id;
  final String unified;
  final String fatoraUnified;
  final String productUnified;
  final String name;
  final double price;
  final double amount;
  final String createdAt;
  final String updatedAt;
  final int isDeleted;

  const FatoraProduct({
    this.id,
    required this.unified,
    required this.fatoraUnified,
    required this.productUnified,
    required this.name,
    required this.price,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = 0,
  });

  FatoraProduct copyWith({
    int? id,
    String? unified,
    String? fatoraUnified,
    String? productUnified,
    String? name,
    double? price,
    double? amount,
    String? createdAt,
    String? updatedAt,
    int? isDeleted,
  }) {
    return FatoraProduct(
      id: id ?? this.id,
      unified: unified ?? this.unified,
      fatoraUnified: fatoraUnified ?? this.fatoraUnified,
      productUnified: productUnified ?? this.productUnified,
      name: name ?? this.name,
      price: price ?? this.price,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unified': unified,
      'fatoraUnified': fatoraUnified,
      'productUnified': productUnified,
      'name': name,
      'price': price,
      'amount': amount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isDeleted': isDeleted,
    };
  }

  factory FatoraProduct.fromMap(Map<String, dynamic> map) {
    return FatoraProduct(
      id: map['id'],
      unified: map['unified'],
      fatoraUnified: map['fatoraUnified'],
      productUnified: map['productUnified'],
      name: map['name'],
      price: (map['price'] ?? 0).toDouble(),
      amount: (map['amount'] ?? 0).toDouble(),
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      isDeleted: map['isDeleted'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory FatoraProduct.fromJson(Map<String, dynamic> json) {
    return FatoraProduct.fromMap(json);
  }
}
