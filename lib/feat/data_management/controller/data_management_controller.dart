import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:naji/core/services/backup_service.dart';
import 'package:naji/core/services/import_service.dart';
import 'package:share_plus/share_plus.dart';

enum DataManagementOperation {
  none,
  exportingJson,
  exportingZip,
  exportingDatabase,
  importingJson,
  importingZip,
  importingDatabase,
}

class DataManagementController extends ChangeNotifier {
  final BackupService _backupService;
  final ImportService _importService;

  DataManagementController({
    BackupService? backupService,
    ImportService? importService,
  }) : _backupService = backupService ?? BackupService(),
       _importService = importService ?? ImportService();

  DataManagementOperation _operation = DataManagementOperation.none;

  ImportResult? _lastImportResult;

  String? _error;

  File? _lastExportedFile;

  bool get isLoading => _operation != DataManagementOperation.none;

  DataManagementOperation get operation => _operation;

  ImportResult? get lastImportResult => _lastImportResult;

  String? get error => _error;

  File? get lastExportedFile => _lastExportedFile;

  bool get hasResult => _lastImportResult != null;

  //
  // ------------------------------------------------------------
  // EXPORT JSON
  // ------------------------------------------------------------
  //

  Future<void> exportJson() async {
    await _run(DataManagementOperation.exportingJson, () async {
      final file = await _backupService.exportJson();

      _lastExportedFile = file;

      await _shareFile(file, text: 'Naji JSON Backup');
    });
  }

  //
  // ------------------------------------------------------------
  // EXPORT ZIP
  // ------------------------------------------------------------
  //

  Future<void> exportZip() async {
    await _run(DataManagementOperation.exportingZip, () async {
      final file = await _backupService.exportZip();

      _lastExportedFile = file;

      await _shareFile(file, text: 'Naji ZIP Backup');
    });
  }

  //
  // ------------------------------------------------------------
  // EXPORT DATABASE
  // ------------------------------------------------------------
  //

  Future<void> exportDatabase() async {
    await _run(DataManagementOperation.exportingDatabase, () async {
      final file = await _backupService.exportDatabase();

      _lastExportedFile = file;

      await _shareFile(file, text: 'Naji Database Backup');
    });
  }

  //
  // ------------------------------------------------------------
  // IMPORT FILE
  // ------------------------------------------------------------
  //

  Future<void> pickAndImport() async {
    _clearError();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'zip', 'db'],
      allowMultiple: false,
    );

    if (result == null) {
      return;
    }

    final path = result.files.single.path;

    if (path == null || path.isEmpty) {
      _setError('تعذر الوصول إلى الملف.');
      return;
    }

    final file = File(path);

    if (!await file.exists()) {
      _setError('الملف غير موجود.');
      return;
    }

    final extension = result.files.single.extension?.toLowerCase();

    switch (extension) {
      case 'json':
        await importJson(file);
        break;

      case 'zip':
        await importZip(file);
        break;

      case 'db':
        await importDatabase(file);
        break;

      default:
        _setError('نوع الملف غير مدعوم.');
    }
  }

  //
  // ------------------------------------------------------------
  // IMPORT JSON
  // ------------------------------------------------------------
  //

  Future<void> importJson(File file) async {
    await _run(DataManagementOperation.importingJson, () async {
      _lastImportResult = await _importService.importJson(file);
    });
  }

  //
  // ------------------------------------------------------------
  // IMPORT ZIP
  // ------------------------------------------------------------
  //

  Future<void> importZip(File file) async {
    await _run(DataManagementOperation.importingZip, () async {
      _lastImportResult = await _importService.importZip(file);
    });
  }

  //
  // ------------------------------------------------------------
  // IMPORT DATABASE
  // ------------------------------------------------------------
  //

  Future<void> importDatabase(File file) async {
    await _run(DataManagementOperation.importingDatabase, () async {
      await _importService.importDatabase(file);

      _lastImportResult = null;
    });
  }

  //
  // ------------------------------------------------------------
  // CLEAR RESULT
  // ------------------------------------------------------------
  //

  void clearResult() {
    _lastImportResult = null;
    _error = null;
    notifyListeners();
  }

  //
  // ------------------------------------------------------------
  // INTERNAL
  // ------------------------------------------------------------
  //

  Future<void> _run(
    DataManagementOperation operation,
    Future<void> Function() action,
  ) async {
    if (isLoading) {
      return;
    }

    _operation = operation;
    _error = null;
    _lastExportedFile = null;

    notifyListeners();

    try {
      await action();
    } catch (e) {
      _error = _cleanError(e);
    } finally {
      _operation = DataManagementOperation.none;
      notifyListeners();
    }
  }

  Future<void> _shareFile(File file, {String? text}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: text),
    );
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    if (_error == null) {
      return;
    }

    _error = null;
    notifyListeners();
  }

  String _cleanError(Object error) {
    if (error is FileSystemException) {
      return error.message;
    }

    return error.toString().replaceFirst('Exception: ', '');
  }
}
