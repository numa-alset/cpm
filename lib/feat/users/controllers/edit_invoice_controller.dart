import 'package:flutter/material.dart';
import 'package:naji/core/models/currency.dart';
import 'package:naji/core/models/enum_status.dart';
import 'package:naji/core/models/fatora.dart';
import 'package:naji/core/models/fatora_product.dart';
import 'package:naji/core/services/device_service.dart';
import 'package:naji/core/services/id_service.dart';
import 'package:naji/core/services/invoice_service.dart';

/// Represents a draft invoice item before saving to database
class InvoiceItemDraft {
  String name;
  double price;
  double quantity;
  Currency currency;

  InvoiceItemDraft({
    this.name = '',
    this.price = 0.0,
    this.quantity = 1.0,
    this.currency = Currency.sy,
  });

  double get total => price * quantity;

  InvoiceItemDraft copy() => InvoiceItemDraft(
    name: name,
    price: price,
    quantity: quantity,
    currency: currency,
  );
}

class EditInvoiceController extends ChangeNotifier {
  final Fatora invoice;
  final List<FatoraProduct> invoiceProducts;
  final InvoiceService _invoiceService;

  EditInvoiceController({
    required this.invoice,
    required this.invoiceProducts,
    required InvoiceService invoiceService,
  }) : _invoiceService = invoiceService {
    _init();
  }

  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  String? error;
  List<InvoiceItemDraft> items = [];
  late TextEditingController writerController;
  late TextEditingController noteController;

  /// Calculate total for a specific currency
  double getTotalByCurrency(Currency currency) {
    return items
        .where((item) => item.currency == currency)
        .fold<double>(0, (sum, item) => sum + item.total);
  }

  double get totalSy => getTotalByCurrency(Currency.sy);
  double get totalDollar => getTotalByCurrency(Currency.dollar);
  double get grandTotal => totalSy + totalDollar;

  void _init() {
    selectedDate = DateTime.fromMillisecondsSinceEpoch(invoice.date);
    writerController = TextEditingController(text: invoice.writer);
    noteController = TextEditingController(text: invoice.note ?? '');

    // Convert existing products to drafts
    items = invoiceProducts
        .map((product) => InvoiceItemDraft(
              name: product.productName,
              price: product.price,
              quantity: product.quantity,
              currency: product.currency,
            ))
        .toList();

    if (items.isEmpty) {
      addItem();
    }
  }

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void addItem() {
    items.add(InvoiceItemDraft());
    notifyListeners();
  }

  void removeItem(int index) {
    if (items.length > 1) {
      items.removeAt(index);
      notifyListeners();
    }
  }

  void updateItem(
    int index, {
    String? name,
    double? price,
    double? quantity,
    Currency? currency,
  }) {
    if (index >= 0 && index < items.length) {
      final item = items[index];
      if (name != null) item.name = name;
      if (price != null) item.price = price;
      if (quantity != null) item.quantity = quantity;
      if (currency != null) item.currency = currency;
      notifyListeners();
    }
  }

  Future<bool> saveInvoice() async {
    // Validation
    if (items.isEmpty) {
      error = "الرجاء إضافة منتج واحد على الأقل";
      notifyListeners();
      return false;
    }

    for (var item in items) {
      if (item.name.trim().isEmpty) {
        error = "اسم المنتج لا يمكن أن يكون فارغاً";
        notifyListeners();
        return false;
      }
      if (item.price < 0 || item.quantity <= 0) {
        error = "الرجاء التأكد من إدخال سعر وكمية صحيحة لجميع المنتجات";
        notifyListeners();
        return false;
      }
    }

    if (writerController.text.trim().isEmpty) {
      error = "الرجاء إدخال اسم الكاتب";
      notifyListeners();
      return false;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Create updated Fatora
      final updatedFatora = invoice.copyWith(
        writer: writerController.text.trim(),
        date: selectedDate.millisecondsSinceEpoch,
        totalSy: totalSy,
        totalDollar: totalDollar,
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      // Create updated FatoraProducts
      final fatoraProducts = items.map((item) {
        return FatoraProduct(
          unified: IdService.generate(),
          fatoraUnified: updatedFatora.unified,
          productName: item.name.trim(),
          price: item.price,
          quantity: item.quantity,
          currency: item.currency,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          deviceId: DeviceService.deviceIdKey,
          status: Status.notScheduled,
        );
      }).toList();

      await _invoiceService.updateInvoice(updatedFatora, fatoraProducts);

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    writerController.dispose();
    noteController.dispose();
    super.dispose();
  }
}
