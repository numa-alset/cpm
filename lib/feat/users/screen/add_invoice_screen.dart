import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:naji/core/models/currency.dart';
import 'package:naji/core/services/invoice_service.dart';
import 'package:naji/feat/users/controllers/add_invoice_controller.dart';
import 'package:provider/provider.dart';

class AddInvoiceScreen extends StatelessWidget {
  final String userUnified;

  const AddInvoiceScreen({super.key, required this.userUnified});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddInvoiceController(
        userUnified: userUnified,
        invoiceService: GetIt.I<InvoiceService>(),
      ),
      child: const _AddInvoiceView(),
    );
  }
}

class _AddInvoiceView extends StatefulWidget {
  const _AddInvoiceView();

  @override
  State<_AddInvoiceView> createState() => _AddInvoiceViewState();
}

class _AddInvoiceViewState extends State<_AddInvoiceView> {
  final _formKey = GlobalKey<FormState>();
  final _writerController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _writerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<AddInvoiceController>();
    FocusScope.of(context).unfocus();

    final success = await controller.saveInvoice(
      writer: _writerController.text,
      note: _noteController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم إنشاء الفاتورة بنجاح"),
          backgroundColor: Colors.green,
        ),
      );
      context.pop(true);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final controller = context.read<AddInvoiceController>();
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
    final controller = context.watch<AddInvoiceController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("إضافة فاتورة جديدة"),
        centerTitle: true,
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (controller.error != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  ),
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

                          // Header Info Card
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "التاريخ",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            InkWell(
                                              onTap: () => _pickDate(context),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.grey.shade400,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.calendar_today,
                                                      size: 18,
                                                      color: Colors.blue,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      _formatDate(
                                                        controller.selectedDate,
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "اسم المحرر",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _writerController,
                                              decoration: InputDecoration(
                                                hintText: "اسم الكاتب",
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 12,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              validator: (val) {
                                                if (val == null ||
                                                    val.trim().isEmpty)
                                                  return "مطلوب";
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "ملاحظات (اختياري)",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _noteController,
                                    decoration: InputDecoration(
                                      hintText: "أي ملاحظات إضافية...",
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "المنتجات (${controller.items.length})",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: controller.addItem,
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text("إضافة منتج آخر"),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.items.length,
                            itemBuilder: (context, index) {
                              return _ProductItemRow(
                                key: ValueKey(index),
                                index: index,
                                item: controller.items[index],
                                isOnlyItem: controller.items.length == 1,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Dual Totals Summary & Save Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "الإجمالي (ليرة سورية):",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${controller.grandTotalSy.toStringAsFixed(2)} ل.س",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "الإجمالي (دولار أمريكي):",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${controller.grandTotalDollar.toStringAsFixed(2)} \$",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton.icon(
                              onPressed: _submit,
                              icon: const Icon(Icons.save),
                              label: const Text(
                                "حفظ الفاتورة",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProductItemRow extends StatefulWidget {
  final int index;
  final DraftInvoiceItem item;
  final bool isOnlyItem;

  const _ProductItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.isOnlyItem,
  });

  @override
  State<_ProductItemRow> createState() => _ProductItemRowState();
}

class _ProductItemRowState extends State<_ProductItemRow> {
  late TextEditingController _priceSyController;
  late TextEditingController _priceDollarController;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _priceSyController = TextEditingController(
      text: widget.item.priceSy >= 0 ? widget.item.priceSy.toString() : '0',
    );
    _priceDollarController = TextEditingController(
      text: widget.item.priceDollar >= 0
          ? widget.item.priceDollar.toString()
          : '0',
    );
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _ProductItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.priceSy.toString() != _priceSyController.text &&
        double.tryParse(_priceSyController.text) != widget.item.priceSy) {
      _priceSyController.text = widget.item.priceSy.toString();
    }
    if (widget.item.priceDollar.toString() != _priceDollarController.text &&
        double.tryParse(_priceDollarController.text) !=
            widget.item.priceDollar) {
      _priceDollarController.text = widget.item.priceDollar.toString();
    }
  }

  @override
  void dispose() {
    _priceSyController.dispose();
    _priceDollarController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _showCreateProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceSyController = TextEditingController(text: '0');
    final priceDollarController = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("إضافة منتج جديد للمخزن"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "اسم المنتج",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? "مطلوب" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceSyController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      labelText: "السعر (ل.س)",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final price = double.tryParse(v ?? '');
                      if (price == null || price < 0) return "مبلغ غير صحيح";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceDollarController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      labelText: "السعر (\$)",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final price = double.tryParse(v ?? '');
                      if (price == null || price < 0) return "مبلغ غير صحيح";
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("إلغاء"),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final name = nameController.text.trim();
                final priceSy = double.parse(priceSyController.text.trim());
                final priceDollar = double.parse(
                  priceDollarController.text.trim(),
                );

                Navigator.pop(dialogContext);

                final controller = context.read<AddInvoiceController>();
                // final success = await controller.createAndSelectProduct(
                //   index: widget.index,
                //   name: name,
                //   priceSy: priceSy,
                //   priceDollar: priceDollar,
                // );
                //
                // if (success) {
                //   _priceSyController.text = priceSy.toString();
                //   _priceDollarController.text = priceDollar.toString();
                // }
              },
              child: const Text("إضافة واختيار"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AddInvoiceController>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                // Expanded(
                //   child: Autocomplete<Product>(
                //     optionsBuilder: (TextEditingValue textEditingValue) {
                //       if (textEditingValue.text.isEmpty) {
                //         return const Iterable<Product>.empty();
                //       }
                //       return controller.availableProducts.where((
                //         Product product,
                //       ) {
                //         return product.name.toLowerCase().contains(
                //           textEditingValue.text.toLowerCase(),
                //         );
                //       });
                //     },
                //     displayStringForOption: (Product option) => option.name,
                //     onSelected: (Product selection) {
                //       controller.selectProduct(widget.index, selection);
                //       _priceSyController.text = selection.priceSy.toString();
                //       _priceDollarController.text = selection.priceDollar
                //           .toString();
                //     },
                //     fieldViewBuilder:
                //         (context, textController, focusNode, onFieldSubmitted) {
                //           if (textController.text.isEmpty &&
                //               widget.item.name.isNotEmpty) {
                //             textController.text = widget.item.name;
                //           }
                //           return TextFormField(
                //             controller: textController,
                //             focusNode: focusNode,
                //             onChanged: (val) {
                //               controller.updateItem(widget.index, name: val);
                //             },
                //             decoration: InputDecoration(
                //               labelText: "اسم المنتج",
                //               hintText: "اختر أو اكتب اسم المنتج",
                //               prefixIcon: const Icon(
                //                 Icons.shopping_cart,
                //                 size: 20,
                //               ),
                //               border: OutlineInputBorder(
                //                 borderRadius: BorderRadius.circular(8),
                //               ),
                //               contentPadding: const EdgeInsets.symmetric(
                //                 horizontal: 12,
                //                 vertical: 12,
                //               ),
                //             ),
                //             validator: (v) => (v == null || v.trim().isEmpty)
                //                 ? "مطلوب"
                //                 : null,
                //           );
                //         },
                //   ),
                // ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: () => _showCreateProductDialog(context),
                  icon: const Icon(Icons.add, color: Colors.blue),
                  tooltip: "إضافة منتج جديد للمخزن",
                ),
                if (!widget.isOnlyItem) ...[
                  const SizedBox(width: 4),
                  IconButton.outlined(
                    onPressed: () => controller.removeItem(widget.index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: "حذف السطر",
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<Currency>(
                    value: widget.item.currency,
                    decoration: InputDecoration(
                      labelText: "العملة",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: Currency.values
                        .map(
                          (currency) => DropdownMenuItem<Currency>(
                            value: currency,
                            child: Text(
                              currency == Currency.sy ? 'ل.س' : 'دولار',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.updateItem(widget.index, currency: value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _priceSyController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (val) {
                      final p = double.tryParse(val) ?? 0.0;
                      controller.updateItem(widget.index, priceSy: p);
                    },
                    decoration: InputDecoration(
                      labelText: widget.item.currency == Currency.sy
                          ? 'السعر (ل.س)'
                          : 'السعر (ل.س)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    validator: (v) {
                      final price = double.tryParse(v ?? '');
                      if (price == null || price < 0) return "غير صحيح";
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _priceDollarController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (val) {
                      final p = double.tryParse(val) ?? 0.0;
                      controller.updateItem(widget.index, priceDollar: p);
                    },
                    decoration: InputDecoration(
                      labelText: 'السعر (\$)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    validator: (v) {
                      final price = double.tryParse(v ?? '');
                      if (price == null || price < 0) return "غير صحيح";
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (val) {
                      final q = double.tryParse(val) ?? 1.0;
                      controller.updateItem(widget.index, quantity: q);
                    },
                    decoration: InputDecoration(
                      labelText: "الكمية",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    validator: (v) {
                      final q = double.tryParse(v ?? '');
                      if (q == null || q <= 0) return "خطأ";
                      return null;
                    },
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
