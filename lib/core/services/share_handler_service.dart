// import 'dart:async';
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:get_it/get_it.dart';
// import 'package:receive_sharing_intent/receive_sharing_intent.dart';
//
// import 'import_service.dart';
//
// class ShareHandlerService {
//   final ImportService _importService = GetIt.I<ImportService>();
//   late StreamSubscription _intentDataStreamSubscription;
//
//   /// Call this inside your main.dart after initializing GetIt
//   void initialize(GlobalKey<NavigatorState> navigatorKey) {
//     // 1. App is in memory (running in background)
//     _intentDataStreamSubscription = ReceiveSharingIntent.instance
//         .getMediaStream()
//         .listen(
//           (List<SharedMediaFile> value) {
//             if (value.isNotEmpty) {
//               _processSharedFile(value.first.path, navigatorKey.currentContext);
//               ReceiveSharingIntent.instance.reset(); // Clear the intent
//             }
//           },
//           onError: (err) {
//             debugPrint("getIntentDataStream error: $err");
//           },
//         );
//
//     // 2. App is completely closed (Cold Start)
//     ReceiveSharingIntent.instance.getInitialMedia().then((
//       List<SharedMediaFile> value,
//     ) {
//       if (value.isNotEmpty) {
//         _processSharedFile(value.first.path, navigatorKey.currentContext);
//         ReceiveSharingIntent.instance.reset(); // Clear the intent
//       }
//     });
//   }
//
//   void dispose() {
//     _intentDataStreamSubscription.cancel();
//   }
//
//   Future<void> _processSharedFile(
//     String filePath,
//     BuildContext? context,
//   ) async {
//     if (context == null) return;
//
//     final file = File(filePath);
//     final extension = filePath.split('.').last.toLowerCase();
//
//     // Ensure it's a file type we support
//     if (!['zip', 'json', 'db'].contains(extension)) {
//       _showSnackBar(context, "صيغة الملف غير مدعومة.", isError: true);
//       return;
//     }
//
//     // Show confirmation dialog before importing
//     final shouldImport = await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => AlertDialog(
//         title: const Text("استيراد بيانات"),
//         content: Text(
//           "هل تريد استيراد البيانات من هذا الملف؟\n\n(${filePath.split('/').last})",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, false),
//             child: const Text("إلغاء"),
//           ),
//           FilledButton(
//             onPressed: () => Navigator.pop(ctx, true),
//             child: const Text("استيراد"),
//           ),
//         ],
//       ),
//     );
//
//     if (shouldImport == true) {
//       _executeImport(file, extension, context);
//     }
//   }
//
//   Future<void> _executeImport(
//     File file,
//     String extension,
//     BuildContext context,
//   ) async {
//     _showSnackBar(context, "جاري استيراد البيانات، يرجى الانتظار...");
//
//     try {
//       if (extension == 'db') {
//         await _importService.importDatabase(file);
//         _showSnackBar(
//           context,
//           "تم استعادة قاعدة البيانات. يرجى إعادة تشغيل التطبيق.",
//         );
//       } else {
//         Map<String, int> stats;
//         if (extension == 'zip') {
//           stats = await _importService.importZip(file);
//         } else {
//           stats = await _importService.importJson(file);
//         }
//
//         int total = stats.values.fold(0, (sum, val) => sum + val);
//
//         if (total == 0) {
//           _showSnackBar(context, "لم يتم العثور على بيانات جديدة لإضافتها.");
//         } else {
//           _showSnackBar(
//             context,
//             "تم الاستيراد بنجاح:\n${stats['users']} مستخدمين, ${stats['products']} منتجات, ${stats['fatoras']} فواتير",
//           );
//         }
//       }
//     } catch (e) {
//       _showSnackBar(context, "حدث خطأ أثناء الاستيراد: $e", isError: true);
//     }
//   }
//
//   void _showSnackBar(
//     BuildContext context,
//     String message, {
//     bool isError = false,
//   }) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green.shade800,
//         duration: const Duration(seconds: 4),
//       ),
//     );
//   }
// }
