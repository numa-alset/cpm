import 'package:naji/repositories/base_repository.dart';

import '../dao/product_dao.dart';
import '../models/product.dart';

class ProductRepository extends BaseRepository<Product> {
  final ProductDAO _productDAO;

  ProductRepository(this._productDAO);

  @override
  Future<int> create(Product product) => _productDAO.insert(product);

  @override
  Future<int> update(Product product) => _productDAO.update(product);

  @override
  Future<int> delete(String unified) => _productDAO.softDelete(unified);

  @override
  Future<Product?> get(String unified) => _productDAO.getByUnified(unified);

  @override
  Future<List<Product>> getAll() => _productDAO.getAll();

  Future<List<Product>> search(String keyword) => _productDAO.search(keyword);

  Future<bool> exists(String unified) => _productDAO.exists(unified);

  Future<int> count() => _productDAO.count();

  @override
  Future<List<Product>> getNotScheduled() {
    return _productDAO.getNotScheduled();
  }
}
