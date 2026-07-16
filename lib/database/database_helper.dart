import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, "naji.db");

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
    total REAL NOT NULL DEFAULT 0,

    type TEXT NOT NULL,

    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    deletedAt INTEGER,

    deviceId TEXT NOT NULL,
    syncVersion INTEGER NOT NULL DEFAULT 1,
    status TEXT NOT NULL
);
""");

    //
    // PRODUCTS
    //
    await db.execute("""
CREATE TABLE products(
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    unified TEXT NOT NULL UNIQUE,

    name TEXT NOT NULL,

    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    deletedAt INTEGER,

    deviceId TEXT NOT NULL,
    syncVersion INTEGER NOT NULL DEFAULT 1,
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

    total REAL NOT NULL,

    type TEXT NOT NULL,

    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    deletedAt INTEGER,

    deviceId TEXT NOT NULL,
    syncVersion INTEGER NOT NULL DEFAULT 1,
    status TEXT NOT NULL,

    FOREIGN KEY(userUnified)
    REFERENCES users(unified)
);
""");

    //
    // FATORA PRODUCTS
    //
    await db.execute("""
CREATE TABLE fatora_products(
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    unified TEXT NOT NULL UNIQUE,

    fatoraUnified TEXT NOT NULL,

    productUnified TEXT NOT NULL,

    name TEXT NOT NULL,
    
    status TEXT NOT NULL,

    price REAL NOT NULL,

    amount REAL NOT NULL,

    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    deletedAt INTEGER,

    deviceId TEXT NOT NULL,
    syncVersion INTEGER NOT NULL DEFAULT 1,

    FOREIGN KEY(fatoraUnified)
    REFERENCES fatoras(unified),

    FOREIGN KEY(productUnified)
    REFERENCES products(unified)
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

    date INTEGER NOT NULL,
    
    status TEXT NOT NULL,

    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL,
    deletedAt INTEGER,

    deviceId TEXT NOT NULL,
    syncVersion INTEGER NOT NULL DEFAULT 1,

    FOREIGN KEY(userUnified)
    REFERENCES users(unified)
);
""");

    //
    // INDEXES
    //

    // USERS
    await db.execute("CREATE INDEX idx_users_unified ON users(unified);");

    await db.execute("CREATE INDEX idx_users_type ON users(type);");

    // PRODUCTS
    await db.execute("CREATE INDEX idx_products_unified ON products(unified);");

    // FATORAS
    await db.execute("CREATE INDEX idx_fatora_unified ON fatoras(unified);");

    await db.execute("CREATE INDEX idx_fatora_user ON fatoras(userUnified);");

    await db.execute("CREATE INDEX idx_fatora_date ON fatoras(date);");

    // FATORA PRODUCTS
    await db.execute(
      "CREATE INDEX idx_fp_unified ON fatora_products(unified);",
    );

    await db.execute(
      "CREATE INDEX idx_fp_fatora ON fatora_products(fatoraUnified);",
    );

    await db.execute(
      "CREATE INDEX idx_fp_product ON fatora_products(productUnified);",
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
