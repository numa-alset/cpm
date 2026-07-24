import 'package:sqflite/sqflite.dart';

import '../models/fatora.dart';
import 'database_helper.dart';

class FatoraDB {
  final db = DatabaseHelper.instance;

  Future<int> insert(Fatora fatora, Transaction txn) async {
    final database = txn;
    return database.insert("fatoras", fatora.toMap());
  }

  Future<List<Fatora>> getAll(Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "fatoras",
      where: "deletedAt IS NULL",
      orderBy: "updatedAt DESC",
    );

    return result.map((e) => Fatora.fromMap(e)).toList();
  }

  Future<int> update(Fatora fatora, Transaction txn) async {
    final database = txn;

    return database.update(
      "fatoras",
      fatora.toMap(),
      where: "unified=?",
      whereArgs: [fatora.unified],
    );
  }

  Future<int> delete(String unified, Transaction txn) async {
    final database = txn;

    return database.update(
      "fatoras",
      {
        "deletedAt": DateTime.now().millisecondsSinceEpoch,
        "updatedAt": DateTime.now().millisecondsSinceEpoch,
      },
      where: "unified=?",
      whereArgs: [unified],
    );
  }

  Future<Fatora?> get(String unified, Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "fatoras",
      where: "unified=?",
      whereArgs: [unified],
    );

    if (result.isEmpty) return null;

    return Fatora.fromMap(result.first);
  }

  Future<List<Fatora>> getUnsynced(Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "fatoras",
      where: "status=?",
      whereArgs: ["notScheduled"],
      orderBy: "updatedAt DESC",
    );

    return result.map((e) => Fatora.fromMap(e)).toList();
  }
}
