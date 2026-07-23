import 'package:naji/core/models/enum_status.dart';
import 'package:naji/core/services/id_service.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';
import 'transaction_service.dart';

class ProductService {
  final ProductRepository _productRepository;
  final TransactionService _transactionService;

  ProductService(this._productRepository, this._transactionService);

  Future<void> createProduct(Product product) async {
    await _transactionService.runTransaction((txn) async {
      // Validate product details
      if (product.name.isEmpty) {
        throw Exception("Product name cannot be empty");
      }
      if (product.price <= 0) {
        throw Exception("Product price must be greater than zero");
      }
      product = product.copyWith(
        unified: generateUUID(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _productRepository.create(product, txn);
    });
  }

  Future<void> updateProduct(Product product) async {
    await _transactionService.runTransaction((txn) async {
      // Validate product details
      if (product.name.isEmpty) {
        throw Exception("Product name cannot be empty");
      }
      if (product.price <= 0) {
        throw Exception("Product price must be greater than zero");
      }
      product = product.copyWith(
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _productRepository.update(product, txn);
    });
  }

  Future<void> deleteProduct(String unified) async {
    await _transactionService.runTransaction((txn) async {
      // Update status to not scheduled before deletion
      final product = await _productRepository.get(unified, txn);
      if (product == null) {
        throw Exception("Product not found");
      }

      await _productRepository.update(
        product.copyWith(status: Status.notScheduled),
        txn,
      );

      await _productRepository.delete(unified, txn);
    });
  }

  Future<List<Product>> searchProducts(String keyword) async {
    return await _transactionService.runTransaction((txn) async {
      return await _productRepository.search(keyword, txn);
    });
  }

  Future<List<Product>> getAllProducts() async {
    return await _transactionService.runTransaction((txn) async {
      return await _productRepository.getAll(txn);
    });
  }

  Future<bool> exists(String unified) async {
    return await _transactionService.runTransaction((txn) async {
      return await _productRepository.exists(unified, txn);
    });
  }

  Future<List<Product>> getNotScheduledProducts() async {
    return await _transactionService.runTransaction((txn) async {
      return await _productRepository.getNotScheduled(txn);
    });
  }

  String generateUUID() {
    return IdService.generate();
  }
}
