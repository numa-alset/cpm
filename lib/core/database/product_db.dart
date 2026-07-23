import 'package:sqflite/sqflite.dart';

import '../models/product.dart';
import 'database_helper.dart';

class ProductDB {
  final db = DatabaseHelper.instance;

  Future<int> insert(Product product, Transaction txn) async {
    final database = txn;
    return database.insert("products", product.toMap());
  }

  Future<List<Product>> getAll(Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "products",
      where: "deletedAt IS NULL",
      orderBy: "name",
    );

    return result.map((e) => Product.fromMap(e)).toList();
  }

  Future<int> update(Product product, Transaction txn) async {
    final database = txn;

    return database.update(
      "products",
      product.toMap(),
      where: "unified=?",
      whereArgs: [product.unified],
    );
  }

  Future<int> delete(String unified, Transaction txn) async {
    final database = txn ?? await db.database;

    return database.update(
      "products",
      {
        "deletedAt": DateTime.now().millisecondsSinceEpoch,
        "updatedAt": DateTime.now().millisecondsSinceEpoch,
      },
      where: "unified=?",
      whereArgs: [unified],
    );
  }

  Future<Product?> get(String unified, Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "products",
      where: "unified=?",
      whereArgs: [unified],
    );

    if (result.isEmpty) return null;

    return Product.fromMap(result.first);
  }

  Future<List<Product>> getUnsynced(Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "products",
      where: "status=?",
      whereArgs: ["notScheduled"],
      orderBy: "updatedAt DESC",
    );

    return result.map((e) => Product.fromMap(e)).toList();
  }
}
