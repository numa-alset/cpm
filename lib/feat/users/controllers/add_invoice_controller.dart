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

class AddInvoiceController extends ChangeNotifier {
  final String userUnified;
  final InvoiceService _invoiceService;

  AddInvoiceController({
    required this.userUnified,
    required InvoiceService invoiceService,
  }) : _invoiceService = invoiceService {
    _init();
  }

  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  String? error;

  List<InvoiceItemDraft> items = [];

  /// Calculate total for a specific currency
  double getTotalByCurrency(Currency currency) {
    return items
        .where((item) => item.currency == currency)
        .fold<double>(0, (sum, item) => sum + item.total);
  }

  double get totalSy => getTotalByCurrency(Currency.sy);
  double get totalDollar => getTotalByCurrency(Currency.dollar);
  double get grandTotal => totalSy + totalDollar;

  Future<void> _init() async {
    addItem();
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

  Future<bool> saveInvoice({required String writer, String? note}) async {
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

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Create Fatora (invoice header)
      final fatora = Fatora(
        unified: IdService.generate(),
        userUnified: userUnified,
        writer: writer.trim(),
        date: selectedDate.millisecondsSinceEpoch,
        totalSy: totalSy,
        totalDollar: totalDollar,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        createdAt: now,
        updatedAt: now,
        deviceId: await DeviceService().getDeviceId(),
        status: Status.notScheduled,
      );

      // Create FatoraProducts (invoice items)
      final fatoraProducts = items.map((item) async {
        return FatoraProduct(
          unified: IdService.generate(),
          fatoraUnified: fatora.unified,
          productName: item.name.trim(),
          price: item.price,
          quantity: item.quantity,
          currency: item.currency,
          createdAt: now,
          updatedAt: now,
          deviceId: await DeviceService().getDeviceId(),
          status: Status.notScheduled,
        );
      }).toList();

      await _invoiceService.createInvoice(
        fatora,
        await Future.wait(fatoraProducts),
      );

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
}
