import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:naji/core/database/database_helper.dart';
import 'package:naji/core/services/transaction_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  static const String backupFolderName = 'naji_backup';

  static const String backupFormat = 'naji_backup';

  static const int backupVersion = 1;

  final TransactionService _transactionService = TransactionService();

  //
  // ------------------------------------------------------------
  // FULL JSON BACKUP
  // ------------------------------------------------------------
  //

  Future<File> exportJson() async {
    final dir = await getApplicationDocumentsDirectory();

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final file = File(join(dir.path, '${backupFolderName}_$timestamp.json'));

    final backup = await _transactionService.runTransaction((txn) async {
      return _createFullBackup(txn);
    });

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backup),
    );

    return file;
  }

  //
  // ------------------------------------------------------------
  // FULL ZIP BACKUP
  // ------------------------------------------------------------
  //

  Future<File> exportZip() async {
    final jsonFile = await exportJson();

    final dir = await getApplicationDocumentsDirectory();

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final zipFile = File(join(dir.path, '${backupFolderName}_$timestamp.zip'));

    final encoder = ZipFileEncoder();

    encoder.create(zipFile.path);

    encoder.addFile(jsonFile, basename(jsonFile.path));

    encoder.close();

    // The JSON file is only needed temporarily.
    try {
      await jsonFile.delete();
    } catch (_) {
      // Ignore cleanup errors.
    }

    return zipFile;
  }

  //
  // ------------------------------------------------------------
  // SQLITE DATABASE BACKUP
  // ------------------------------------------------------------
  //

  Future<File> exportDatabase() async {
    final dir = await getApplicationDocumentsDirectory();

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final destination = File(
      join(dir.path, '${backupFolderName}_database_$timestamp.db'),
    );

    if (await destination.exists()) {
      await destination.delete();
    }

    final db = await DatabaseHelper.instance.database;

    //
    // Make sure all WAL changes are written into the main DB file.
    //
    await db.rawQuery('PRAGMA wal_checkpoint(FULL)');

    //
    // Close before copying the physical SQLite file.
    //
    await DatabaseHelper.instance.close();

    try {
      final sourcePath = await DatabaseHelper.instance.databasePath;
      final source = File(sourcePath);

      if (!await source.exists()) {
        throw StateError('Database file was not found.');
      }

      await source.copy(destination.path);

      return destination;
    } finally {
      //
      // Reopen the database so the app continues working.
      //
      await DatabaseHelper.instance.database;
    }
  }

  //
  // ------------------------------------------------------------
  // SHARE BACKUP
  // ------------------------------------------------------------
  //

  Future<void> shareBackup() async {
    final file = await exportJson();

    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  //
  // ------------------------------------------------------------
  // UNSYNCED EXPORT
  // ------------------------------------------------------------
  //

  Future<File> exportUnsynced() async {
    final dir = await getApplicationDocumentsDirectory();

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final file = File(join(dir.path, 'unsynced_$timestamp.json'));

    final backup = await _transactionService.runTransaction((txn) async {
      final users = await txn.query(
        'users',
        where: 'status = ?',
        whereArgs: ['notScheduled'],
        orderBy: 'updatedAt DESC',
      );

      final fatoras = await txn.query(
        'fatoras',
        where: 'status = ?',
        whereArgs: ['notScheduled'],
        orderBy: 'updatedAt DESC',
      );

      final payments = await txn.query(
        'payments',
        where: 'status = ?',
        whereArgs: ['notScheduled'],
        orderBy: 'updatedAt DESC',
      );

      final fatoraProducts = await txn.query(
        'fatora_items',
        where: 'status = ?',
        whereArgs: ['notScheduled'],
        orderBy: 'updatedAt DESC',
      );

      return {
        'format': backupFormat,
        'version': backupVersion,
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'unsynced',
        'users': users,
        'fatoras': fatoras,
        'payments': payments,
        'fatoraProducts': fatoraProducts,
      };
    });

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backup),
    );

    return file;
  }

  //
  // ------------------------------------------------------------
  // SINGLE RECORD EXPORT
  // ------------------------------------------------------------
  //

  Future<File> exportSingleRecord({
    required String type,
    required String unified,
  }) async {
    final normalizedType = type.toLowerCase().trim();

    final dir = await getApplicationDocumentsDirectory();

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final file = File(
      join(
        dir.path,
        '${backupFolderName}_${normalizedType}_'
        '${_safeFileName(unified)}_$timestamp.json',
      ),
    );

    final backup = await _transactionService.runTransaction((txn) async {
      return _createSingleRecordBackup(
        txn,
        type: normalizedType,
        unified: unified,
      );
    });

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backup),
    );

    return file;
  }

  //
  // ------------------------------------------------------------
  // FULL BACKUP CREATION
  // ------------------------------------------------------------
  //

  Future<Map<String, dynamic>> _createFullBackup(Transaction txn) async {
    //
    // IMPORTANT:
    //
    // No "deletedAt IS NULL" filter here.
    //
    // Tombstones must be exported so another device can learn
    // about deleted records.
    //

    final users = await txn.query('users', orderBy: 'updatedAt DESC');

    final fatoras = await txn.query('fatoras', orderBy: 'updatedAt DESC');

    final payments = await txn.query('payments', orderBy: 'updatedAt DESC');

    final fatoraProducts = await txn.query(
      'fatora_items',
      orderBy: 'updatedAt DESC',
    );

    return {
      'format': backupFormat,
      'version': backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'type': 'full',

      'users': users,
      'fatoras': fatoras,
      'payments': payments,
      'fatoraProducts': fatoraProducts,
    };
  }

  //
  // ------------------------------------------------------------
  // SINGLE RECORD BACKUP
  // ------------------------------------------------------------
  //

  Future<Map<String, dynamic>> _createSingleRecordBackup(
    Transaction txn, {
    required String type,
    required String unified,
  }) async {
    final result = <String, dynamic>{
      'format': backupFormat,
      'version': backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'type': 'single',

      'users': <Map<String, dynamic>>[],
      'fatoras': <Map<String, dynamic>>[],
      'payments': <Map<String, dynamic>>[],
      'fatoraProducts': <Map<String, dynamic>>[],
    };

    switch (type) {
      //
      // USER
      //
      case 'user':
      case 'users':
        final users = await txn.query(
          'users',
          where: 'unified = ?',
          whereArgs: [unified],
        );

        if (users.isEmpty) {
          throw StateError('User with unified "$unified" was not found.');
        }

        result['users'] = users;

        //
        // Include all invoices belonging to the user.
        //
        final fatoras = await txn.query(
          'fatoras',
          where: 'userUnified = ?',
          whereArgs: [unified],
          orderBy: 'updatedAt DESC',
        );

        result['fatoras'] = fatoras;

        //
        // Include all invoice items.
        //
        if (fatoras.isNotEmpty) {
          final fatoraIds = fatoras
              .map((e) => e['unified'])
              .whereType<String>()
              .toList();

          final placeholders = List.filled(fatoraIds.length, '?').join(',');

          final items = await txn.query(
            'fatora_items',
            where: 'fatoraUnified IN ($placeholders)',
            whereArgs: fatoraIds,
            orderBy: 'updatedAt DESC',
          );

          result['fatoraProducts'] = items;
        }

        //
        // Include all payments belonging to the user.
        //
        final payments = await txn.query(
          'payments',
          where: 'userUnified = ?',
          whereArgs: [unified],
          orderBy: 'updatedAt DESC',
        );

        result['payments'] = payments;

        break;

      //
      // FATORA
      //
      case 'fatora':
      case 'fatoras':
      case 'invoice':
      case 'invoices':
        final fatoras = await txn.query(
          'fatoras',
          where: 'unified = ?',
          whereArgs: [unified],
        );

        if (fatoras.isEmpty) {
          throw StateError('Fatora with unified "$unified" was not found.');
        }

        result['fatoras'] = fatoras;

        final fatora = fatoras.first;

        final userUnified = fatora['userUnified'];

        if (userUnified is String) {
          final users = await txn.query(
            'users',
            where: 'unified = ?',
            whereArgs: [userUnified],
          );

          result['users'] = users;
        }

        final items = await txn.query(
          'fatora_items',
          where: 'fatoraUnified = ?',
          whereArgs: [unified],
          orderBy: 'updatedAt DESC',
        );

        result['fatoraProducts'] = items;

        break;

      //
      // PAYMENT
      //
      case 'payment':
      case 'payments':
        final payments = await txn.query(
          'payments',
          where: 'unified = ?',
          whereArgs: [unified],
        );

        if (payments.isEmpty) {
          throw StateError('Payment with unified "$unified" was not found.');
        }

        result['payments'] = payments;

        final payment = payments.first;

        final userUnified = payment['userUnified'];

        if (userUnified is String) {
          final users = await txn.query(
            'users',
            where: 'unified = ?',
            whereArgs: [userUnified],
          );

          result['users'] = users;
        }

        break;

      //
      // FATORA PRODUCT
      //
      case 'fatoraproduct':
      case 'fatoraproducts':
      case 'fatora_product':
      case 'fatora_products':
      case 'item':
      case 'items':
        final items = await txn.query(
          'fatora_items',
          where: 'unified = ?',
          whereArgs: [unified],
        );

        if (items.isEmpty) {
          throw StateError(
            'Fatora product with unified "$unified" was not found.',
          );
        }

        result['fatoraProducts'] = items;

        final item = items.first;

        final fatoraUnified = item['fatoraUnified'];

        if (fatoraUnified is String) {
          final fatoras = await txn.query(
            'fatoras',
            where: 'unified = ?',
            whereArgs: [fatoraUnified],
          );

          result['fatoras'] = fatoras;

          if (fatoras.isNotEmpty) {
            final userUnified = fatoras.first['userUnified'];

            if (userUnified is String) {
              final users = await txn.query(
                'users',
                where: 'unified = ?',
                whereArgs: [userUnified],
              );

              result['users'] = users;
            }
          }
        }

        break;

      default:
        throw ArgumentError('Unknown backup type: "$type".');
    }

    return result;
  }

  String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}
