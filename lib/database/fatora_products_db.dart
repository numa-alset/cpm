import 'package:naji/models/fatora_product.dart';

import 'database_helper.dart';

class FatoraProductsDB {
  final db = DatabaseHelper.instance;

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

  // ...existing code...
}
