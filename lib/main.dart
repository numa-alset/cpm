import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:naji/core/services/share_import_service.dart';
import 'package:naji/locator/locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupLocator();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<ImportProgress>? _importSubscription;

  bool _processingDialogVisible = false;

  @override
  void initState() {
    super.initState();

    final shareImportService = getIt<ShareImportService>();

    // IMPORTANT:
    // Subscribe BEFORE initialize().
    _importSubscription = shareImportService.progress.listen(
      _handleImportProgress,
    );

    // Now start listening for shared files.
    shareImportService.initialize();
  }

  void _handleImportProgress(ImportProgress progress) {
    print('UI: import status = ${progress.status}');

    print('UI: message = ${progress.message}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (progress.status) {
        case ImportProgressStatus.processing:
          _showProcessingDialog(progress.message);
          break;

        case ImportProgressStatus.success:
          _hideProcessingDialog();

          _showImportSuccess(progress);

          break;

        case ImportProgressStatus.failure:
          _hideProcessingDialog();

          _showImportError(progress);

          break;
      }
    });
  }

  void _showProcessingDialog(String? message) {
    if (_processingDialogVisible) return;

    _processingDialogVisible = true;

    final context =
        getIt<GoRouter>().routerDelegate.navigatorKey.currentContext;

    if (context == null) {
      _processingDialogVisible = false;
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(width: 20),
                Expanded(child: Text(message ?? 'جاري استيراد الملف...')),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      _processingDialogVisible = false;
    });
  }

  void _hideProcessingDialog() {
    if (!_processingDialogVisible) return;

    final context =
        getIt<GoRouter>().routerDelegate.navigatorKey.currentContext;

    if (context == null) {
      _processingDialogVisible = false;
      return;
    }

    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
    }

    _processingDialogVisible = false;
  }

  void _showImportSuccess(ImportProgress progress) {
    final context =
        getIt<GoRouter>().routerDelegate.navigatorKey.currentContext;

    if (context == null) return;

    final result = progress.result;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          progress.message ?? 'تم استيراد ${result?.total ?? 0} عنصر بنجاح',
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showImportError(ImportProgress progress) {
    final context =
        getIt<GoRouter>().routerDelegate.navigatorKey.currentContext;

    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(progress.message ?? 'فشل استيراد الملف'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _importSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = getIt<GoRouter>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp.router(
        title: 'Naji',
        routeInformationProvider: router.routeInformationProvider,
        routeInformationParser: router.routeInformationParser,
        routerDelegate: router.routerDelegate,
        backButtonDispatcher: RootBackButtonDispatcher(),
      ),
    );
  }
}
