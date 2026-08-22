// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:naji/core/models/product.dart';
// import 'package:naji/core/services/product_service.dart';
//
// class ProductsController extends ChangeNotifier {
//   final ProductService _productService;
//
//   ProductsController({required ProductService productService})
//     : _productService = productService;
//
//   List<Product> products = [];
//   bool isLoading = true;
//   String? error;
//
//   String _currentKeyword = '';
//   Timer? _debounce;
//
//   Future<void> loadProducts() async {
//     isLoading = true;
//     error = null;
//     notifyListeners();
//
//     try {
//       if (_currentKeyword.trim().isEmpty) {
//         products = await _productService.getAllProducts();
//       } else {
//         products = await _productService.searchProducts(_currentKeyword.trim());
//       }
//
//       // Sort alphabetically or by newest (adjust as you prefer)
//       products.sort((a, b) => a.name.compareTo(b.name));
//     } catch (e) {
//       error = "حدث خطأ أثناء تحميل المنتجات: $e";
//     } finally {
//       isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   void search(String keyword) {
//     _currentKeyword = keyword;
//
//     // Debounce to avoid querying the DB on every single keystroke
//     if (_debounce?.isActive ?? false) _debounce!.cancel();
//     _debounce = Timer(const Duration(milliseconds: 300), () {
//       loadProducts();
//     });
//   }
//
//   Future<bool> deleteProduct(String unified) async {
//     try {
//       await _productService.deleteProduct(unified);
//       products.removeWhere((p) => p.unified == unified);
//       notifyListeners();
//       return true;
//     } catch (e) {
//       error = "فشل في حذف المنتج: $e";
//       notifyListeners();
//       return false;
//     }
//   }
//
//   Future<bool> saveProduct(Product product, {bool isEditing = false}) async {
//     try {
//       if (isEditing) {
//         await _productService.updateProduct(product);
//       } else {
//         await _productService.createProduct(product);
//       }
//       // Reload the list to get the updated DB state and sorting
//       await loadProducts();
//       return true;
//     } catch (e) {
//       error = "فشل في حفظ المنتج: $e";
//       notifyListeners();
//       return false;
//     }
//   }
// }
