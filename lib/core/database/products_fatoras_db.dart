import 'package:sqflite/sqflite.dart';

import '../models/fatora_product.dart';
import 'database_helper.dart';

class FatoraProductsDB {
  final db = DatabaseHelper.instance;

  Future<int> insert(FatoraProduct item, Transaction txn) async {
    final database = txn;
    return database.insert("fatora_products", item.toMap());
  }

  Future<List<FatoraProduct>> getByFatora(
    String unified,
    Transaction txn,
  ) async {
    final database = txn;

    final result = await database.query(
      "fatora_products",
      where: "fatoraUnified=? AND deletedAt IS NULL",
      whereArgs: [unified],
    );

    return result.map((e) => FatoraProduct.fromMap(e)).toList();
  }

  Future<int> update(FatoraProduct item, Transaction txn) async {
    final database = txn;

    return database.update(
      "fatora_products",
      item.toMap(),
      where: "unified=?",
      whereArgs: [item.unified],
    );
  }

  Future<int> delete(String unified, Transaction txn) async {
    final database = txn;

    return database.update(
      "fatora_products",
      {
        "deletedAt": DateTime.now().millisecondsSinceEpoch,
        "updatedAt": DateTime.now().millisecondsSinceEpoch,
      },
      where: "unified=?",
      whereArgs: [unified],
    );
  }

  Future<FatoraProduct?> get(String unified, Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "fatora_products",
      where: "unified=?",
      whereArgs: [unified],
    );

    if (result.isEmpty) return null;

    return FatoraProduct.fromMap(result.first);
  }

  Future<List<FatoraProduct>> getAll(Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "fatora_products",
      where: "deletedAt IS NULL",
      orderBy: "date DESC",
    );

    return result.map((e) => FatoraProduct.fromMap(e)).toList();
  }

  Future<List<FatoraProduct>> getUnsynced(Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "fatora_products",
      where: "status=?",
      whereArgs: ["notScheduled"],
      orderBy: "updatedAt DESC",
    );

    return result.map((e) => FatoraProduct.fromMap(e)).toList();
  }
}
