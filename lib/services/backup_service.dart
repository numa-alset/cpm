import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:naji/database/fatora_db.dart';
import 'package:naji/database/payment_db.dart';
import 'package:naji/database/product_db.dart';
import 'package:naji/database/products_fatoras_db.dart';
import 'package:naji/database/user_db.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class BackupService {
  final UserDB _userDB = UserDB();
  final ProductDB _productDB = ProductDB();
  final FatoraDB _fatoraDB = FatoraDB();
  final PaymentDB _paymentDB = PaymentDB();
  final FatoraProductsDB _fatoraProductsDB = FatoraProductsDB();

  /// Export everything to JSON
  Future<File> exportJson() async {
    final dir = await getApplicationDocumentsDirectory();

    final file = File(
      join(dir.path, 'backup_${DateTime.now().millisecondsSinceEpoch}.json'),
    );

    final backup = {
      "createdAt": DateTime.now().toIso8601String(),
      "version": 1,

      "users": (await _userDB.getAll()).map((e) => e.toMap()).toList(),

      "products": (await _productDB.getAll()).map((e) => e.toMap()).toList(),

      "fatoras": (await _fatoraDB.getAll()).map((e) => e.toMap()).toList(),

      "payments": (await _paymentDB.getAll()).map((e) => e.toMap()).toList(),

      "fatoraProducts": (await _fatoraProductsDB.getAll())
          .map((e) => e.toMap())
          .toList(),
    };

    await file.writeAsString(
      const JsonEncoder.withIndent("  ").convert(backup),
    );

    return file;
  }

  /// Export JSON inside a ZIP
  Future<File> exportZip() async {
    final jsonFile = await exportJson();

    final dir = await getApplicationDocumentsDirectory();

    final zipFile = File(
      join(dir.path, 'backup_${DateTime.now().millisecondsSinceEpoch}.zip'),
    );

    final encoder = ZipFileEncoder();

    encoder.create(zipFile.path);

    encoder.addFile(jsonFile);

    encoder.close();

    return zipFile;
  }

  /// Export the sqlite database itself
  Future<File> exportDatabase() async {
    final dbPath = await getDatabasesPath();

    final source = File(join(dbPath, DatabaseHelper.databaseName));

    final dir = await getApplicationDocumentsDirectory();

    final destination = File(
      join(dir.path, 'database_${DateTime.now().millisecondsSinceEpoch}.db'),
    );

    return source.copy(destination.path);
  }

  /// Share JSON backup
  Future<void> shareBackup() async {
    final file = await exportJson();

    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  /// Export only records that are not synced yet.
  Future<File> exportUnsynced() async {
    final dir = await getApplicationDocumentsDirectory();

    final file = File(
      join(dir.path, 'unsynced_${DateTime.now().millisecondsSinceEpoch}.json'),
    );

    final backup = {
      "createdAt": DateTime.now().toIso8601String(),
      "version": 1,

      "users": (await _userDB.getUnsynced()).map((e) => e.toMap()).toList(),

      "products": (await _productDB.getUnsynced())
          .map((e) => e.toMap())
          .toList(),

      "fatoras": (await _fatoraDB.getUnsynced()).map((e) => e.toMap()).toList(),

      "payments": (await _paymentDB.getUnsynced())
          .map((e) => e.toMap())
          .toList(),

      "fatoraProducts": (await _fatoraProductsDB.getUnsynced())
          .map((e) => e.toMap())
          .toList(),
    };

    await file.writeAsString(
      const JsonEncoder.withIndent("  ").convert(backup),
    );

    return file;
  }
}
