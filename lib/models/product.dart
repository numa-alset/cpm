class Product {
  final int? id;
  final String unified;
  final String name;
  final String createdAt;
  final String updatedAt;
  final int isDeleted;

  const Product({
    this.id,
    required this.unified,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = 0,
  });

  Product copyWith({
    int? id,
    String? unified,
    String? name,
    String? createdAt,
    String? updatedAt,
    int? isDeleted,
  }) {
    return Product(
      id: id ?? this.id,
      unified: unified ?? this.unified,
      name: name ?? this.name,
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
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isDeleted': isDeleted,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      unified: map['unified'],
      name: map['name'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      isDeleted: map['isDeleted'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product.fromMap(json);
  }
}
