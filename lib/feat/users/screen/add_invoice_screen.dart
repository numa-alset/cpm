import 'package:flutter/material.dart';
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
    } else if (!success && mounted) {
      final error = context.read<AddInvoiceController>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? "حدث خطأ"),
          backgroundColor: Colors.red,
        ),
      );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("إضافة فاتورة جديدة"),
        centerTitle: true,
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Writer Field
                  TextFormField(
                    controller: _writerController,
                    decoration: InputDecoration(
                      labelText: "اسم المحرر",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "مطلوب";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  GestureDetector(
                    onTap: () => _pickDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text(_formatDate(controller.selectedDate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Products Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "المنتجات",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: controller.addItem,
                        icon: const Icon(Icons.add),
                        label: const Text("إضافة منتج"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Products List
                  if (controller.items.isEmpty)
                    const Center(
                      child: Text("لم يتم إضافة منتجات بعد"),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.items.length,
                      itemBuilder: (context, index) {
                        return _InvoiceItemWidget(
                          index: index,
                          controller: controller,
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "الملخص",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: "إجمالي SYP",
                          value: controller.totalSy,
                        ),
                        _SummaryRow(
                          label: "إجمالي USD",
                          value: controller.totalDollar,
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "الإجمالي",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "${controller.totalSy.toStringAsFixed(2)} SYP + ${controller.totalDollar.toStringAsFixed(2)} USD",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Note Field
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "ملاحظات (اختياري)",
                      prefixIcon: const Icon(Icons.note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          child: const Text("إلغاء"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _submit,
                          child: const Text("حفظ الفاتورة"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _InvoiceItemWidget extends StatefulWidget {
  final int index;
  final AddInvoiceController controller;

  const _InvoiceItemWidget({
    required this.index,
    required this.controller,
  });

  @override
  State<_InvoiceItemWidget> createState() => _InvoiceItemWidgetState();
}

class _InvoiceItemWidgetState extends State<_InvoiceItemWidget> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    final item = widget.controller.items[widget.index];
    _nameController = TextEditingController(text: item.name);
    _priceController = TextEditingController(text: item.price.toString());
    _quantityController = TextEditingController(text: item.quantity.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _updateController() {
    widget.controller.updateItem(
      widget.index,
      name: _nameController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      quantity: double.tryParse(_quantityController.text) ?? 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.controller.items[widget.index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "المنتج ${widget.index + 1}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (widget.controller.items.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      widget.controller.removeItem(widget.index);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Product Name
            TextFormField(
              controller: _nameController,
              onChanged: (_) => _updateController(),
              decoration: InputDecoration(
                labelText: "اسم المنتج",
                hintText: "مثال: لاب توب",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "مطلوب";
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            // Price, Quantity, and Currency
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    onChanged: (_) => _updateController(),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "السعر",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "مطلوب";
                      }
                      if (double.tryParse(val) == null) {
                        return "رقم صحيح";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    onChanged: (_) => _updateController(),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "الكمية",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "مطلوب";
                      }
                      if (double.tryParse(val) == null) {
                        return "رقم صحيح";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    const Text(
                      "العملة",
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    SegmentedButton<Currency>(
                      segments: const [
                        ButtonSegment(
                          value: Currency.sy,
                          label: Text("SYP"),
                        ),
                        ButtonSegment(
                          value: Currency.dollar,
                          label: Text("USD"),
                        ),
                      ],
                      selected: {item.currency},
                      onSelectionChanged: (value) {
                        widget.controller.updateItem(
                          widget.index,
                          currency: value.first,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Total Display
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "الإجمالي: ${item.total.toStringAsFixed(2)} ${item.currency.value}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value.toStringAsFixed(2)),
        ],
      ),
    );
  }
}
