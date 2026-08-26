import 'package:flutter/material.dart';
import 'package:naji/core/models/currency.dart';
import 'package:naji/feat/payments/controller/payment_controller.dart';

class AddPaymentSheet extends StatefulWidget {
  final PaymentsController controller;

  const AddPaymentSheet({super.key, required this.controller});

  @override
  State<AddPaymentSheet> createState() => AddPaymentSheetState();
}

class AddPaymentSheetState extends State<AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();

  String? _selectedUserUnified;

  Currency _selectedCurrency = Currency.sy;

  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final success = await widget.controller.addPayment(
      userUnified: _selectedUserUnified!,
      amount: double.parse(_amountController.text.trim()),
      currency: _selectedCurrency,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.controller.error ?? "حدث خطأ غير متوقع")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.add_card_rounded,
                      color: colors.onPrimaryContainer,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "إضافة دفعة",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "سجّل دفعة جديدة للعميل",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "العميل",
                  hintText: "اختر العميل",
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                initialValue: _selectedUserUnified,
                items: widget.controller.users
                    .map(
                      (user) => DropdownMenuItem(
                        value: user.unified,
                        child: Text(user.name),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() {
                          _selectedUserUnified = value;
                        });
                      },
                validator: (value) {
                  if (value == null) {
                    return "الرجاء اختيار العميل";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<Currency>(
                decoration: InputDecoration(
                  labelText: "العملة",
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                initialValue: _selectedCurrency,
                items: Currency.values
                    .map(
                      (currency) => DropdownMenuItem(
                        value: currency,
                        child: Text("${currency.name} (${currency.symbol})"),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCurrency = value;
                          });
                        }
                      },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _amountController,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "المبلغ",
                  hintText: "0.00",
                  suffixText: _selectedCurrency.symbol,
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "المبلغ مطلوب";
                  }

                  final amount = double.tryParse(value.trim());

                  if (amount == null || amount <= 0) {
                    return "مبلغ غير صالح";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _saving
                    ? Container(
                        key: const ValueKey("loading"),
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : FilledButton.icon(
                        key: const ValueKey("save"),
                        onPressed: _save,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text("حفظ الدفعة"),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
