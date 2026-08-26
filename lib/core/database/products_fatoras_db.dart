import 'package:naji/core/models/enum_status.dart';
import 'package:sqflite/sqflite.dart';

import '../models/fatora_product.dart';
import 'database_helper.dart';

class FatoraProductsDB {
  final db = DatabaseHelper.instance;

  Future<int> insert(FatoraProduct item, Transaction txn) async {
    final database = txn;
    final now = DateTime.now().millisecondsSinceEpoch;
    return database.insert("fatora_items", {...item.toMap(), "updatedAt": now});
  }

  Future<List<FatoraProduct>> getByFatora(
    String unified,
    Transaction txn,
  ) async {
    final database = txn;

    final result = await database.query(
      "fatora_items",
      where: "fatoraUnified=? AND deletedAt IS NULL",
      whereArgs: [unified],
    );

    return result.map((e) => FatoraProduct.fromMap(e)).toList();
  }

  Future<int> update(FatoraProduct item, Transaction txn) async {
    final database = txn;

    return database.update(
      "fatora_items",
      {...item.toMap(), "updatedAt": DateTime.now().millisecondsSinceEpoch},
      where: "unified=?",
      whereArgs: [item.unified],
    );
  }

  Future<int> delete(String unified, Transaction txn) async {
    final database = txn;
    final now = DateTime.now().millisecondsSinceEpoch;

    return database.update(
      "fatora_items",
      {"deletedAt": now, "updatedAt": now},
      where: "unified=?",
      whereArgs: [unified],
    );
  }

  Future<FatoraProduct?> get(String unified, Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "fatora_items",
      where: "unified=?",
      whereArgs: [unified],
    );

    if (result.isEmpty) return null;

    return FatoraProduct.fromMap(result.first);
  }

  Future<List<FatoraProduct>> getAll(Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "fatora_items",
      where: "deletedAt IS NULL",
      orderBy: "updatedAt DESC",
    );

    return result.map((e) => FatoraProduct.fromMap(e)).toList();
  }

  Future<List<FatoraProduct>> getUnsynced(Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "fatora_items",
      where: "status=?",
      whereArgs: ["notScheduled"],
      orderBy: "updatedAt DESC",
    );

    return result.map((e) => FatoraProduct.fromMap(e)).toList();
  }

  Future<int> markSync(String unified, Transaction txn) async {
    final database = txn;

    return database.update(
      "fatora_items",
      {"status": Status.scheduled.value},
      where: "unified=?",
      whereArgs: [unified],
    );
  }
}
