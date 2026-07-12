class Payment {
  final int? id;
  final String unified;
  final String userUnified;
  final String username;
  final double amount;
  final String date;
  final String createdAt;
  final String updatedAt;
  final int isDeleted;

  const Payment({
    this.id,
    required this.unified,
    required this.userUnified,
    required this.username,
    required this.amount,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = 0,
  });

  Payment copyWith({
    int? id,
    String? unified,
    String? userUnified,
    String? username,
    double? amount,
    String? date,
    String? createdAt,
    String? updatedAt,
    int? isDeleted,
  }) {
    return Payment(
      id: id ?? this.id,
      unified: unified ?? this.unified,
      userUnified: userUnified ?? this.userUnified,
      username: username ?? this.username,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unified': unified,
      'userUnified': userUnified,
      'username': username,
      'amount': amount,
      'date': date,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isDeleted': isDeleted,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      unified: map['unified'],
      userUnified: map['userUnified'],
      username: map['username'],
      amount: (map['amount'] ?? 0).toDouble(),
      date: map['date'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      isDeleted: map['isDeleted'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment.fromMap(json);
  }
}
