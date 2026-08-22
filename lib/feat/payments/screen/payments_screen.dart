import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:naji/core/models/currency.dart';
import 'package:naji/core/models/payment.dart';
import 'package:naji/core/services/payment_service.dart';
import 'package:naji/core/services/user_service.dart';
import 'package:naji/feat/payments/controller/payment_controller.dart';
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

  String _formatExactDate(int milliseconds) {
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

  void _showAddPaymentDialog(BuildContext context) {
    final controller = context.read<PaymentsController>();

    String? selectedUserUnified;
    Currency selectedCurrency = Currency.sy; // القيمة الافتراضية للعملة
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("إضافة دفعة جديدة"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dropdown to select User
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "العميل",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                initialValue: selectedUserUnified,
                hint: const Text("اختر العميل"),
                items: controller.users.map((user) {
                  return DropdownMenuItem(
                    value: user.unified,
                    child: Text(user.name),
                  );
                }).toList(),
                onChanged: (val) {
                  selectedUserUnified = val;
                },
                validator: (val) => val == null ? "الرجاء اختيار عميل" : null,
              ),
              const SizedBox(height: 16),

              // Dropdown to select Currency
              DropdownButtonFormField<Currency>(
                decoration: const InputDecoration(
                  labelText: "العملة",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                value: selectedCurrency,
                items: Currency.values.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency.name),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    selectedCurrency = val;
                  }
                },
              ),
              const SizedBox(height: 16),

              // TextField for Amount
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "المبلغ",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "مطلوب";
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) return "مبلغ غير صالح";
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("إلغاء"),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // تمرير العملة المختارة مع العملية
                final success = await context
                    .read<PaymentsController>()
                    .addPayment(
                      userUnified: selectedUserUnified!,
                      amount: double.parse(amountController.text.trim()),
                      currency: selectedCurrency,
                    );

                if (success && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("تمت إضافة الدفعة بنجاح"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text("حفظ الدفعة"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaymentsController>();
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPaymentDialog(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Selector
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<GroupingFilter>(
                  segments: const [
                    ButtonSegment(
                      value: GroupingFilter.day,
                      label: Text("يومياً"),
                    ),
                    ButtonSegment(
                      value: GroupingFilter.month,
                      label: Text("شهرياً"),
                    ),
                    ButtonSegment(
                      value: GroupingFilter.year,
                      label: Text("سنوياً"),
                    ),
                  ],
                  selected: {controller.currentFilter},
                  onSelectionChanged: (set) =>
                      controller.changeFilter(set.first),
                ),
              ),
            ),

            // Main Content wrapped in RefreshIndicator
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.loadData,
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : controller.error != null
                    ? CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                        ],
                      )
                    : controller.displayItems.isEmpty
                    ? CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                "لا توجد مدفوعات مسجلة حتى الآن",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: controller.displayItems.length,
                        itemBuilder: (context, index) {
                          final item = controller.displayItems[index];

                          // --- RENDER HEADER ITEM ---
                          if (item is String) {
                            final isCollapsed = controller.collapsedGroups
                                .contains(item);

                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => controller.toggleGroup(item),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                    Icon(
                                      isCollapsed
                                          ? Icons.expand_more
                                          : Icons.expand_less,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // --- RENDER PAYMENT ITEM ---
                          if (item is Payment) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.shade50,
                                  child: Icon(
                                    // تغيير الأيقونة لتلائم نوع العملة
                                    item.currency == Currency.dollar
                                        ? Icons.attach_money
                                        : Icons.money,
                                    color: Colors.green,
                                  ),
                                ),
                                title: Text(
                                  // استخدام رمز العملة الديناميكي
                                  "${item.amount.toStringAsFixed(2)} ${item.currency.symbol}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      controller.getUserName(item.userUnified),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      "التاريخ: ${_formatExactDate(item.date)}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final confirm = await _confirmDelete(
                                      context,
                                    );
                                    if (confirm && context.mounted) {
                                      final success = await context
                                          .read<PaymentsController>()
                                          .deletePayment(item.unified);
                                      if (success && context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "تم حذف الدفعة بنجاح",
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            );
                          }

                          return const SizedBox.shrink();
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
