import 'dart:async';
import 'dart:io';

import 'package:file_share_intent/file_share_intent.dart';

import 'import_service.dart';

enum ImportProgressStatus { processing, success, failure }

class ImportProgress {
  const ImportProgress({required this.status, this.message, this.result});

  final ImportProgressStatus status;
  final String? message;
  final ImportResult? result;
}

class ShareImportService {
  ShareImportService({required ImportService importService})
    : _importService = importService;

  final ImportService _importService;

  StreamSubscription<List<SharedMediaFile>>? _subscription;

  final StreamController<ImportProgress> _progressController =
      StreamController<ImportProgress>.broadcast();

  Stream<ImportProgress> get progress => _progressController.stream;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;

    print('SHARE: initialize START');

    try {
      final initialFiles = await FileShareIntent.instance.getInitialMedia();

      print('SHARE: initial files = ${initialFiles.length}');

      if (initialFiles.isNotEmpty) {
        await _handleFiles(initialFiles);
      }
    } catch (e, stack) {
      print('SHARE: initial error = $e');
      print(stack);

      _progressController.add(
        ImportProgress(
          status: ImportProgressStatus.failure,
          message: 'تعذر فتح الملف المشترك: $e',
        ),
      );
    }

    print('SHARE: registering stream');

    _subscription = FileShareIntent.instance.getMediaStream().listen(
      (files) async {
        print('SHARE: stream received ${files.length} file(s)');

        if (files.isEmpty) return;

        await _handleFiles(files);
      },
      onError: (error, stack) {
        print('SHARE: stream error = $error');
        print(stack);

        _progressController.add(
          ImportProgress(
            status: ImportProgressStatus.failure,
            message: 'تعذر استقبال الملف: $error',
          ),
        );
      },
    );

    print('SHARE: initialize END');
  }

  Future<void> _handleFiles(List<SharedMediaFile> files) async {
    print('SHARE: handling ${files.length} file(s)');

    for (final sharedFile in files) {
      final path = sharedFile.path;

      print('SHARE: path = $path');

      if (path.isEmpty) {
        print('SHARE: empty path');
        continue;
      }

      final file = File(path);

      final exists = await file.exists();

      print('SHARE: file exists = $exists');

      if (!exists) {
        _progressController.add(
          const ImportProgress(
            status: ImportProgressStatus.failure,
            message: 'الملف غير موجود.',
          ),
        );

        continue;
      }

      // Tell the UI that processing has started.
      print('SHARE: processing started');

      _progressController.add(
        const ImportProgress(
          status: ImportProgressStatus.processing,
          message: 'جاري استيراد الملف...',
        ),
      );

      try {
        print('IMPORT: starting $path');

        final result = await _importService.importFile(file);

        print('IMPORT: finished');
        print('IMPORT: success = ${result.success}');
        print('IMPORT: total = ${result.total}');
        print('IMPORT: message = ${result.message}');

        if (result.success) {
          _progressController.add(
            ImportProgress(
              status: ImportProgressStatus.success,
              message: result.message,
              result: result,
            ),
          );
        } else {
          _progressController.add(
            ImportProgress(
              status: ImportProgressStatus.failure,
              message: result.message,
              result: result,
            ),
          );
        }
      } catch (e, stack) {
        print('IMPORT ERROR: $e');
        print(stack);

        _progressController.add(
          ImportProgress(
            status: ImportProgressStatus.failure,
            message: 'فشل استيراد الملف: $e',
          ),
        );
      }
    }

    print('SHARE: resetting');

    await FileShareIntent.instance.reset();

    print('SHARE: done');
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _progressController.close();
  }
}
