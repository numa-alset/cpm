import 'package:sqflite/sqflite.dart';

import '../models/enum_status.dart';
import '../models/user.dart';
import 'database_helper.dart';

class UserDB {
  final db = DatabaseHelper.instance;

  Future<int> insert(User user, Transaction txn) async {
    final database = txn;
    final now = DateTime.now().millisecondsSinceEpoch;
    return await database.insert("users", {...user.toMap(), "updatedAt": now});
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
      {
        ...user.toMap(),
        "status": Status.notScheduled.value,
        "updatedAt": DateTime.now().millisecondsSinceEpoch,
      },
      where: "unified=?",
      whereArgs: [user.unified],
    );
  }

  Future<int> delete(String unified, Transaction txn) async {
    final database = txn;
    final now = DateTime.now().millisecondsSinceEpoch;
    return await database.update(
      "users",
      {"deletedAt": now, "updatedAt": now, "status": Status.notScheduled.value},
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
