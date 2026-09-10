import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:naji/core/router/route_pages.dart';
import 'package:naji/locator/locator.dart';

/// Reusable error screen used across the app.
/// Shows an icon, title, message, and optional actions (retry / open data management).
class ErrorScreen extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final bool showDataManagementButton;

  const ErrorScreen({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.showDataManagementButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title ?? 'حصل خطأ'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 88,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 20),
              Text(
                title ?? 'حدث خطأ',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message ??
                    'حدثت مشكلة أثناء تنفيذ العملية. الرجاء المحاولة لاحقًا.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onRetry != null) ...[
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (showDataManagementButton)
                    OutlinedButton.icon(
                      onPressed: () {
                        try {
                          getIt<GoRouter>().go(AppRouter.homePath);
                        } catch (e) {
                          // ignore navigation errors here
                          debugPrint('Navigation to home failed: $e');
                        }
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('الصفحة الرئيسية'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
