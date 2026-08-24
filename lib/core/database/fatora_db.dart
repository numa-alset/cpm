import 'package:sqflite/sqflite.dart';

import '../models/enum_status.dart';
import '../models/fatora.dart';
import 'database_helper.dart';

class FatoraDB {
  final db = DatabaseHelper.instance;

  Future<int> insert(Fatora fatora, Transaction txn) async {
    final database = txn;
    final now = DateTime.now().millisecondsSinceEpoch;
    return database.insert("fatoras", {
      ...fatora.toMap(),
      "status": Status.notScheduled.value,
      "updatedAt": now,
    });
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
      {
        ...fatora.toMap(),
        "status": Status.notScheduled.value,
        "updatedAt": DateTime.now().millisecondsSinceEpoch,
      },
      where: "unified=?",
      whereArgs: [fatora.unified],
    );
  }

  Future<int> delete(String unified, Transaction txn) async {
    final database = txn;
    final now = DateTime.now().millisecondsSinceEpoch;

    return database.update(
      "fatoras",
      {"deletedAt": now, "updatedAt": now, "status": Status.notScheduled.value},
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
