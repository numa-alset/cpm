import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:naji/core/models/fatora.dart';
import 'package:naji/core/router/route_pages.dart';
import 'package:naji/core/services/invoice_pdf_service.dart';
import 'package:naji/core/services/invoice_service.dart';
import 'package:naji/core/services/user_service.dart';
import 'package:naji/feat/invoices/controller/invoices_controller.dart';
import 'package:naji/feat/invoices/widgets/invoice_group_widget.dart';
import 'package:provider/provider.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          InvoicesController(GetIt.I<InvoiceService>(), GetIt.I<UserService>())
            ..loadInvoices(),
      child: const _InvoicesView(),
    );
  }
}

class _InvoicesView extends StatelessWidget {
  const _InvoicesView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoicesController>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // HEADER
            // -----------------------------------------------------------------
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            //   child: Row(
            //     children: [
            //       Expanded(
            //         child: Text(
            //           'الفواتير',
            //           style: Theme.of(context).textTheme.headlineSmall
            //               ?.copyWith(fontWeight: FontWeight.w800),
            //         ),
            //       ),
            //       IconButton.filledTonal(
            //         tooltip: 'تحديث',
            //         onPressed: controller.isLoading
            //             ? null
            //             : controller.loadInvoices,
            //         icon: const Icon(Icons.refresh_rounded),
            //       ),
            //     ],
            //   ),
            // ),

            // -----------------------------------------------------------------
            // FILTER BAR
            // -----------------------------------------------------------------
            _buildFilterBar(context, controller),

            // -----------------------------------------------------------------
            // BODY
            // -----------------------------------------------------------------
            Expanded(child: _Body(controller: controller)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final userService = GetIt.I<UserService>();

          try {
            final users = await userService.getAllUsers();

            if (!context.mounted) return;

            if (users.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('لا يوجد مستخدمون. أضف مستخدماً أولاً.'),
                ),
              );
              return;
            }

            final String selectedUser = await showModalBottomSheet(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (context) {
                return SafeArea(
                  child: SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'اختر العميل / المورد',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: users.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                tileColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onTap: () {
                                  context.pop(user.unified);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

            if (!context.mounted) return;
            context.push(AppRouter.addInvoicePath, extra: selectedUser);
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تعذر تحميل المستخدمين: $e')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة فاتورة'),
      ),
    );
  }

  // ===========================================================================
  // FILTER BAR
  // ===========================================================================

  Widget _buildFilterBar(BuildContext context, InvoicesController controller) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          // FILTERS
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

          // GROUP ACTIONS
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
}

// ==============================================================================
// BODY IMPLEMENTATION
// (assuming you have a ListView builder in _Body similar to Payments)
// ==============================================================================

// ==============================================================================
// BODY IMPLEMENTATION (With Delete & Share Logic)
// ==============================================================================

class _Body extends StatelessWidget {
  final InvoicesController controller;

  const _Body({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null) {
      return _ErrorState(
        error: controller.error!,
        onRetry: controller.loadInvoices,
      );
    }

    if (controller.groups.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: controller.loadInvoices,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        itemCount: controller.groups.length,
        itemBuilder: (context, index) {
          final group = controller.groups[index];

          return InvoiceGroupWidget(
            group: group,
            collapsed: controller.isGroupCollapsed(group.key),
            isExpanded: controller.isInvoiceExpanded,
            productsFor: controller.productsFor,
            isLoadingProducts: controller.isLoadingProducts,
            onToggle: () {
              controller.toggleGroup(group.key);
            },
            onToggleInvoice: (unified) {
              return controller.toggleInvoice(unified);
            },
            onDelete: (invoice) {
              return _deleteInvoice(context, controller, invoice);
            },
            onShare: (invoice) {
              return _shareInvoice(context, controller, invoice);
            },
            getUserName: controller.getUserName,
          );
        },
      ),
    );
  }

  Future<void> _deleteInvoice(
    BuildContext context,
    InvoicesController controller,
    Fatora invoice,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف الفاتورة'),
          content: const Text('هل أنت متأكد من حذف هذه الفاتورة؟'),
          actions: [
            TextButton(
              onPressed: () {
                context.pop(false);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                context.pop(true);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await controller.deleteInvoice(invoice);

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف الفاتورة')));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل حذف الفاتورة: $e')));
    }
  }

  Future<void> _shareInvoice(
    BuildContext context,
    InvoicesController controller,
    Fatora invoice,
  ) async {
    try {
      final products = controller.productsFor(invoice.unified);

      // If products haven't been loaded yet, load them first.
      if (products.isEmpty) {
        await controller.refreshInvoiceProducts(invoice.unified);
      }

      final loadedProducts = controller.productsFor(invoice.unified);

      final userService = GetIt.I<UserService>();
      final user = await userService.getUser(invoice.userUnified);

      if (user == null) {
        throw Exception('لم يتم العثور على العميل المرتبط بالفاتورة');
      }

      await InvoicePdfService.shareInvoice(
        user: user,
        fatora: invoice,
        products: loadedProducts,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر مشاركة الفاتورة: $e')));
    }
  }
}

// ==============================================================================
// EMPTY & ERROR STATES
// ==============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 52),
          SizedBox(height: 12),
          Text(
            'لا توجد فواتير',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text('أضف أول فاتورة للبدء'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          const Text('حدث خطأ أثناء تحميل الفواتير'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// FILTER ITEM & ENUMS
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
