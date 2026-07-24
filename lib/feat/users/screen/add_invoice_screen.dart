import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:naji/core/models/fatora.dart';
import 'package:naji/core/models/product.dart';
import 'package:naji/core/services/invoice_service.dart';
import 'package:naji/core/services/product_service.dart';
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
        productService: GetIt.I<ProductService>(),
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
                                  // Invoice Type Selector
                                  const Text(
                                    "نوع الفاتورة",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SegmentedButton<InvoiceType>(
                                    segments: const [
                                      ButtonSegment(
                                        value: InvoiceType.sale,
                                        label: Text("مبيعات"),
                                        icon: Icon(Icons.sell_outlined),
                                      ),
                                      ButtonSegment(
                                        value: InvoiceType.purchase,
                                        label: Text("مشتريات"),
                                        icon: Icon(Icons.shopping_bag_outlined),
                                      ),
                                    ],
                                    selected: {controller.selectedType},
                                    onSelectionChanged: (set) {
                                      controller.setType(set.first);
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Date & Writer Row
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
                                                    val.trim().isEmpty) {
                                                  return "مطلوب";
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Notes Field
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

                          // Section Title & Add Item Row Button
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

                          // Products Item List
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

                  // Bottom Total Summary & Save Bar
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
                                "الإجمالي الكلي:",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                controller.grandTotal.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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
  late TextEditingController _priceController;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.item.price > 0 ? widget.item.price.toString() : '',
    );
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _ProductItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep controllers synced if value updated from auto-selection
    if (widget.item.price.toString() != _priceController.text &&
        double.tryParse(_priceController.text) != widget.item.price) {
      _priceController.text = widget.item.price > 0
          ? widget.item.price.toString()
          : '';
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _showCreateProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("إضافة منتج جديد للمخزن"),
          content: Form(
            key: formKey,
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
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: "السعر الافتراضي",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final price = double.tryParse(v ?? '');
                    if (price == null || price <= 0) return "مبلغ غير صحيح";
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
                if (!formKey.currentState!.validate()) return;
                final name = nameController.text.trim();
                final price = double.parse(priceController.text.trim());

                Navigator.pop(dialogContext);

                final controller = context.read<AddInvoiceController>();
                final success = await controller.createAndSelectProduct(
                  index: widget.index,
                  name: name,
                  price: price,
                );

                if (success) {
                  _priceController.text = price.toString();
                }
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
    final controller = context.read<AddInvoiceController>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey.shade200,
                  child: Text(
                    "${widget.index + 1}",
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 8),

                // Searchable Product Dropdown / Autocomplete
                Expanded(
                  child: Autocomplete<Product>(
                    displayStringForOption: (Product p) => p.name,
                    initialValue: TextEditingValue(text: widget.item.name),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final query = textEditingValue.text.trim().toLowerCase();
                      if (query.isEmpty) {
                        return controller.availableProducts;
                      }
                      return controller.availableProducts.where((Product p) {
                        return p.name.toLowerCase().contains(query);
                      });
                    },
                    onSelected: (Product selectedProduct) {
                      controller.selectProduct(widget.index, selectedProduct);
                      _priceController.text = selectedProduct.price.toString();
                    },
                    fieldViewBuilder:
                        (
                          context,
                          fieldController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          return TextFormField(
                            controller: fieldController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              hintText: "ابحث أو اختر منتج...",
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            onChanged: (val) {
                              controller.updateItem(widget.index, name: val);
                            },
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return "مطلوب";
                              }
                              return null;
                            },
                          );
                        },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topRight,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            width: MediaQuery.of(context).size.width * 0.65,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final Product option = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  title: Text(option.name),
                                  subtitle: Text("${option.price} د.ع"),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 4),

                // Button to create a new product if it doesn't exist
                IconButton(
                  tooltip: "إضافة منتج جديد",
                  icon: const Icon(Icons.add_box_outlined, color: Colors.blue),
                  onPressed: () => _showCreateProductDialog(context),
                ),

                if (!widget.isOnlyItem)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => controller.removeItem(widget.index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Price Field
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      labelText: "السعر",
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final price = double.tryParse(val) ?? 0.0;
                      controller.updateItem(widget.index, price: price);
                    },
                    validator: (val) {
                      final price = double.tryParse(val ?? '');
                      if (price == null || price <= 0) {
                        return "خطأ";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Quantity Field
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      labelText: "الكمية",
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final qty = double.tryParse(val) ?? 0.0;
                      controller.updateItem(widget.index, quantity: qty);
                    },
                    validator: (val) {
                      final qty = double.tryParse(val ?? '');
                      if (qty == null || qty <= 0) {
                        return "خطأ";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Item Subtotal
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "المجموع",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      widget.item.total.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
