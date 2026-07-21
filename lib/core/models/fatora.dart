import 'package:naji/core/models/enum_status.dart';

import 'base_model.dart';

enum InvoiceType {
  sale,
  purchase;

  String get value => name;

  static InvoiceType fromString(String value) {
    return InvoiceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InvoiceType.sale,
    );
  }
}

class Fatora extends BaseModel {
  final String userUnified;
  final String writer;
  final int date;
  final InvoiceType type;
  final double total;
  final String? note;

  const Fatora({
    super.id,
    required super.unified,
    required this.userUnified,
    required this.writer,
    required this.date,
    required this.type,
    required this.total,
    this.note,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.deviceId,
    required super.status,
  });

  Fatora copyWith({
    int? id,
    String? unified,
    String? userUnified,
    String? writer,
    int? date,
    InvoiceType? type,
    double? total,
    String? note,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
    String? deviceId,
    int? syncVersion,
    Status? status,
  }) {
    return Fatora(
      id: id ?? this.id,
      unified: unified ?? this.unified,
      userUnified: userUnified ?? this.userUnified,
      writer: writer ?? this.writer,
      date: date ?? this.date,
      type: type ?? this.type,
      total: total ?? this.total,
      note: note ?? this.note,
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
      "writer": writer,
      "date": date,
      "type": type.value,
      "total": total,
      "note": note,
    };
  }

  factory Fatora.fromMap(Map<String, dynamic> map) {
    return Fatora(
      id: map["id"] as int?,
      unified: map["unified"] as String,
      userUnified: map["userUnified"] as String,
      writer: map["writer"] as String,
      date: map["date"] as int,
      type: InvoiceType.fromString(map["type"] as String),
      total: (map["total"] as num).toDouble(),
      note: map["note"] as String?,
      createdAt: map["createdAt"] as int,
      updatedAt: map["updatedAt"] as int,
      deletedAt: map["deletedAt"] as int?,
      deviceId: map["deviceId"] as String,
      status: Status.values.byName(map["status"] as String),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Fatora.fromJson(Map<String, dynamic> json) {
    return Fatora.fromMap(json);
  }
}
