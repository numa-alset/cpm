import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:naji/core/services/backup_service.dart';
import 'package:naji/core/services/import_service.dart';
import 'package:share_plus/share_plus.dart';

class DataManagementController extends ChangeNotifier {
  final ImportService _importService = GetIt.I<ImportService>();
  final BackupService _backupService = GetIt.I<BackupService>();

  bool isLoading = false;
  String? message;
  bool isError = false;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setMessage(String msg, {bool error = false}) {
    message = msg;
    isError = error;
    notifyListeners();
  }

  // --- IMPORT ---
  Future<void> importData() async {
    _setLoading(true);
    _setMessage("");

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'zip', 'db'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String extension = result.files.single.extension?.toLowerCase() ?? '';

        if (extension == 'db') {
          // Hard Database Restore
          await _importService.importDatabase(file);
          _setMessage(
            "تم استعادة قاعدة البيانات بالكامل. يرجى إعادة تشغيل التطبيق.",
          );
        } else {
          // Smart JSON / ZIP Merge
          Map<String, int> stats;
          if (extension == 'zip') {
            stats = await _importService.importZip(file);
          } else {
            stats = await _importService.importJson(file);
          }

          int total = stats.values.fold(0, (sum, val) => sum + val);

          if (total == 0) {
            _setMessage("لم يتم العثور على بيانات جديدة لإضافتها أو تحديثها.");
          } else {
            _setMessage(
              "تم بنجاح استيراد/تحديث:\n"
              "${stats['users']} مستخدمين\n"
              "${stats['products']} منتجات\n"
              "${stats['fatoras']} فواتير\n"
              "${stats['payments']} دفعات\n",
            );
          }
        }
      } else {
        _setMessage("تم إلغاء اختيار الملف.", error: true);
      }
    } catch (e) {
      _setMessage("حدث خطأ أثناء الاستيراد: $e", error: true);
    } finally {
      _setLoading(false);
    }
  }

  // --- EXPORT (Added this method) ---
  Future<void> exportFullBackup() async {
    _setLoading(true);
    _setMessage("");

    try {
      // Calls your existing backup service to generate the ZIP file
      final file = await _backupService.exportZip();

      // Opens the share dialog
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'نسخة احتياطية للبيانات',
        ),
      );

      _setMessage("تم تجهيز النسخة الاحتياطية بنجاح.");
    } catch (e) {
      _setMessage("حدث خطأ أثناء التصدير: $e", error: true);
    } finally {
      _setLoading(false);
    }
  }
}
