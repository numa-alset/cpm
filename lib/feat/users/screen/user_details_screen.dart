import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:naji/core/router/route_pages.dart';
import 'package:naji/core/services/invoice_service.dart';
import 'package:naji/core/services/payment_service.dart';
import 'package:naji/feat/users/controllers/user_details_controller.dart';
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
    final isBuyer = user.type == UserType.buyer;

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
              // User Info Header
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surface,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isBuyer
                          ? Colors.blue.shade100
                          : Colors.orange.shade100,
                      child: Icon(
                        isBuyer ? Icons.shopping_cart : Icons.store,
                        color: isBuyer ? Colors.blue : Colors.orange,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "الرصيد",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          user.total.toStringAsFixed(2),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: user.total < 0 ? Colors.red : Colors.green,
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
                    // --- Invoices Tab with Embedded Products ---
                    controller.invoices.isEmpty
                        ? _buildEmptyState("لا توجد فواتير")
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: controller.invoices.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final invoiceRecord = controller.invoices[index];
                              final fatora = invoiceRecord.$1; // The Invoice
                              final products = invoiceRecord.$2; // The Products

                              final isSale = fatora.type.value == "sale";

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
                                    backgroundColor: isSale
                                        ? Colors.blue.shade50
                                        : Colors.purple.shade50,
                                    child: Icon(
                                      Icons.receipt,
                                      color: isSale
                                          ? Colors.blue
                                          : Colors.purple,
                                    ),
                                  ),
                                  title: Text(
                                    "فاتورة ${isSale ? 'مبيعات' : 'مشتريات'}",
                                  ),
                                  subtitle: Text(
                                    "${_formatDate(fatora.date)}  •  ${products.length} منتجات",
                                  ),
                                  trailing: Text(
                                    fatora.total.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  children: [
                                    const Divider(height: 1),
                                    if (products.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text("لا توجد منتجات مسجلة"),
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
                                          final product = products[prodIndex];
                                          return ListTile(
                                            dense: true,
                                            title: Text(
                                              product.productName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Text(
                                              "الكمية: ${product.quantity} × ${product.price}",
                                            ),
                                            trailing: Text(
                                              product.total.toStringAsFixed(2),
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              );
                            },
                          ),

                    // --- Payments Tab ---
                    controller.payments.isEmpty
                        ? _buildEmptyState("لا توجد دفعات")
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: controller.payments.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final payment = controller.payments[index];
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green.shade50,
                                    child: const Icon(
                                      Icons.attach_money,
                                      color: Colors.green,
                                    ),
                                  ),
                                  title: const Text("دفعة نقدية"),
                                  subtitle: Text(_formatDate(payment.date)),
                                  trailing: Text(
                                    payment.amount.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                  onTap: () {
                                    // TODO: Edit/View Payment Details
                                  },
                                ),
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
