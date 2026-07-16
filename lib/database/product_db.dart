import 'package:sqflite/sqflite.dart';

import '../models/product.dart';
import 'database_helper.dart';

class ProductDB {
  final db = DatabaseHelper.instance;

  Future<int> insert(Product product, {Transaction? txn}) async {
    final database = txn ?? await db.database;
    return database.insert("products", product.toMap());
  }

  Future<List<Product>> getAll({Transaction? txn}) async {
    final database = txn ?? await db.database;

    final result = await database.query(
      "products",
      where: "isDeleted=0",
      orderBy: "name",
    );

    return result.map((e) => Product.fromMap(e)).toList();
  }

  Future<int> update(Product product, Transaction? txn) async {
    final database = txn ?? await db.database;

    return database.update(
      "products",
      product.toMap(),
      where: "unified=?",
      whereArgs: [product.unified],
    );
  }

  Future<int> delete(String unified, Transaction? txn) async {
    final database = txn ?? await db.database;

    return database.update(
      "products",
      {"isDeleted": 1, "updatedAt": DateTime.now().toIso8601String()},
      where: "unified=?",
      whereArgs: [unified],
    );
  }

  Future<Product?> get(String unified) async {
    final database = await db.database;

    final result = await database.query(
      "products",
      where: "unified=?",
      whereArgs: [unified],
    );

    if (result.isEmpty) return null;

    return Product.fromMap(result.first);
  }
}
