import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../database/user_db.dart';
import '../database/product_db.dart';
import '../database/fatora_db.dart';
import '../database/payment_db.dart';
import '../database/products_fatoras_db.dart';

import '../models/user.dart';
import '../models/product.dart';
import '../models/fatora.dart';
import '../models/payment.dart';
import '../models/fatora_product.dart';

class ImportService {
  final UserDB _userDB = UserDB();
  final ProductDB _productDB = ProductDB();
  final FatoraDB _fatoraDB = FatoraDB();
  final PaymentDB _paymentDB = PaymentDB();
  final FatoraProductsDB _fatoraProductsDB = FatoraProductsDB();

  /// Import a JSON backup file and upsert records.
  /// Returns a map with counts of processed records.
  Future<Map<String, int>> importJson(File file) async {
    final content = await file.readAsString();
    final Map<String, dynamic> data = json.decode(content) as Map<String, dynamic>;

    var usersCount = 0;
    var productsCount = 0;
    var fatorasCount = 0;
    var paymentsCount = 0;
    var fatoraProductsCount = 0;

    // USERS
    final users = (data['users'] ?? []) as List<dynamic>;
    for (final u in users) {
      try {
        final map = Map<String, dynamic>.from(u as Map);
        final user = User.fromJson(map);
        final existing = await _userDB.get(user.unified);
        if (existing == null) {
          await _userDB.insert(user, null);
        } else {
          await _userDB.update(user, null);
        }
        usersCount++;
      } catch (_) {
        // skip malformed
      }
    }

    // PRODUCTS
    final products = (data['products'] ?? []) as List<dynamic>;
    for (final p in products) {
      try {
        final map = Map<String, dynamic>.from(p as Map);
        final product = Product.fromJson(map);
        final existing = await _productDB.get(product.unified);
        if (existing == null) {
          await _productDB.insert(product);
        } else {
          await _productDB.update(product, null);
        }
        productsCount++;
      } catch (_) {}
    }

    // FATORAS
    final fatoras = (data['fatoras'] ?? []) as List<dynamic>;
    for (final f in fatoras) {
      try {
        final map = Map<String, dynamic>.from(f as Map);
        final item = Fatora.fromJson(map);
        final existing = await _fatoraDB.get(item.unified);
        if (existing == null) {
          await _fatoraDB.insert(item);
        } else {
          await _fatoraDB.update(item, null);
        }
        fatorasCount++;
      } catch (_) {}
    }

    // PAYMENTS
    final payments = (data['payments'] ?? []) as List<dynamic>;
    for (final p in payments) {
      try {
        final map = Map<String, dynamic>.from(p as Map);
        final item = Payment.fromJson(map);
        final existing = await _paymentDB.get(item.unified);
        if (existing == null) {
          await _paymentDB.insert(item);
        } else {
          await _paymentDB.update(item, null);
        }
        paymentsCount++;
      } catch (_) {}
    }

    // FATORA PRODUCTS
    final fatoraProducts = (data['fatoraProducts'] ?? []) as List<dynamic>;
    for (final p in fatoraProducts) {
      try {
        final map = Map<String, dynamic>.from(p as Map);
        final item = FatoraProduct.fromJson(map);
        final existing = await _fatoraProductsDB.get(item.unified);
        if (existing == null) {
          await _fatoraProductsDB.insert(item);
        } else {
          await _fatoraProductsDB.update(item, null);
        }
        fatoraProductsCount++;
      } catch (_) {}
    }

    return {
      'users': usersCount,
      'products': productsCount,
      'fatoras': fatorasCount,
      'payments': paymentsCount,
      'fatoraProducts': fatoraProductsCount,
    };
  }

  /// Import first JSON file inside a ZIP archive.
  Future<Map<String, int>> importZip(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      if (file.isFile && file.name.toLowerCase().endsWith('.json')) {
        final tmpDir = await getTemporaryDirectory();
        final outPath = join(tmpDir.path, file.name);
        final outFile = File(outPath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
        final result = await importJson(outFile);
        await outFile.delete().catchError((_) {});
        return result;
      }
    }

    return {
      'users': 0,
      'products': 0,
      'fatoras': 0,
      'payments': 0,
      'fatoraProducts': 0,
    };
  }

  /// Replace the app database file with the provided sqlite file.
  /// Closes the current database and copies the given file into place.
  Future<void> importDatabase(File sourceDbFile) async {
    await DatabaseHelper.instance.close();
    await DatabaseHelper.instance.deleteDatabaseFile();

    final dbPath = await getDatabasesPath();
    final dest = File(join(dbPath, DatabaseHelper.databaseName));

    await dest.create(recursive: true);
    await sourceDbFile.copy(dest.path);
  }
}
