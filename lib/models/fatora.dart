class Fatora {
  final int? id;
  final String unified;
  final String userUnified;
  final String writer;
  final String date;
  final double total;
  final String type;
  final String createdAt;
  final String updatedAt;
  final int isDeleted;

  const Fatora({
    this.id,
    required this.unified,
    required this.userUnified,
    required this.writer,
    required this.date,
    required this.total,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = 0,
  });

  Fatora copyWith({
    int? id,
    String? unified,
    String? userUnified,
    String? writer,
    String? date,
    double? total,
    String? type,
    String? createdAt,
    String? updatedAt,
    int? isDeleted,
  }) {
    return Fatora(
      id: id ?? this.id,
      unified: unified ?? this.unified,
      userUnified: userUnified ?? this.userUnified,
      writer: writer ?? this.writer,
      date: date ?? this.date,
      total: total ?? this.total,
      type: type ?? this.type,
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
      'writer': writer,
      'date': date,
      'total': total,
      'type': type,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isDeleted': isDeleted,
    };
  }

  factory Fatora.fromMap(Map<String, dynamic> map) {
    return Fatora(
      id: map['id'],
      unified: map['unified'],
      userUnified: map['userUnified'],
      writer: map['writer'],
      date: map['date'],
      total: (map['total'] ?? 0).toDouble(),
      type: map['type'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      isDeleted: map['isDeleted'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Fatora.fromJson(Map<String, dynamic> json) {
    return Fatora.fromMap(json);
  }
}
