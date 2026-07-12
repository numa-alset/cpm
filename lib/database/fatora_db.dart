import '../models/fatora.dart';
import 'database_helper.dart';

class FatoraDB {
  final db = DatabaseHelper.instance;

  Future insert(Fatora fatora) async {
    final database = await db.database;
    return database.insert("fatoras", fatora.toMap());
  }

  Future<List<Fatora>> getAll() async {
    final database = await db.database;

    final result = await database.query(
      "fatoras",
      where: "isDeleted=0",
      orderBy: "date DESC",
    );

    return result.map((e) => Fatora.fromMap(e)).toList();
  }

  Future update(Fatora fatora) async {
    final database = await db.database;

    return database.update(
      "fatoras",
      fatora.toMap(),
      where: "unified=?",
      whereArgs: [fatora.unified],
    );
  }

  Future delete(String unified) async {
    final database = await db.database;

    return database.update(
      "fatoras",
      {"isDeleted": 1, "updatedAt": DateTime.now().toIso8601String()},
      where: "unified=?",
      whereArgs: [unified],
    );
  }

  Future<Fatora?> get(String unified) async {
    final database = await db.database;

    final result = await database.query(
      "fatoras",
      where: "unified=?",
      whereArgs: [unified],
    );

    if (result.isEmpty) return null;

    return Fatora.fromMap(result.first);
  }
}
