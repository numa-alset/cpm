import 'package:flutter/material.dart';
import 'package:naji/core/models/fatora.dart';
import 'package:naji/core/models/fatora_product.dart';
import 'package:naji/core/models/product.dart';
import 'package:naji/core/services/device_service.dart';
import 'package:naji/core/services/invoice_service.dart';
import 'package:naji/core/services/product_service.dart';

import '../../../../core/models/enum_status.dart';
import '../../../../core/services/id_service.dart';

class DraftInvoiceItem {
  String? productUnified;
  String name;
  double price;
  double quantity;

  DraftInvoiceItem({
    this.productUnified,
    this.name = '',
    this.price = 0.0,
    this.quantity = 1.0,
  });

  double get total => price * quantity;
}

class AddInvoiceController extends ChangeNotifier {
  final String userUnified;
  final InvoiceService _invoiceService;
  final ProductService _productService;

  AddInvoiceController({
    required this.userUnified,
    required InvoiceService invoiceService,
    required ProductService productService,
  }) : _invoiceService = invoiceService,
       _productService = productService {
    _init();
  }

  DateTime selectedDate = DateTime.now();
  InvoiceType selectedType = InvoiceType.sale;
  bool isLoading = false;
  bool isProductsLoading = false;
  String? error;

  List<Product> availableProducts = [];
  List<DraftInvoiceItem> items = [];

  double get grandTotal => items.fold(0, (sum, item) => sum + item.total);

  Future<void> _init() async {
    addItem();
    await loadProducts();
  }

  Future<void> loadProducts() async {
    isProductsLoading = true;
    notifyListeners();
    try {
      availableProducts = await _productService.getAllProducts();
    } catch (e) {
      error = "فشل في تحميل قائمة المنتجات: $e";
    } finally {
      isProductsLoading = false;
      notifyListeners();
    }
  }

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setType(InvoiceType type) {
    selectedType = type;
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

  void selectProduct(int index, Product product) {
    if (index >= 0 && index < items.length) {
      items[index].productUnified = product.unified;
      items[index].name = product.name;
      items[index].price = product.price;
      notifyListeners();
    }
  }

  void updateItem(int index, {String? name, double? price, double? quantity}) {
    if (index >= 0 && index < items.length) {
      if (name != null) items[index].name = name;
      if (price != null) items[index].price = price;
      if (quantity != null) items[index].quantity = quantity;
      notifyListeners();
    }
  }

  /// Creates a new product directly in DB, reloads product list, and selects it for item[index]
  Future<bool> createAndSelectProduct({
    required int index,
    required String name,
    required double price,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final newProduct = Product(
        unified: IdService.generate(),
        name: name.trim(),
        price: price,
        createdAt: now,
        updatedAt: now,
        deviceId: DeviceService.deviceIdKey,
        status: Status.notScheduled,
      );

      await _productService.createProduct(newProduct);

      // Reload products list
      availableProducts = await _productService.getAllProducts();

      // Auto-select this newly created product for the specific row
      selectProduct(index, newProduct);

      notifyListeners();
      return true;
    } catch (e) {
      error = "فشل في إضافة المنتج الجديد: $e";
      notifyListeners();
      return false;
    }
  }

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
      if (item.price <= 0 || item.quantity <= 0) {
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

      // 1. Consolidate duplicate products to prevent database unique constraint conflicts
      final Map<String, DraftInvoiceItem> consolidatedMap = {};

      for (var item in items) {
        // Group by productUnified if present; fallback to trimmed product name
        final String key =
            (item.productUnified != null && item.productUnified!.isNotEmpty)
            ? item.productUnified!
            : item.name.trim().toLowerCase();

        if (consolidatedMap.containsKey(key)) {
          final existing = consolidatedMap[key]!;
          final double totalQuantity = existing.quantity + item.quantity;
          final double totalAmount = existing.total + item.total;

          // Compute weighted average unit price in case prices differ
          final double weightedPrice = totalQuantity > 0
              ? (totalAmount / totalQuantity)
              : existing.price;

          consolidatedMap[key] = DraftInvoiceItem(
            productUnified: existing.productUnified ?? item.productUnified,
            name: existing.name.isNotEmpty ? existing.name : item.name.trim(),
            price: weightedPrice,
            quantity: totalQuantity,
          );
        } else {
          consolidatedMap[key] = DraftInvoiceItem(
            productUnified: item.productUnified,
            name: item.name.trim(),
            price: item.price,
            quantity: item.quantity,
          );
        }
      }

      final consolidatedItems = consolidatedMap.values.toList();

      // 2. Create the Fatora header
      final fatora = Fatora(
        unified: IdService.generate(),
        userUnified: userUnified,
        writer: writer.trim(),
        date: selectedDate.millisecondsSinceEpoch,
        type: selectedType,
        total: grandTotal,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        createdAt: now,
        updatedAt: now,
        deviceId: DeviceService.deviceIdKey,
        status: Status.notScheduled,
      );

      // 3. Map consolidated items to FatoraProduct models
      final fatoraProducts = consolidatedItems.map((item) {
        return FatoraProduct(
          unified: IdService.generate(),
          fatoraUnified: fatora.unified,
          productUnified: item.productUnified ?? IdService.generate(),
          productName: item.name.trim(),
          price: item.price,
          quantity: item.quantity,
          createdAt: now,
          updatedAt: now,
          deviceId: DeviceService.deviceIdKey,
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
