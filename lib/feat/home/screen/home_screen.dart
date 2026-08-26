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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: context.read<HomeController>().loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, _) {
        if (controller.isLoading && !controller.hasItems) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error != null && !controller.hasItems) {
          return _ErrorState(
            message: controller.error!,
            onRetry: controller.loadData,
          );
        }

        if (!controller.hasItems) {
          return const _EmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.loadData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _SummaryCard(controller: controller),

              const SizedBox(height: 16),

              _ScheduleAllButton(controller: controller),

              const SizedBox(height: 16),

              ...controller.unscheduledItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SyncItemCard(
                    item: item,
                    enabled: !controller.isScheduling,
                    onSchedule: () {
                      controller.scheduleSingle(item);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'بيانات بانتظار الجدولة',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 8),

            Text(
              '${controller.itemCount} عناصر رئيسية',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.person_outline,
                    label: 'المستخدمون',
                    value: controller.userCount,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'الفواتير',
                    value: controller.invoiceCount,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.payments_outlined,
                    label: 'الدفعات',
                    value: controller.paymentCount,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon),

        const SizedBox(height: 6),

        Text('$value', style: Theme.of(context).textTheme.titleMedium),

        const SizedBox(height: 2),

        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ScheduleAllButton extends StatelessWidget {
  const _ScheduleAllButton({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: controller.isScheduling
          ? null
          : () async {
              final success = await controller.scheduleAll();

              if (!context.mounted || !success) {
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تمت جدولة البيانات بنجاح')),
              );
            },
      icon: controller.isScheduling
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.share_outlined),
      label: Text(controller.isScheduling ? 'جاري الجدولة...' : 'جدولة الكل'),
    );
  }
}

class _ChildItem extends StatelessWidget {
  const _ChildItem({required this.child});

  final SyncItem child;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsetsDirectional.only(start: 72, end: 16),
      leading: const Icon(Icons.inventory_2_outlined, size: 20),
      title: Text(child.title),
      subtitle: Text(child.subtitle),
    );
  }
}

class _SyncItemCard extends StatelessWidget {
  const _SyncItemCard({
    required this.item,
    required this.enabled,
    required this.onSchedule,
  });

  final SyncItem item;
  final bool enabled;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: item.hasChildren
          ? ExpansionTile(
              leading: _ItemIcon(type: item.type),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              children: [
                ...item.children.map((child) => _ChildItem(child: child)),

                const Divider(height: 1),

                _ScheduleAction(enabled: enabled, onPressed: onSchedule),
              ],
            )
          : ListTile(
              leading: _ItemIcon(type: item.type),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: IconButton(
                tooltip: 'جدولة',
                onPressed: enabled ? onSchedule : null,
                icon: const Icon(Icons.share_outlined),
              ),
            ),
    );
  }
}

class _ItemIcon extends StatelessWidget {
  const _ItemIcon({required this.type});

  final SyncItemType type;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case SyncItemType.user:
        return const CircleAvatar(child: Icon(Icons.person_outline));

      case SyncItemType.invoice:
        return const CircleAvatar(child: Icon(Icons.receipt_long_outlined));

      case SyncItemType.payment:
        return const CircleAvatar(child: Icon(Icons.payments_outlined));

      case SyncItemType.fatoraProduct:
        return const CircleAvatar(child: Icon(Icons.inventory_2_outlined));
    }
  }
}

class _ScheduleAction extends StatelessWidget {
  const _ScheduleAction({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: TextButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: const Icon(Icons.share_outlined),
          label: const Text('جدولة'),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<HomeController>().loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.7,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done_outlined, size: 64),

                  SizedBox(height: 16),

                  Text('لا توجد بيانات بانتظار الجدولة'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),

            const SizedBox(height: 12),

            Text(message, textAlign: TextAlign.center),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
