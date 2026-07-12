import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), "naji.db");

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE users(
id INTEGER PRIMARY KEY AUTOINCREMENT,
unified TEXT UNIQUE,
name TEXT,
location TEXT,
total REAL,
type TEXT,
createdAt TEXT,
updatedAt TEXT,
isDeleted INTEGER DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE products(
id INTEGER PRIMARY KEY AUTOINCREMENT,
unified TEXT UNIQUE,
name TEXT,
createdAt TEXT,
updatedAt TEXT,
isDeleted INTEGER DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE fatoras(
id INTEGER PRIMARY KEY AUTOINCREMENT,
unified TEXT UNIQUE,
userUnified TEXT,
writer TEXT,
date TEXT,
total REAL,
type TEXT,
createdAt TEXT,
updatedAt TEXT,
isDeleted INTEGER DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE fatora_products(
id INTEGER PRIMARY KEY AUTOINCREMENT,
unified TEXT UNIQUE,
fatoraUnified TEXT,
productUnified TEXT,
name TEXT,
price REAL,
amount REAL,
createdAt TEXT,
updatedAt TEXT,
isDeleted INTEGER DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE payments(
id INTEGER PRIMARY KEY AUTOINCREMENT,
unified TEXT UNIQUE,
userUnified TEXT,
username TEXT,
amount REAL,
date TEXT,
createdAt TEXT,
updatedAt TEXT,
isDeleted INTEGER DEFAULT 0
)
''');
  }
}
