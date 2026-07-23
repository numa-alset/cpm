import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:naji/core/database/fatora_db.dart';
import 'package:naji/core/database/payment_db.dart';
import 'package:naji/core/database/product_db.dart';
import 'package:naji/core/database/products_fatoras_db.dart';
import 'package:naji/core/database/user_db.dart';
import 'package:naji/core/services/transaction_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/fatora_product.dart';

class BackupService {
  static final String backupFolderName = "naji_backup";

  final UserDB _userDB = UserDB();
  final ProductDB _productDB = ProductDB();
  final FatoraDB _fatoraDB = FatoraDB();
  final PaymentDB _paymentDB = PaymentDB();
  final FatoraProductsDB _fatoraProductsDB = FatoraProductsDB();
  final TransactionService _transactionService = TransactionService();

  /// Export everything to JSON
  Future<File> exportJson() async {
    final dir = await getApplicationDocumentsDirectory();

    final file = File(
      join(
        dir.path,
        '${backupFolderName}_${DateTime.now().millisecondsSinceEpoch}.json',
      ),
    );

    // Use a DB transaction to take a consistent snapshot of all tables

    final backup = await _transactionService.runTransaction((txn) async {
      final users = (await _userDB.getAll(txn)).map((e) => e.toMap()).toList();

      final products = (await _productDB.getAll(
        txn,
      )).map((e) => e.toMap()).toList();

      final fatoras = (await _fatoraDB.getAll(
        txn,
      )).map((e) => e.toMap()).toList();

      final payments = (await _paymentDB.getAll(
        txn,
      )).map((e) => e.toMap()).toList();

      // fatora_products DB helper does not expose a txn-aware getAll, query directly on txn
      final fpResult = await txn.query(
        'fatora_products',
        where: 'deletedAt IS NULL',
        orderBy: 'date DESC',
      );

      final fatoraProducts = fpResult
          .map((e) => FatoraProduct.fromMap(e).toMap())
          .toList();

      return {
        "createdAt": DateTime.now().toIso8601String(),
        "version": 1,

        "users": users,
        "products": products,
        "fatoras": fatoras,
        "payments": payments,
        "fatoraProducts": fatoraProducts,
      };
    });

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
      join(
        dir.path,
        '${backupFolderName}_${DateTime.now().millisecondsSinceEpoch}.zip',
      ),
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
      join(
        dir.path,
        '${backupFolderName}_database_${DateTime.now().millisecondsSinceEpoch}.db',
      ),
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

    final backup = await _transactionService.runTransaction((txn) async {
      final users = (await _userDB.getUnsynced(
        txn,
      )).map((e) => e.toMap()).toList();

      final products = (await _productDB.getUnsynced(
        txn,
      )).map((e) => e.toMap()).toList();

      final fatoras = (await _fatoraDB.getUnsynced(
        txn,
      )).map((e) => e.toMap()).toList();

      final payments = (await _paymentDB.getUnsynced(
        txn,
      )).map((e) => e.toMap()).toList();

      final fatoraProducts = (await _fatoraProductsDB.getUnsynced(
        txn,
      )).map((e) => e.toMap()).toList();

      return {
        "createdAt": DateTime.now().toIso8601String(),
        "version": 1,

        "users": users,
        "products": products,
        "fatoras": fatoras,
        "payments": payments,
        "fatoraProducts": fatoraProducts,
      };
    });

    await file.writeAsString(
      const JsonEncoder.withIndent("  ").convert(backup),
    );

    return file;
  }

  /// Export a single selected record by unified identifier and type
  Future<File> exportSingleRecord({
    required String type,
    required String unified,
  }) async {
    final dir = await getApplicationDocumentsDirectory();

    final file = File(
      join(
        dir.path,
        '${backupFolderName}_${type}_$unified'
        '_${DateTime.now().millisecondsSinceEpoch}.json',
      ),
    );

    final backup = await _transactionService.runTransaction((txn) async {
      final result = <String, dynamic>{
        "createdAt": DateTime.now().toIso8601String(),
        "version": 1,
        "users": <dynamic>[],
        "products": <dynamic>[],
        "fatoras": <dynamic>[],
        "payments": <dynamic>[],
        "fatoraProducts": <dynamic>[],
      };

      switch (type.toLowerCase()) {
        case 'user':
        case 'users':
          final user = await _userDB.get(unified, txn);
          if (user != null) {
            result["users"] = [user.toMap()];
          }
          break;

        case 'product':
        case 'products':
          final product = await _productDB.get(unified, txn);
          if (product != null) {
            result["products"] = [product.toMap()];
          }
          break;

        case 'fatora':
        case 'fatoras':
        case 'invoice':
          final fatora = await _fatoraDB.get(unified, txn);
          if (fatora != null) {
            result["fatoras"] = [fatora.toMap()];
          }
          break;

        case 'payment':
        case 'payments':
          final payment = await _paymentDB.get(unified, txn);
          if (payment != null) {
            result["payments"] = [payment.toMap()];
          }
          break;

        case 'fatoraproduct':
        case 'fatora_products':
        case 'fatoraproducts':
          final fp = await _fatoraProductsDB.get(unified, txn);
          if (fp != null) {
            result["fatoraProducts"] = [fp.toMap()];
          }
          break;
      }

      return result;
    });

    await file.writeAsString(
      const JsonEncoder.withIndent("  ").convert(backup),
    );

    return file;
  }
}
