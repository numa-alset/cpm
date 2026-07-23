import 'package:naji/core/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../dao/product_dao.dart';
import '../models/product.dart';

class ProductRepository extends BaseRepository<Product> {
  final ProductDAO _productDAO;

  ProductRepository(this._productDAO);

  @override
  Future<int> create(Product product, Transaction txn) =>
      _productDAO.insert(product, txn);

  @override
  Future<int> update(Product product, Transaction txn) =>
      _productDAO.update(product, txn);

  @override
  Future<int> delete(String unified, Transaction txn) =>
      _productDAO.softDelete(unified, txn);

  @override
  Future<Product?> get(String unified, Transaction txn) =>
      _productDAO.getByUnified(unified, txn);

  @override
  Future<List<Product>> getAll(Transaction txn) => _productDAO.getAll(txn);

  Future<List<Product>> search(String keyword, Transaction txn) =>
      _productDAO.search(keyword, txn);

  Future<bool> exists(String unified, Transaction txn) =>
      _productDAO.exists(unified, txn);

  Future<int> count(Transaction txn) => _productDAO.count(txn);

  @override
  Future<List<Product>> getNotScheduled(Transaction txn) {
    return _productDAO.getNotScheduled(txn);
  }
}
