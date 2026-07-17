import 'package:naji/core/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../dao/product_dao.dart';
import '../models/product.dart';

class ProductRepository extends BaseRepository<Product> {
  final ProductDAO _productDAO;

  ProductRepository(this._productDAO);

  @override
  Future<int> create(Product product, {Transaction? txn}) =>
      _productDAO.insert(product, txn: txn);

  @override
  Future<int> update(Product product, {Transaction? txn}) =>
      _productDAO.update(product, txn: txn);

  @override
  Future<int> delete(String unified, {Transaction? txn}) =>
      _productDAO.softDelete(unified, txn: txn);

  @override
  Future<Product?> get(String unified, {Transaction? txn}) =>
      _productDAO.getByUnified(unified, txn: txn);

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
