import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static final String databaseName = "naji.db";
  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, DatabaseHelper.databaseName);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute("PRAGMA foreign_keys = ON;");
  }

  Future<void> _onCreate(Database db, int version) async {
    //
    // USERS
    //
    await db.execute("""
CREATE TABLE users(
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    unified TEXT NOT NULL UNIQUE,

    name TEXT NOT NULL,
    location TEXT NOT NULL,
    totalSy REAL NOT NULL DEFAULT 0,
    totalDollar REAL NOT NULL DEFAULT 0,

    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    deletedAt INTEGER,

    deviceId TEXT NOT NULL,
    status TEXT NOT NULL
);
""");

   //
   // FATORAS (Invoices)
   //
   await db.execute("""
CREATE TABLE fatoras(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
 
    unified TEXT NOT NULL UNIQUE,
 
    userUnified TEXT NOT NULL,
 
    writer TEXT NOT NULL,
 
    date INTEGER NOT NULL,
 
    totalSy REAL NOT NULL DEFAULT 0,
    totalDollar REAL NOT NULL DEFAULT 0,
  
    note TEXT,
  
    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    deletedAt INTEGER,
  
    deviceId TEXT NOT NULL,
    status TEXT NOT NULL,
  
   FOREIGN KEY(userUnified)
REFERENCES users(unified)
ON UPDATE CASCADE
ON DELETE RESTRICT
);
""");

   //
   // FATORA ITEMS
   //
   await db.execute("""
CREATE TABLE fatora_items(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
 
    unified TEXT NOT NULL UNIQUE,
 
    fatoraUnified TEXT NOT NULL,
 
    productName TEXT NOT NULL,
 
    price REAL NOT NULL,
 
    quantity REAL NOT NULL,
 
    currency TEXT NOT NULL,
 
    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    deletedAt INTEGER,
 
    deviceId TEXT NOT NULL,
    status TEXT NOT NULL,
 
    FOREIGN KEY(fatoraUnified)
    REFERENCES fatoras(unified)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);
""");

    //
    // PAYMENTS
    //
    await db.execute("""
CREATE TABLE payments(
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    unified TEXT NOT NULL UNIQUE,

    userUnified TEXT NOT NULL,

    amount REAL NOT NULL,

    currency TEXT NOT NULL,

    date INTEGER NOT NULL,
    
    status TEXT NOT NULL,

    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    deletedAt INTEGER,

    deviceId TEXT NOT NULL,

    FOREIGN KEY(userUnified)
REFERENCES users(unified)
ON UPDATE CASCADE
ON DELETE RESTRICT
);
""");

    //
    // INDEXES
    //

    // USERS
    await db.execute("CREATE INDEX idx_users_unified ON users(unified);");

    // FATORAS
    await db.execute("CREATE INDEX idx_fatora_unified ON fatoras(unified);");
    await db.execute("CREATE INDEX idx_fatoras_user ON fatoras(userUnified);");
    await db.execute("CREATE INDEX idx_fatoras_date ON fatoras(date);");

    // FATORA ITEMS
    await db.execute(
      "CREATE INDEX idx_fatora_items_unified ON fatora_items(unified);",
    );

    await db.execute(
      "CREATE INDEX idx_fatora_items_fatora ON fatora_items(fatoraUnified);",
    );

    // PAYMENTS
    await db.execute("CREATE INDEX idx_payment_unified ON payments(unified);");

    await db.execute("CREATE INDEX idx_payment_user ON payments(userUnified);");

    await db.execute("CREATE INDEX idx_payment_date ON payments(date);");
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  Future<void> deleteDatabaseFile() async {
    final path = join(await getDatabasesPath(), "naji.db");
    await deleteDatabase(path);
    _database = null;
  }
}
