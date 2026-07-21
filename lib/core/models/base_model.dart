import 'package:naji/core/models/enum_status.dart';

abstract class BaseModel {
  final int? id;
  final String unified;

  /// millisecondsSinceEpoch
  final int createdAt;

  /// millisecondsSinceEpoch
  final int updatedAt;

  /// null = active
  /// timestamp = deleted
  final int? deletedAt;

  /// Device that last modified this record
  final String deviceId;

  /// Status
  final Status status;

  const BaseModel({
    this.id,
    required this.unified,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.deviceId,
    required this.status,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> baseMap() {
    return {
      if (id != null) "id": id,
      "unified": unified,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
      "deletedAt": deletedAt,
      "deviceId": deviceId,
      "status": status.value,
    };
  }
}
