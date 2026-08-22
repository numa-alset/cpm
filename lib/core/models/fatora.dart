import 'package:naji/core/models/currency.dart';
import 'package:naji/core/models/enum_status.dart';

import 'base_model.dart';

class Fatora extends BaseModel {
  final String userUnified;
  final String writer;
  final int date;
  final double totalSy;
  final double totalDollar;
  final String? note;

  double get total => totalSy + totalDollar;
  Currency get currency => totalDollar > 0 && totalSy == 0
      ? Currency.dollar
      : Currency.sy;

  const Fatora({
    super.id,
    required super.unified,
    required this.userUnified,
    required this.writer,
    required this.date,
    this.totalSy = 0,
    this.totalDollar = 0,
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
    double? totalSy,
    double? totalDollar,
    String? note,
    Currency? currency,
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
      totalSy: totalSy ?? this.totalSy,
      totalDollar: totalDollar ?? this.totalDollar,
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
      "totalSy": totalSy,
      "totalDollar": totalDollar,
      "note": note,
    };
  }

  factory Fatora.fromMap(Map<String, dynamic> map) {
    final legacyTotal = (map["total"] as num?)?.toDouble() ?? 0.0;
    final legacyCurrency = map["currency"] as String?;
    final totalSyValue = (map["totalSy"] as num?)?.toDouble() ??
        (legacyCurrency != null &&
                Currency.fromString(legacyCurrency) == Currency.sy
            ? legacyTotal
            : 0.0);
    final totalDollarValue = (map["totalDollar"] as num?)?.toDouble() ??
        (legacyCurrency != null &&
                Currency.fromString(legacyCurrency) == Currency.dollar
            ? legacyTotal
            : 0.0);

    return Fatora(
      id: map["id"] as int?,
      unified: map["unified"] as String,
      userUnified: map["userUnified"] as String,
      writer: map["writer"] as String,
      date: map["date"] as int,
      totalSy: totalSyValue,
      totalDollar: totalDollarValue,
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
