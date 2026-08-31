import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:naji/core/models/currency.dart';
import 'package:naji/core/services/payment_service.dart';
import 'package:naji/feat/users/controllers/edit_payment_controller.dart';
import 'package:provider/provider.dart';

class EditPaymentScreen extends StatelessWidget {
  final dynamic payment;

  const EditPaymentScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditPaymentController(
        payment: payment,
        paymentService: GetIt.I<PaymentService>(),
      ),
      child: const _EditPaymentView(),
    );
  }
}

class _EditPaymentView extends StatefulWidget {
  const _EditPaymentView();

  @override
  State<_EditPaymentView> createState() => _EditPaymentViewState();
}

class _EditPaymentViewState extends State<_EditPaymentView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final controller = context.read<EditPaymentController>();
    _amountController = TextEditingController(
      text: controller.amount.toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<EditPaymentController>();
    final amount = double.parse(_amountController.text.trim());
    controller.setAmount(amount);

    FocusScope.of(context).unfocus();

    final success = await controller.savePayment();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم تحديث الدفعة بنجاح"),
          backgroundColor: Colors.green,
        ),
      );
      context.pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.error ?? "حدث خطأ"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final controller = context.read<EditPaymentController>();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      controller.setDate(pickedDate);
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EditPaymentController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("تحديث الدفعة المالية"),
        centerTitle: true,
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                controller.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Text(
                      "المبلغ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      decoration: InputDecoration(
                        hintText: "0.00",
                        prefixIcon: const Icon(
                          Icons.attach_money,
                          color: Colors.green,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "الرجاء إدخال المبلغ";
                        }
                        final amount = double.tryParse(value.trim());
                        if (amount == null || amount <= 0) {
                          return "الرجاء إدخال مبلغ صحيح أكبر من صفر";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "العملة",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButton<Currency>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        value: controller.selectedCurrency,
                        items: Currency.values.map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Row(
                              children: [
                                Icon(
                                  currency == Currency.sy
                                      ? Icons.monetization_on
                                      : Icons.attach_money,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${currency.displayName} (${currency.symbol})",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newCurrency) {
                          if (newCurrency != null) {
                            controller.setCurrency(newCurrency);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "التاريخ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _formatDate(controller.selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.grey.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.close),
                              label: const Text("إلغاء"),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _submit,
                              icon: const Icon(Icons.check),
                              label: const Text("حفظ التغييرات"),
                            ),
                          ),
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
