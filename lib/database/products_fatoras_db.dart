import '../models/fatora_product.dart';
import 'database_helper.dart';

class FatoraProductsDB {
  final db = DatabaseHelper.instance;

  Future<int> insert(FatoraProduct item) async {
    final database = await db.database;
    return database.insert("fatora_products", item.toMap());
  }

  Future<List<FatoraProduct>> getByFatora(String unified) async {
    final database = await db.database;

    final result = await database.query(
      "fatora_products",
      where: "fatoraUnified=? AND isDeleted=0",
      whereArgs: [unified],
    );

    return result.map((e) => FatoraProduct.fromMap(e)).toList();
  }

  Future<int> update(FatoraProduct item) async {
    final database = await db.database;

    return database.update(
      "fatora_products",
      item.toMap(),
      where: "unified=?",
      whereArgs: [item.unified],
    );
  }

  Future<int> delete(String unified) async {
    final database = await db.database;

    return database.update(
      "fatora_products",
      {"isDeleted": 1, "updatedAt": DateTime.now().toIso8601String()},
      where: "unified=?",
      whereArgs: [unified],
    );
  }

  Future<FatoraProduct?> get(String unified) async {
    final database = await db.database;

    final result = await database.query(
      "fatora_products",
      where: "unified=?",
      whereArgs: [unified],
    );

    if (result.isEmpty) return null;

    return FatoraProduct.fromMap(result.first);
  }

  Future<List<FatoraProduct>> getAll() async {
    final database = await db.database;

    final result = await database.query(
      "fatora_products",
      where: "isDeleted=0",
      orderBy: "date DESC",
    );

    return result.map((e) => FatoraProduct.fromMap(e)).toList();
  }
}
