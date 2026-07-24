import 'package:sqflite/sqflite.dart';

import '../models/payment.dart';
import 'database_helper.dart';

class PaymentDB {
  final db = DatabaseHelper.instance;

  Future<int> insert(Payment payment, Transaction txn) async {
    final database = txn;
    return database.insert("payments", payment.toMap());
  }

  Future<List<Payment>> getAll(Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "payments",
      where: "deletedAt IS NULL",
      orderBy: "updatedAt DESC",
    );

    return result.map((e) => Payment.fromMap(e)).toList();
  }

  Future<int> update(Payment payment, Transaction txn) async {
    final database = txn;

    return database.update(
      "payments",
      payment.toMap(),
      where: "unified=?",
      whereArgs: [payment.unified],
    );
  }

  Future<int> delete(String unified, Transaction txn) async {
    final database = txn;

    return database.update(
      "payments",
      {
        "deletedAt": DateTime.now().millisecondsSinceEpoch,
        "updatedAt": DateTime.now().millisecondsSinceEpoch,
      },
      where: "unified=?",
      whereArgs: [unified],
    );
  }

  Future<Payment?> get(String unified, Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "payments",
      where: "unified=?",
      whereArgs: [unified],
    );

    if (result.isEmpty) return null;

    return Payment.fromMap(result.first);
  }

  Future<List<Payment>> getUnsynced(Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "payments",
      where: "status=?",
      whereArgs: ["notScheduled"],
      orderBy: "updatedAt DESC",
    );

    return result.map((e) => Payment.fromMap(e)).toList();
  }
}
