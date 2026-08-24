import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:naji/core/models/currency.dart';
import 'package:naji/core/router/route_pages.dart';
import 'package:naji/core/services/invoice_service.dart';
import 'package:naji/core/services/payment_service.dart';
import 'package:naji/feat/users/controllers/user_details_controller.dart';
import 'package:naji/feat/users/screen/edit_invoice_screen.dart';
import 'package:naji/feat/users/screen/edit_payment_screen.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/user.dart';
import '../../../../core/services/user_service.dart';

class UserDetailsScreen extends StatelessWidget {
  final String userUuid;

  const UserDetailsScreen({super.key, required this.userUuid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserDetailsController(
        userUnified: userUuid,
        userService: GetIt.I<UserService>(),
        invoiceService: GetIt.I<InvoiceService>(),
        paymentService: GetIt.I<PaymentService>(),
      )..load(),
      child: const _UserDetailsView(),
    );
  }
}

class _UserDetailsView extends StatelessWidget {
  const _UserDetailsView();

  String _formatDate(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("حذف الدفعة"),
            content: const Text(
              "هل أنت متأكد أنك تريد حذف هذه الدفعة؟ سيتم استرجاع المبلغ لرصيد العميل.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("إلغاء"),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text("حذف"),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _confirmDeleteInvoice(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("حذف الفاتورة"),
            content: const Text(
              "هل أنت متأكد أنك تريد حذف هذه الفاتورة؟ سيتم استرجاع المبلغ لرصيد العميل.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("إلغاء"),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text("حذف"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UserDetailsController>();
    final theme = Theme.of(context);

    if (controller.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("تفاصيل المستخدم")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.error != null || controller.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("خطأ")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(controller.error ?? "المستخدم غير موجود"),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.load,
                child: const Text("إعادة المحاولة"),
              ),
            ],
          ),
        ),
      );
    }

    final user = controller.user!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: Text(user.name), centerTitle: true),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddOptions(context, user),
          child: const Icon(Icons.add),
        ),
        body: RefreshIndicator(
          onRefresh: controller.load,
          child: Column(
            children: [
              // User Info Header with Dual Currency Balances
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surface,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(
                        Icons.store,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user.location,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Balances Section (SYP & USD)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "الأرصدة",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Syrian Pounds Balance
                        Text(
                          "${user.totalSy.toStringAsFixed(2)} ل.س",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: user.totalSy < 0 ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Dollar Balance
                        Text(
                          "${user.totalDollar.toStringAsFixed(2)} \$",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: user.totalDollar < 0
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Tabs
              const TabBar(
                tabs: [
                  Tab(text: "الفواتير", icon: Icon(Icons.receipt_long)),
                  Tab(text: "الدفعات", icon: Icon(Icons.payments_outlined)),
                ],
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  children: [
                    // --- Invoices Tab with Grouping ---
                    controller.invoices.isEmpty
                        ? _buildEmptyState("لا توجد فواتير")
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: controller.invoiceGroupKeys.length,
                            itemBuilder: (context, groupIndex) {
                              final groupKey =
                                  controller.invoiceGroupKeys[groupIndex];
                              final groupedInvoices =
                                  controller.groupedInvoices[groupKey] ?? [];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Group Header
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          groupKey,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '${groupedInvoices.length}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Invoices in this group
                                  ...List.generate(groupedInvoices.length, (
                                    index,
                                  ) {
                                    final invoiceRecord =
                                        groupedInvoices[index];
                                    final fatora = invoiceRecord.$1;
                                    final products = invoiceRecord.$2;

                                    final invoiceTotals = <String>[];
                                    if (fatora.totalSy > 0) {
                                      invoiceTotals.add(
                                        '${fatora.totalSy.toStringAsFixed(2)} ${Currency.sy.symbol}',
                                      );
                                    }
                                    if (fatora.totalDollar > 0) {
                                      invoiceTotals.add(
                                        '${fatora.totalDollar.toStringAsFixed(2)} ${Currency.dollar.symbol}',
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Card(
                                        elevation: 0,
                                        clipBehavior: Clip.antiAlias,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          side: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: ExpansionTile(
                                          shape: const Border(),
                                          collapsedShape: const Border(),
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                Colors.blue.shade50,
                                            child: const Icon(
                                              Icons.receipt,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          title: const Text("فاتورة"),
                                          subtitle: Text(
                                            "${_formatDate(fatora.date)}  •  ${products.length} منتجات",
                                          ),
                                          trailing: Text(
                                            invoiceTotals.join('  •  '),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          children: [
                                            const Divider(height: 1),
                                            if (fatora.note != null &&
                                                fatora.note!
                                                    .trim()
                                                    .isNotEmpty) ...[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(
                                                      Icons.note_outlined,
                                                      size: 18,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        fatora.note!,
                                                        style: const TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Divider(height: 1),
                                            ],
                                            if (products.isEmpty)
                                              const Padding(
                                                padding: EdgeInsets.all(16),
                                                child: Text(
                                                  "لا توجد منتجات مسجلة",
                                                ),
                                              )
                                            else
                                              ListView.separated(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemCount: products.length,
                                                separatorBuilder: (_, __) =>
                                                    const Divider(height: 1),
                                                itemBuilder: (context, prodIndex) {
                                                  final product =
                                                      products[prodIndex];
                                                  final productTotal =
                                                      product.price *
                                                      product.quantity;
                                                  final productCurrency =
                                                      product.currency;

                                                  return ListTile(
                                                    dense: true,
                                                    title: Text(
                                                      product.productName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      "الكمية: ${product.quantity} × ${product.price} ${productCurrency.symbol}",
                                                    ),
                                                    trailing: Text(
                                                      "${productTotal.toStringAsFixed(2)} ${productCurrency.symbol}",
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            const SizedBox(height: 12),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.blue,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        final result = await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                EditInvoiceScreen(
                                                                  invoice:
                                                                      fatora,
                                                                  invoiceProducts:
                                                                      products,
                                                                ),
                                                          ),
                                                        );
                                                        if (result == true &&
                                                            context.mounted) {
                                                          controller.load();
                                                        }
                                                      },
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size: 18,
                                                      ),
                                                      label: const Text(
                                                        "تعديل",
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        final confirm =
                                                            await _confirmDeleteInvoice(
                                                              context,
                                                            );
                                                        if (confirm &&
                                                            context.mounted) {
                                                          final success =
                                                              await controller
                                                                  .deleteInvoice(
                                                                    fatora
                                                                        .unified,
                                                                  );
                                                          if (success &&
                                                              context.mounted) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  "تم حذف الفاتورة بنجاح",
                                                                ),
                                                                backgroundColor:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      },
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        size: 18,
                                                      ),
                                                      label: const Text("حذف"),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                  if (groupIndex <
                                      controller.invoiceGroupKeys.length - 1)
                                    const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),

                    // --- Payments Tab with Grouping ---
                    controller.payments.isEmpty
                        ? _buildEmptyState("لا توجد دفعات")
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: controller.paymentGroupKeys.length,
                            itemBuilder: (context, groupIndex) {
                              final groupKey =
                                  controller.paymentGroupKeys[groupIndex];
                              final groupedPayments =
                                  controller.groupedPayments[groupKey] ?? [];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Group Header
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          groupKey,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '${groupedPayments.length}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Payments in this group
                                  ...List.generate(groupedPayments.length, (
                                    index,
                                  ) {
                                    final payment = groupedPayments[index];
                                    final currencySymbol =
                                        payment.currency.symbol;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Card(
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          side: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    backgroundColor:
                                                        Colors.green.shade50,
                                                    child: const Icon(
                                                      Icons.attach_money,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                          "دفعة نقدية",
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        Text(
                                                          _formatDate(
                                                            payment.date,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey
                                                                .shade600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    "${payment.amount.toStringAsFixed(2)} $currencySymbol",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  Expanded(
                                                    child: TextButton.icon(
                                                      style:
                                                          TextButton.styleFrom(
                                                            foregroundColor:
                                                                Colors.blue,
                                                          ),
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size: 18,
                                                      ),
                                                      label: const Text(
                                                        "تعديل",
                                                      ),
                                                      onPressed: () async {
                                                        final result =
                                                            await Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) =>
                                                                    EditPaymentScreen(
                                                                      payment:
                                                                          payment,
                                                                    ),
                                                              ),
                                                            );
                                                        if (result == true &&
                                                            context.mounted) {
                                                          controller.load();
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: TextButton.icon(
                                                      style:
                                                          TextButton.styleFrom(
                                                            foregroundColor:
                                                                Colors.red,
                                                          ),
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        size: 18,
                                                      ),
                                                      label: const Text("حذف"),
                                                      onPressed: () async {
                                                        final confirm =
                                                            await _confirmDelete(
                                                              context,
                                                            );
                                                        if (confirm &&
                                                            context.mounted) {
                                                          final success =
                                                              await context
                                                                  .read<
                                                                    UserDetailsController
                                                                  >()
                                                                  .deletePayment(
                                                                    payment
                                                                        .unified,
                                                                  );

                                                          if (success &&
                                                              context.mounted) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  "تم حذف الدفعة بنجاح",
                                                                ),
                                                                backgroundColor:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                  if (groupIndex <
                                      controller.paymentGroupKeys.length - 1)
                                    const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.receipt_long, color: Colors.white),
                  ),
                  title: const Text(
                    "إضافة فاتورة جديدة",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    final result = await context.push<bool>(
                      AppRouter.addInvoicePath,
                      extra: user.unified,
                    );

                    if (result == true && context.mounted) {
                      context.read<UserDetailsController>().load();
                    }
                  },
                ),
                const Divider(indent: 70),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.payments, color: Colors.white),
                  ),
                  title: const Text(
                    "إضافة دفعة مالية",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    context.pop(sheetContext);
                    final result = await context.push<bool>(
                      AppRouter.addPaymentPath,
                      extra: user.unified,
                    );
                    if (result == true && context.mounted) {
                      context.read<UserDetailsController>().load();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
