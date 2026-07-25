import 'package:flutter/material.dart';
import 'package:naji/feat/home/controller/home_controller.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeController()..loadData(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  IconData _getIconForType(SyncItemType type) {
    switch (type) {
      case SyncItemType.user:
        return Icons.person;
      case SyncItemType.product:
        return Icons.inventory_2;
      case SyncItemType.invoice:
        return Icons.receipt;
      case SyncItemType.payment:
        return Icons.payment;
      case SyncItemType.fatoraProduct:
        return Icons.shopping_cart;
    }
  }

  Color _getColorForType(SyncItemType type) {
    switch (type) {
      case SyncItemType.user:
        return Colors.blue;
      case SyncItemType.product:
        return Colors.orange;
      case SyncItemType.invoice:
        return Colors.green;
      case SyncItemType.payment:
        return Colors.purple;
      case SyncItemType.fatoraProduct:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "بيانات غير مجدولة",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${controller.unscheduledItems.length} عنصر",
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text(
                      "تصدير وجدولة الكل",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed:
                        controller.unscheduledItems.isEmpty ||
                            controller.isLoading
                        ? null
                        : () async {
                            final success = await context
                                .read<HomeController>()
                                .scheduleAll();
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("تم التصدير والجدولة بنجاح"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // List Section
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.loadData,
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : controller.error != null
                    ? CustomScrollView(
                        slivers: [
                          SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    controller.error!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: controller.loadData,
                                    child: const Text("إعادة المحاولة"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : controller.unscheduledItems.isEmpty
                    ? CustomScrollView(
                        slivers: [
                          SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 64,
                                    color: Colors.green.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "رائع! لا توجد بيانات غير مجدولة",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: controller.unscheduledItems.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = controller.unscheduledItems[index];
                          final iconColor = _getColorForType(item.type);

                          // --- Grouped Display (Fatora with Products) ---
                          if (item.children.isNotEmpty) {
                            return Card(
                              elevation: 0,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: ExpansionTile(
                                shape: const Border(),
                                collapsedShape: const Border(),
                                leading: CircleAvatar(
                                  backgroundColor: iconColor.withOpacity(0.1),
                                  child: Icon(
                                    _getIconForType(item.type),
                                    color: iconColor,
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  item.subtitle,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                children: [
                                  const Divider(height: 1),
                                  ...item.children.map((child) {
                                    return ListTile(
                                      dense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                      leading: Icon(
                                        _getIconForType(child.type),
                                        color: _getColorForType(child.type),
                                        size: 18,
                                      ),
                                      title: Text(
                                        child.title,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      trailing: Text(
                                        child.subtitle,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  }),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    color: Colors.grey.shade50,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            theme.colorScheme.primaryContainer,
                                        foregroundColor: theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                        elevation: 0,
                                      ),
                                      icon: const Icon(
                                        Icons.cloud_upload_outlined,
                                      ),
                                      label: const Text(
                                        "جدولة الفاتورة وعناصرها",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onPressed: () async {
                                        final success = await context
                                            .read<HomeController>()
                                            .scheduleSingle(item);
                                        if (success && context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "تمت الجدولة بنجاح",
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // --- Single Standalone Item Display ---
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: iconColor.withOpacity(0.1),
                                child: Icon(
                                  _getIconForType(item.type),
                                  color: iconColor,
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                item.subtitle,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.cloud_upload_outlined,
                                  color: Colors.blue,
                                ),
                                tooltip: "جدولة هذا العنصر",
                                onPressed: () async {
                                  final success = await context
                                      .read<HomeController>()
                                      .scheduleSingle(item);
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "تمت جدولة '${item.title}' بنجاح",
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
