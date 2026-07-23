import 'package:sqflite/sqflite.dart';

import '../models/user.dart';
import 'database_helper.dart';

class UserDB {
  final db = DatabaseHelper.instance;

  Future<int> insert(User user, Transaction txn) async {
    final database = txn;
    return await database.insert("users", user.toMap());
  }

  Future<List<User>> getAll(Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "users",
      where: "deletedAt IS NULL",
      orderBy: "updatedAt DESC",
    );

    return result.map((e) => User.fromMap(e)).toList();
  }

  Future<User?> get(String unified, Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "users",
      where: "unified=?",
      whereArgs: [unified],
    );

    if (result.isEmpty) return null;

    return User.fromMap(result.first);
  }

  Future<int> update(User user, Transaction txn) async {
    final database = txn;

    return await database.update(
      "users",
      user.toMap(),
      where: "unified=?",
      whereArgs: [user.unified],
    );
  }

  Future<int> delete(String unified, Transaction txn) async {
    final database = txn;
    return await database.update(
      "users",
      {
        "deletedAt": DateTime.now().millisecondsSinceEpoch,
        "updatedAt": DateTime.now().millisecondsSinceEpoch,
      },
      where: "unified=?",
      whereArgs: [unified],
    );
  }

  Future<List<User>> getUnsynced(Transaction txn) async {
    final database = txn;

    final result = await database.query(
      "users",
      where: "status=?",
      whereArgs: ["notScheduled"],
      orderBy: "updatedAt DESC",
    );

    return result.map((e) => User.fromMap(e)).toList();
  }
}
