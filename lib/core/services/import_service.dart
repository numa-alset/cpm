import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:naji/core/database/database_helper.dart';
import 'package:naji/core/database/fatora_db.dart';
import 'package:naji/core/database/payment_db.dart';
import 'package:naji/core/database/products_fatoras_db.dart';
import 'package:naji/core/database/user_db.dart';
import 'package:naji/core/models/fatora.dart';
import 'package:naji/core/models/fatora_product.dart';
import 'package:naji/core/models/payment.dart';
import 'package:naji/core/models/user.dart';
import 'package:naji/core/services/transaction_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class ImportService {
  static const String backupFormat = 'naji_backup';

  static const int supportedBackupVersion = 1;

  final UserDB _userDB = UserDB();
  final FatoraDB _fatoraDB = FatoraDB();
  final PaymentDB _paymentDB = PaymentDB();
  final FatoraProductsDB _fatoraProductsDB = FatoraProductsDB();

  final TransactionService _transactionService = TransactionService();

  //
  // ------------------------------------------------------------
  // IMPORT JSON
  // ------------------------------------------------------------
  //

  Future<ImportResult> importJson(File file) async {
    if (!await file.exists()) {
      throw FileSystemException('Backup file does not exist.', file.path);
    }

    final content = await file.readAsString();

    final decoded = json.decode(content);

    if (decoded is! Map) {
      throw const FormatException('Invalid backup format.');
    }

    final data = Map<String, dynamic>.from(decoded);

    _validateBackup(data);

    //
    // Parse everything BEFORE starting the DB transaction.
    //
    // This means malformed records don't result in a partially
    // modified database.
    //
    final parsedUsers = _parseUsers(data['users']);
    final parsedFatoras = _parseFatoras(data['fatoras']);
    final parsedPayments = _parsePayments(data['payments']);
    final parsedFatoraProducts = _parseFatoraProducts(data['fatoraProducts']);

    //
    // Actual merge.
    //
    final result = await _transactionService.runTransaction((txn) async {
      var users = 0;
      var fatoras = 0;
      var payments = 0;
      var fatoraProducts = 0;

      //
      // USERS
      //
      for (final user in parsedUsers) {
        final existing = await _userDB.get(user.unified, txn);

        if (existing == null) {
          await _userDB.insert(user, txn);
          users++;
        } else if (user.updatedAt > existing.updatedAt) {
          await _userDB.update(user, txn);
          users++;
        }
      }

      //
      // FATORAS
      //
      for (final fatora in parsedFatoras) {
        final existing = await _fatoraDB.get(fatora.unified, txn);

        if (existing == null) {
          await _fatoraDB.insert(fatora, txn);
          fatoras++;
        } else if (fatora.updatedAt > existing.updatedAt) {
          await _fatoraDB.update(fatora, txn);
          fatoras++;
        }
      }

      //
      // PAYMENTS
      //
      for (final payment in parsedPayments) {
        final existing = await _paymentDB.get(payment.unified, txn);

        if (existing == null) {
          await _paymentDB.insert(payment, txn);
          payments++;
        } else if (payment.updatedAt > existing.updatedAt) {
          await _paymentDB.update(payment, txn);
          payments++;
        }
      }

      //
      // FATORA PRODUCTS
      //
      for (final item in parsedFatoraProducts) {
        final existing = await _fatoraProductsDB.get(item.unified, txn);

        if (existing == null) {
          await _fatoraProductsDB.insert(item, txn);
          fatoraProducts++;
        } else if (item.updatedAt > existing.updatedAt) {
          await _fatoraProductsDB.update(item, txn);
          fatoraProducts++;
        }
      }

      return ImportResult(
        users: users,
        fatoras: fatoras,
        payments: payments,
        fatoraProducts: fatoraProducts,
      );
    });

    return result;
  }

  //
  // ------------------------------------------------------------
  // IMPORT ZIP
  // ------------------------------------------------------------
  //

  Future<ImportResult> importZip(File zipFile) async {
    if (!await zipFile.exists()) {
      throw FileSystemException('ZIP backup does not exist.', zipFile.path);
    }

    final bytes = await zipFile.readAsBytes();

    final Archive archive;

    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw FormatException('Invalid ZIP backup: $e');
    }

    ArchiveFile? jsonEntry;

    for (final entry in archive) {
      if (!entry.isFile) {
        continue;
      }

      final name = basename(entry.name).toLowerCase();

      if (name.endsWith('.json')) {
        jsonEntry = entry;
        break;
      }
    }

    if (jsonEntry == null) {
      throw const FormatException(
        'No JSON backup was found inside the ZIP file.',
      );
    }

    final tmpDir = await getTemporaryDirectory();

    //
    // Never use the ZIP filename directly as a path.
    //
    final outFile = File(
      join(
        tmpDir.path,
        'naji_import_${DateTime.now().millisecondsSinceEpoch}.json',
      ),
    );

    try {
      await outFile.writeAsBytes(jsonEntry.content as List<int>, flush: true);

      return await importJson(outFile);
    } finally {
      try {
        if (await outFile.exists()) {
          await outFile.delete();
        }
      } catch (_) {
        // Ignore cleanup errors.
      }
    }
  }

  //
  // ------------------------------------------------------------
  // IMPORT SQLITE DATABASE
  // ------------------------------------------------------------
  //

  Future<void> importDatabase(File sourceDbFile) async {
    if (!await sourceDbFile.exists()) {
      throw FileSystemException(
        'Database backup does not exist.',
        sourceDbFile.path,
      );
    }

    //
    // Validate that the source is actually a SQLite database
    // containing the expected users table.
    //
    await _validateDatabaseFile(sourceDbFile);

    //
    // Close the current database and reset DatabaseHelper cache.
    //
    await DatabaseHelper.instance.close();

    final dbPath = await getDatabasesPath();

    final destination = File(join(dbPath, DatabaseHelper.databaseName));

    //
    // Keep the old DB until the new file has been copied.
    //
    final tempDestination = File(
      join(dbPath, '${DatabaseHelper.databaseName}.importing'),
    );

    if (await tempDestination.exists()) {
      await tempDestination.delete();
    }

    try {
      await sourceDbFile.copy(tempDestination.path);

      if (await destination.exists()) {
        await destination.delete();
      }

      await tempDestination.rename(destination.path);
    } catch (_) {
      try {
        if (await tempDestination.exists()) {
          await tempDestination.delete();
        }
      } catch (_) {}

      rethrow;
    }
  }

  //
  // ------------------------------------------------------------
  // VALIDATE BACKUP
  // ------------------------------------------------------------
  //

  void _validateBackup(Map<String, dynamic> data) {
    if (data['format'] != backupFormat) {
      throw const FormatException('This file is not a Naji backup.');
    }

    final version = data['version'];

    if (version is! num) {
      throw const FormatException('Backup version is missing.');
    }

    if (version.toInt() > supportedBackupVersion) {
      throw UnsupportedError(
        'This backup was created by a newer version of Naji. '
        'Backup version: ${version.toInt()}, '
        'supported: $supportedBackupVersion.',
      );
    }

    _validateListField(data, 'users');
    _validateListField(data, 'fatoras');
    _validateListField(data, 'payments');
    _validateListField(data, 'fatoraProducts');
  }

  void _validateListField(Map<String, dynamic> data, String field) {
    final value = data[field];

    if (value == null) {
      throw FormatException('Backup field "$field" is missing.');
    }

    if (value is! List) {
      throw FormatException('Backup field "$field" must be a list.');
    }
  }

  //
  // ------------------------------------------------------------
  // PARSING
  // ------------------------------------------------------------
  //

  List<User> _parseUsers(dynamic value) {
    return _parseList(value, 'users', (map) => User.fromJson(map));
  }

  List<Fatora> _parseFatoras(dynamic value) {
    return _parseList(value, 'fatoras', (map) => Fatora.fromJson(map));
  }

  List<Payment> _parsePayments(dynamic value) {
    return _parseList(value, 'payments', (map) => Payment.fromJson(map));
  }

  List<FatoraProduct> _parseFatoraProducts(dynamic value) {
    return _parseList(
      value,
      'fatoraProducts',
      (map) => FatoraProduct.fromJson(map),
    );
  }

  List<T> _parseList<T>(
    dynamic value,
    String field,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (value is! List) {
      throw FormatException('"$field" must be a list.');
    }

    final result = <T>[];

    for (var i = 0; i < value.length; i++) {
      final item = value[i];

      if (item is! Map) {
        throw FormatException('Invalid "$field" record at index $i.');
      }

      try {
        result.add(parser(Map<String, dynamic>.from(item)));
      } catch (e) {
        throw FormatException('Invalid "$field" record at index $i: $e');
      }
    }

    return result;
  }

  //
  // ------------------------------------------------------------
  // SQLITE VALIDATION
  // ------------------------------------------------------------
  //

  Future<void> _validateDatabaseFile(File file) async {
    Database? db;

    try {
      db = await openDatabase(file.path, readOnly: true);

      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master "
        "WHERE type = 'table' AND name = 'users'",
      );

      if (result.isEmpty) {
        throw const FormatException(
          'The database does not contain the expected Naji schema.',
        );
      }

      final usersColumns = await db.rawQuery('PRAGMA table_info(users)');

      final hasUnified = usersColumns.any((row) => row['name'] == 'unified');

      final hasUpdatedAt = usersColumns.any(
        (row) => row['name'] == 'updatedAt',
      );

      if (!hasUnified || !hasUpdatedAt) {
        throw const FormatException(
          'The database schema is not compatible with Naji.',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        rethrow;
      }

      throw FormatException('Invalid SQLite database: $e');
    } finally {
      await db?.close();
    }
  }
}

class ImportResult {
  final int users;
  final int fatoras;
  final int payments;
  final int fatoraProducts;

  const ImportResult({
    this.users = 0,
    this.fatoras = 0,
    this.payments = 0,
    this.fatoraProducts = 0,
  });

  int get total => users + fatoras + payments + fatoraProducts;

  bool get hasChanges => total > 0;

  @override
  String toString() {
    return 'ImportResult('
        'users: $users, '
        'fatoras: $fatoras, '
        'payments: $payments, '
        'fatoraProducts: $fatoraProducts'
        ')';
  }

  Map<String, int> toMap() {
    return {
      'users': users,
      'fatoras': fatoras,
      'payments': payments,
      'fatoraProducts': fatoraProducts,
      'total': total,
    };
  }
}
