import 'package:flutter/material.dart';
import 'package:naji/feat/data_management/controller/data_management_controller.dart';
import 'package:naji/locator/locator.dart';
import 'package:provider/provider.dart';

class DataManagementScreen extends StatelessWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<DataManagementController>(),
      child: const _DataManagementView(),
    );
  }
}

class _DataManagementView extends StatelessWidget {
  const _DataManagementView();

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManagementController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('إدارة البيانات')),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  controller.clearResult();
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildBackupSection(context, controller),

                    const SizedBox(height: 16),

                    _buildRestoreSection(context, controller),

                    if (controller.lastImportResult != null) ...[
                      const SizedBox(height: 16),
                      _buildImportResult(context, controller),
                    ],

                    if (controller.error != null) ...[
                      const SizedBox(height: 16),
                      _buildError(context, controller),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),

              if (controller.isLoading)
                _buildLoadingOverlay(context, controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackupSection(
    BuildContext context,
    DataManagementController controller,
  ) {
    return _SectionCard(
      title: 'تصدير البيانات',
      icon: Icons.upload_rounded,
      child: Column(
        children: [
          _DataManagementTile(
            icon: Icons.description_outlined,
            title: 'نسخة JSON',
            subtitle: 'نسخة كاملة يمكن دمجها مع بيانات جهاز آخر',
            onTap: controller.isLoading ? null : controller.exportJson,
          ),

          const Divider(height: 1),

          _DataManagementTile(
            icon: Icons.folder_zip_outlined,
            title: 'نسخة ZIP',
            subtitle: 'نسخة مضغوطة مناسبة للحفظ والمشاركة',
            onTap: controller.isLoading ? null : controller.exportZip,
          ),

          const Divider(height: 1),

          _DataManagementTile(
            icon: Icons.storage_outlined,
            title: 'نسخة قاعدة البيانات',
            subtitle: 'نسخة كاملة من قاعدة بيانات Naji',
            onTap: controller.isLoading ? null : controller.exportDatabase,
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreSection(
    BuildContext context,
    DataManagementController controller,
  ) {
    return _SectionCard(
      title: 'استيراد البيانات',
      icon: Icons.download_rounded,
      child: Column(
        children: [
          _DataManagementTile(
            icon: Icons.file_open_outlined,
            title: 'استيراد نسخة احتياطية',
            subtitle: 'اختر ملف JSON أو ZIP أو قاعدة بيانات',
            onTap: controller.isLoading
                ? null
                : () => _handleImport(context, controller),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImport(
    BuildContext context,
    DataManagementController controller,
  ) async {
    await controller.pickAndImport();

    if (!context.mounted) {
      return;
    }

    if (controller.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error!),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (controller.lastImportResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم استيراد البيانات بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildImportResult(
    BuildContext context,
    DataManagementController controller,
  ) {
    final result = controller.lastImportResult!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'نتيجة الاستيراد',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  tooltip: 'مسح',
                  onPressed: controller.clearResult,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _ResultRow(label: 'المستخدمون', value: result.users),

            _ResultRow(label: 'الفواتير', value: result.fatoras),

            _ResultRow(label: 'الدفعات', value: result.payments),

            _ResultRow(label: 'منتجات الفواتير', value: result.fatoraProducts),

            const Divider(),

            _ResultRow(label: 'المجموع', value: result.total, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    DataManagementController controller,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                controller.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            IconButton(
              onPressed: controller.clearResult,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(
    BuildContext context,
    DataManagementController controller,
  ) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black26,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(),
                  ),

                  const SizedBox(height: 16),

                  Text(_operationText(controller.operation)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _operationText(DataManagementOperation operation) {
    switch (operation) {
      case DataManagementOperation.exportingJson:
        return 'جاري إنشاء نسخة JSON...';

      case DataManagementOperation.exportingZip:
        return 'جاري إنشاء النسخة المضغوطة...';

      case DataManagementOperation.exportingDatabase:
        return 'جاري إنشاء نسخة قاعدة البيانات...';

      case DataManagementOperation.importingJson:
        return 'جاري استيراد البيانات...';

      case DataManagementOperation.importingZip:
        return 'جاري فك واستيراد النسخة...';

      case DataManagementOperation.importingDatabase:
        return 'جاري استبدال قاعدة البيانات...';

      case DataManagementOperation.none:
        return '';
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DataManagementTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _DataManagementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: onTap != null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final int value;
  final bool bold;

  const _ResultRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: bold ? FontWeight.bold : null);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value.toString(), style: style),
        ],
      ),
    );
  }
}
