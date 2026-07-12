import 'package:sqflite/sqflite.dart';

import '../models/user.dart';
import 'database_helper.dart';

class UserDB {
  final db = DatabaseHelper.instance;

  Future<int> insert(User user) async {
    final database = await db.database;
    return await database.insert("users", user.toMap());
  }

  Future<List<User>> getAll() async {
    final database = await db.database;

    final result = await database.query(
      "users",
      where: "isDeleted=0",
      orderBy: "name",
    );

    return result.map((e) => User.fromMap(e)).toList();
  }

  Future<User?> get(String unified) async {
    final database = await db.database;

    final result = await database.query(
      "users",
      where: "unified=?",
      whereArgs: [unified],
    );

    if (result.isEmpty) return null;

    return User.fromMap(result.first);
  }

  Future<int> update(User user) async {
    final database = await db.database;

    return await database.update(
      "users",
      user.toMap(),
      where: "unified=?",
      whereArgs: [user.unified],
    );
  }

  Future<int> delete(String unified) async {
    final database = await db.database;

    return await database.update(
      "users",
      {"isDeleted": 1, "updatedAt": DateTime.now().toIso8601String()},
      where: "unified=?",
      whereArgs: [unified],
    );
  }
}
