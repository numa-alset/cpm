import 'package:sqflite/sqflite.dart';

import '../models/payment.dart';
import 'database_helper.dart';

class PaymentDB {
  final db = DatabaseHelper.instance;

  Future<int> insert(Payment payment, {Transaction? txn}) async {
    final database = txn ?? await db.database;
    return database.insert("payments", payment.toMap());
  }

  Future<List<Payment>> getAll({Transaction? txn}) async {
    final database = txn ?? await db.database;

    final result = await database.query(
      "payments",
      where: "isDeleted=0",
      orderBy: "date DESC",
    );

    return result.map((e) => Payment.fromMap(e)).toList();
  }

  Future<int> update(Payment payment, Transaction? txn) async {
    final database = txn ?? await db.database;

    return database.update(
      "payments",
      payment.toMap(),
      where: "unified=?",
      whereArgs: [payment.unified],
    );
  }

  Future<int> delete(String unified, Transaction? txn) async {
    final database = txn ?? await db.database;

    return database.update(
      "payments",
      {"isDeleted": 1, "updatedAt": DateTime.now().toIso8601String()},
      where: "unified=?",
      whereArgs: [unified],
    );
  }

  Future<Payment?> get(String unified) async {
    final database = await db.database;

    final result = await database.query(
      "payments",
      where: "unified=?",
      whereArgs: [unified],
    );

    if (result.isEmpty) return null;

    return Payment.fromMap(result.first);
  }
}
