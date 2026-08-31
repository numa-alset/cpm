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
      // appBar: AppBar(
      //   title: const Text('الرئيسية'),
      //   actions: [
      //     IconButton(
      //       tooltip: 'تحديث',
      //       onPressed: context.read<HomeController>().loadData,
      //       icon: const Icon(Icons.refresh),
      //     ),
      //   ],
      // ),
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

// ============================================================
// SUMMARY
// ============================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('بيانات بانتظار الجدولة', style: theme.textTheme.titleLarge),

            const SizedBox(height: 8),

            Text(
              '${controller.itemCount} عناصر رئيسية'
              '${controller.productCount > 0 ? ' • ${controller.productCount} منتجات' : ''}',
              style: theme.textTheme.bodyMedium,
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

// ============================================================
// SCHEDULE ALL
// ============================================================

class _ScheduleAllButton extends StatelessWidget {
  const _ScheduleAllButton({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
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
      ),
    );
  }
}

// ============================================================
// SYNC ITEM CARD
// ============================================================

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
      child: item.isExpandable
          ? ExpansionTile(
              leading: _ItemIcon(type: item.type),
              title: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              children: [
                if (item.hasDetails) _SyncDetails(details: item.details),

                if (item.hasChildren) ...[
                  if (item.hasDetails) const Divider(height: 1),

                  _ChildrenHeader(count: item.children.length),

                  ...item.children.map((child) => _ChildItem(child: child)),
                ],

                const Divider(height: 1),

                _ScheduleAction(enabled: enabled, onPressed: onSchedule),
              ],
            )
          : ListTile(
              leading: _ItemIcon(type: item.type),
              title: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                tooltip: 'جدولة',
                onPressed: enabled ? onSchedule : null,
                icon: const Icon(Icons.share_outlined),
              ),
            ),
    );
  }
}

// ============================================================
// DETAILS
// ============================================================

class _SyncDetails extends StatelessWidget {
  const _SyncDetails({required this.details});

  final List<SyncDetail> details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(72, 8, 16, 12),
      child: Column(
        children: [
          for (final detail in details)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(detail.label, style: theme.textTheme.bodySmall),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    flex: 3,
                    child: Text(
                      detail.value,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// CHILDREN
// ============================================================

class _ChildrenHeader extends StatelessWidget {
  const _ChildrenHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 72,
        end: 16,
        top: 8,
        bottom: 4,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          'المنتجات ($count)',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}

class _ChildItem extends StatelessWidget {
  const _ChildItem({required this.child});

  final SyncItem child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 72, end: 16),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: const Icon(Icons.inventory_2_outlined, size: 20),
        title: Text(child.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: child.details.isEmpty
            ? null
            : _ProductDetails(details: child.details),
        trailing: Text(
          child.subtitle,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.details});

  final List<SyncDetail> details;

  @override
  Widget build(BuildContext context) {
    final quantity = details.where((e) => e.label == 'الكمية').firstOrNull;

    final unitPrice = details.where((e) => e.label == 'سعر الوحدة').firstOrNull;

    if (quantity == null || unitPrice == null) {
      return const SizedBox.shrink();
    }

    return Text('${quantity.value} × ${unitPrice.value}');
  }
}

// ============================================================
// ICON
// ============================================================

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

// ============================================================
// SCHEDULE ACTION
// ============================================================

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

// ============================================================
// EMPTY
// ============================================================

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

// ============================================================
// ERROR
// ============================================================

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
