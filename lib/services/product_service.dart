import 'package:naji/services/id_service.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductService {
  final ProductRepository _productRepository;

  ProductService(this._productRepository);

  Future<void> createProduct(Product product) async {
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
    await _productRepository.create(product);
  }

  Future<void> updateProduct(Product product) async {
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
    await _productRepository.update(product);
  }

  Future<void> deleteProduct(String unified) async {
    await _productRepository.delete(unified);
  }

  Future<List<Product>> searchProducts(String keyword) async {
    return await _productRepository.search(keyword);
  }

  Future<List<Product>> getAllProducts() async {
    return await _productRepository.getAll();
  }

  Future<bool> exists(String unified) async {
    return await _productRepository.exists(unified);
  }

  String generateUUID() {
    return IdService.generate();
  }
}
