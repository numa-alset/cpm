import 'package:sqflite/sqflite.dart';

import '../models/fatora.dart';
import 'database_helper.dart';

class FatoraDB {
  final db = DatabaseHelper.instance;

  Future<int> insert(Fatora fatora, {Transaction? txn}) async {
    final database = txn ?? await db.database;
    return database.insert("fatoras", fatora.toMap());
  }

  Future<List<Fatora>> getAll({Transaction? txn}) async {
    final database = txn ?? await db.database;

    final result = await database.query(
      "fatoras",
      where: "isDeleted=0",
      orderBy: "date DESC",
    );

    return result.map((e) => Fatora.fromMap(e)).toList();
  }

  Future<int> update(Fatora fatora, Transaction? txn) async {
    final database = txn ?? await db.database;

    return database.update(
      "fatoras",
      fatora.toMap(),
      where: "unified=?",
      whereArgs: [fatora.unified],
    );
  }

  Future<int> delete(String unified, Transaction? txn) async {
    final database = txn ?? await db.database;

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

  Future<List<Fatora>> getUnsynced({Transaction? txn}) async {
    final database = txn ?? await db.database;

    final result = await database.query(
      "fatoras",
      where: "status=?",
      whereArgs: ["notScheduled"],
      orderBy: "updatedAt DESC",
    );

    return result.map((e) => Fatora.fromMap(e)).toList();
  }
}
