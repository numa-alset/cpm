import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:naji/core/models/payment.dart';
import 'package:naji/core/services/payment_service.dart';
import 'package:naji/core/services/user_service.dart';
import 'package:naji/feat/payments/controller/payment_controller.dart';
import 'package:naji/feat/payments/widgets/add_payment_sheet.dart';
import 'package:naji/feat/payments/widgets/payment_group.dart';
import 'package:provider/provider.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaymentsController(
        paymentService: GetIt.I<PaymentService>(),
        userService: GetIt.I<UserService>(),
      )..loadData(),
      child: const _PaymentsView(),
    );
  }
}

class _PaymentsView extends StatelessWidget {
  const _PaymentsView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaymentsController>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPaymentSheet(context, controller),
        icon: const Icon(Icons.add_card_rounded),
        label: const Text("إضافة دفعة"),
      ),

      body: Column(
        children: [
          _buildFilterBar(context, controller),

          Expanded(child: _buildContent(context, controller)),
        ],
      ),
    );
  }

  // ===========================================================================
  // FILTER BAR
  // ===========================================================================

  Widget _buildFilterBar(BuildContext context, PaymentsController controller) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          // ============================================================
          // FILTERS
          // ============================================================
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _FilterItem(
                      label: "يومي",
                      icon: Icons.today_outlined,
                      selected: controller.currentFilter == GroupingFilter.day,
                      onTap: () => controller.changeFilter(GroupingFilter.day),
                    ),
                  ),

                  Expanded(
                    child: _FilterItem(
                      label: "شهري",
                      icon: Icons.calendar_month_outlined,
                      selected:
                          controller.currentFilter == GroupingFilter.month,
                      onTap: () =>
                          controller.changeFilter(GroupingFilter.month),
                    ),
                  ),

                  Expanded(
                    child: _FilterItem(
                      label: "سنوي",
                      icon: Icons.calendar_today_outlined,
                      selected: controller.currentFilter == GroupingFilter.year,
                      onTap: () => controller.changeFilter(GroupingFilter.year),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ============================================================
          // GROUP ACTIONS
          // ============================================================
          if (controller.groups.isNotEmpty) ...[
            const SizedBox(width: 8),

            Container(
              height: 46,
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: PopupMenuButton<_GroupAction>(
                tooltip: "المجموعات",
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert_rounded),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (action) {
                  switch (action) {
                    case _GroupAction.expandAll:
                      controller.expandAll();
                      break;

                    case _GroupAction.collapseAll:
                      controller.collapseAll();
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _GroupAction.expandAll,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.unfold_more_rounded),
                      title: Text("توسيع الكل"),
                    ),
                  ),

                  PopupMenuItem(
                    value: _GroupAction.collapseAll,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.unfold_less_rounded),
                      title: Text("طي الكل"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // CONTENT
  // ===========================================================================

  Widget _buildContent(BuildContext context, PaymentsController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null) {
      return _buildErrorState(context, controller);
    }

    if (controller.groups.isEmpty) {
      return _buildEmptyState(context, controller);
    }

    return RefreshIndicator(
      onRefresh: controller.loadData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 110),
        itemCount: controller.groups.length,
        itemBuilder: (context, index) {
          final group = controller.groups[index];

          return PaymentGroupWidget(
            group: group,
            collapsed: controller.isGroupCollapsed(group.key),
            userName: controller.getUserName,
            onToggle: () {
              controller.toggleGroup(group.key);
            },
            onDelete: (payment) => _deletePayment(context, controller, payment),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // ERROR
  // ===========================================================================

  Widget _buildErrorState(BuildContext context, PaymentsController controller) {
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: controller.loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: colors.onErrorContainer,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "حدث خطأ",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      controller.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 20),

                    FilledButton.icon(
                      onPressed: controller.loadData,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text("إعادة المحاولة"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // EMPTY
  // ===========================================================================

  Widget _buildEmptyState(BuildContext context, PaymentsController controller) {
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: controller.loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.payments_outlined,
                      size: 40,
                      color: colors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "لا توجد دفعات",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "لم يتم تسجيل أي دفعات حتى الآن",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ADD PAYMENT
  // ===========================================================================

  Future<void> _showAddPaymentSheet(
    BuildContext context,
    PaymentsController controller,
  ) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddPaymentSheet(controller: controller),
    );

    if (success == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تمت إضافة الدفعة بنجاح")));
    }
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  Future<void> _deletePayment(
    BuildContext context,
    PaymentsController controller,
    Payment payment,
  ) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final colors = Theme.of(dialogContext).colorScheme;

            return AlertDialog(
              title: const Text("حذف الدفعة"),
              content: const Text(
                "هل أنت متأكد من حذف هذه الدفعة؟ سيتم استرجاع المبلغ لرصيد العميل.",
              ),
              actions: [
                TextButton(
                  onPressed: () => dialogContext.pop(false),
                  child: const Text("إلغاء"),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                  ),
                  onPressed: () => dialogContext.pop(true),
                  child: const Text("حذف"),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirm || !context.mounted) {
      return;
    }

    final success = await controller.deletePayment(payment.unified);

    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم حذف الدفعة بنجاح")));
    }
  }
}

// ==============================================================================
// FILTER ITEM
// ==============================================================================

class _FilterItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? colors.onPrimary : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _GroupAction { expandAll, collapseAll }
