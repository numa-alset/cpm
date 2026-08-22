import 'package:flutter/material.dart';
import 'package:naji/core/models/currency.dart';
import 'package:naji/core/models/enum_status.dart';
import 'package:naji/core/models/fatora.dart';
import 'package:naji/core/models/fatora_product.dart';
import 'package:naji/core/services/id_service.dart';
import 'package:naji/core/services/invoice_service.dart';
import 'package:naji/core/services/product_service.dart';

class DraftInvoiceItem {
  String name;
  double priceSy;
  double priceDollar;
  double quantity;
  Currency currency;

  DraftInvoiceItem({
    this.name = '',
    this.priceSy = 0.0,
    this.priceDollar = 0.0,
    this.quantity = 1.0,
    this.currency = Currency.sy,
  });

  double getPrice(Currency currency) =>
      currency == Currency.sy ? priceSy : priceDollar;

  double get currentPrice => getPrice(currency);

  void setPrice(Currency currency, double val) {
    if (currency == Currency.sy) {
      priceSy = val;
    } else {
      priceDollar = val;
    }
  }

  double getTotal(Currency currency) => getPrice(currency) * quantity;

  // الإجماليات لكلتا العملتين
  double get totalSy => priceSy * quantity;
  double get totalDollar => priceDollar * quantity;
}

class AddInvoiceController extends ChangeNotifier {
  final String userUnified;
  final InvoiceService _invoiceService;

  AddInvoiceController({
    required this.userUnified,
    required InvoiceService invoiceService,
  }) : _invoiceService = invoiceService
     {
    _init();
  }

  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  bool isProductsLoading = false;
  String? error;

  List<DraftInvoiceItem> items = [];

  // إجمالي الليرة السورية لكل الفاتورة
  double get grandTotalSy => items.fold(0, (sum, item) => sum + item.totalSy);

  // إجمالي الدولار لكل الفاتورة
  double get grandTotalDollar =>
      items.fold(0, (sum, item) => sum + item.totalDollar);

  Future<void> _init() async {
    addItem();
  }



  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void addItem() {
    items.add(DraftInvoiceItem());
    notifyListeners();
  }

  void removeItem(int index) {
    if (items.length > 1) {
      items.removeAt(index);
      notifyListeners();
    }
  }
  //
  // void selectProduct(int index) {
  //   if (index >= 0 && index < items.length) {
  //     items[index].name = product.name;
  //     items[index].priceSy = product.priceSy;
  //     items[index].priceDollar = product.priceDollar;
  //     items[index].currency = product.priceSy > 0 && product.priceDollar <= 0
  //         ? Currency.sy
  //         : product.priceDollar > 0 && product.priceSy <= 0
  //         ? Currency.dollar
  //         : Currency.sy;
  //     notifyListeners();
  //   }
  // }

  void updateItem(
    int index, {
    String? name,
    double? priceSy,
    double? priceDollar,
    double? quantity,
    Currency? currency,
  }) {
    if (index >= 0 && index < items.length) {
      if (name != null) items[index].name = name;
      if (priceSy != null) items[index].priceSy = priceSy;
      if (priceDollar != null) items[index].priceDollar = priceDollar;
      if (quantity != null) items[index].quantity = quantity;
      if (currency != null) items[index].currency = currency;
      notifyListeners();
    }
  }

  // Future<bool> createAndSelectProduct({
  //   required int index,
  //   required String name,
  //   required double priceSy,
  //   required double priceDollar,
  // }) async {
  //   try {
  //     final now = DateTime.now().millisecondsSinceEpoch;
  //     final newProduct = Product(
  //       unified: IdService.generate(),
  //       name: name.trim(),
  //       priceSy: priceSy,
  //       priceDollar: priceDollar,
  //       createdAt: now,
  //       updatedAt: now,
  //       deviceId: "default_device",
  //       status: Status.notScheduled,
  //     );
  //
  //     await _productService.createProduct(newProduct);
  //     availableProducts = await _productService.getAllProducts();
  //     selectProduct(index, newProduct);
  //
  //     notifyListeners();
  //     return true;
  //   } catch (e) {
  //     error = "فشل في إضافة المنتج الجديد: $e";
  //     notifyListeners();
  //     return false;
  //   }
  // }

  Future<bool> saveInvoice({required String writer, String? note}) async {
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
      if (item.priceSy < 0 || item.priceDollar < 0 || item.quantity <= 0) {
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
      final Map<String, DraftInvoiceItem> consolidatedMap = {};

      for (var item in items) {
        final String key = item.name.trim().toLowerCase();

        if (consolidatedMap.containsKey(key)) {
          final existing = consolidatedMap[key]!;
          final double totalQuantity = existing.quantity + item.quantity;

          final double totalSyAmount = existing.totalSy + item.totalSy;
          final double totalDollarAmount =
              existing.totalDollar + item.totalDollar;

          final double weightedPriceSy = totalQuantity > 0
              ? (totalSyAmount / totalQuantity)
              : existing.priceSy;
          final double weightedPriceDollar = totalQuantity > 0
              ? (totalDollarAmount / totalQuantity)
              : existing.priceDollar;

          consolidatedMap[key] = DraftInvoiceItem(
            name: existing.name.isNotEmpty ? existing.name : item.name.trim(),
            priceSy: weightedPriceSy,
            priceDollar: weightedPriceDollar,
            quantity: totalQuantity,
            currency: existing.currency,
          );
        } else {
          consolidatedMap[key] = DraftInvoiceItem(
            name: item.name.trim(),
            priceSy: item.priceSy,
            priceDollar: item.priceDollar,
            quantity: item.quantity,
            currency: item.currency,
          );
        }
      }

      final consolidatedItems = consolidatedMap.values.toList();

      final fatora = Fatora(
        unified: IdService.generate(),
        userUnified: userUnified,
        writer: writer.trim(),
        date: selectedDate.millisecondsSinceEpoch,
        totalSy: grandTotalSy,
        totalDollar: grandTotalDollar,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        createdAt: now,
        updatedAt: now,
        deviceId: "default_device",
        status: Status.notScheduled,
      );

      final fatoraProducts = consolidatedItems.map((item) {
        final itemCurrency = item.currency;

        return FatoraProduct(
          unified: IdService.generate(),
          fatoraUnified: fatora.unified,
          productName: item.name.trim(),
          price: item.getPrice(itemCurrency),
          quantity: item.quantity,
          currency: itemCurrency,
          createdAt: now,
          updatedAt: now,
          deviceId: "default_device",
          status: Status.notScheduled,
        );
      }).toList();

      await _invoiceService.createInvoice(fatora, fatoraProducts);

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
