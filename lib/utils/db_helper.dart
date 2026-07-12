import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  static const _tableName = 'operations';
  static const _colId = 'id';
  static const _colDate = 'date';
  static const _colType = 'type'; // "sy" or "mtn"
  static const _colNumber = 'number';
  static const _colAmount = 'amount';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  // Initialize database using sqflite's getDatabasesPath()
  Future<Database> _initDB() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'ta7wel.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName(
            $_colId INTEGER PRIMARY KEY AUTOINCREMENT,
            $_colDate TEXT,
            $_colType TEXT,
            $_colNumber TEXT,
            $_colAmount REAL
          )
        ''');
      },
    );
  }

  // Insert a new operation
  Future<int> insertOperation({
    required String date,
    required String type,
    required String number,
    required int amount,
  }) async {
    final db = await database;
    return await db.insert(_tableName, {
      _colDate: date,
      _colType: type,
      _colNumber: number,
      _colAmount: amount,
    });
  }

  // Get all operations sorted by date desc
  Future<List<Map<String, dynamic>>> getAllOperations() async {
    final db = await database;
    return await db.query(_tableName, orderBy: '$_colDate DESC');
  }

  // 🔹 Get operations by type (e.g. "sy" or "mtn")
  Future<List<Map<String, dynamic>>> getOperationsByType(String type) async {
    final db = await database;
    return await db.query(
      _tableName,
      where: '$_colType = ?',
      whereArgs: [type],
      orderBy: '$_colDate DESC',
    );
  }

  // Delete one operation
  Future<int> deleteOperation(int id) async {
    final db = await database;
    return await db.delete(_tableName, where: '$_colId = ?', whereArgs: [id]);
  }

  // Clear all records
  Future<int> clearAll() async {
    final db = await database;
    return await db.delete(_tableName);
  }

  // Export to JSON file
  Future<File> exportToFile() async {
    final ops = await getAllOperations();
    final databasesPath = await getDatabasesPath();
    final file = File(join(databasesPath, 'ta7wel_export.json'));
    await file.writeAsString(jsonEncode(ops));
    return file;
  }

  // Import from JSON file
  Future<void> importFromFile(File file) async {
    if (!await file.exists()) return;

    final db = await database;
    final jsonStr = await file.readAsString();
    final List<dynamic> data = jsonDecode(jsonStr);

    final batch = db.batch();
    for (var item in data) {
      batch.insert(_tableName, {
        _colDate: item[_colDate],
        _colType: item[_colType],
        _colNumber: item[_colNumber],
        _colAmount: item[_colAmount],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // 🔹 Get record count (optionally filtered by type)
  Future<int> getCount({String? type}) async {
    final db = await database;
    String query = 'SELECT COUNT(*) FROM $_tableName';
    List<Object?>? args;

    if (type != null) {
      query += ' WHERE $_colType = ?';
      args = [type];
    }

    final result = await db.rawQuery(query, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
