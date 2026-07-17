import 'package:naji/core/models/enum_status.dart';
import 'package:sqflite/sqflite.dart';

import '../database/product_db.dart';
import '../models/product.dart';
import 'base_dao.dart';

class ProductDAO extends BaseDAO<Product> {
  final ProductDB productDB = ProductDB();

  @override
  Future<int> insert(Product item, {Transaction? txn}) {
    return productDB.insert(item, txn: txn);
  }

  @override
  Future<int> update(Product item, {Transaction? txn}) {
    return productDB.update(item, txn);
  }

  @override
  Future<int> softDelete(String unified, {Transaction? txn}) {
    return productDB.delete(unified, txn);
  }

  @override
  Future<Product?> getByUnified(String unified, {Transaction? txn}) {
    return productDB.get(unified);
  }

  @override
  Future<List<Product>> getAll({Transaction? txn}) {
    return productDB.getAll(txn: txn);
  }

  Future<List<Product>> search(String keyword) {
    final allProducts = productDB.getAll();
    final filtered = allProducts.then(
      (products) => products
          .where(
            (product) =>
                product.name.toLowerCase().contains(keyword.toLowerCase()),
          )
          .toList(),
    );
    return filtered;
  }

  Future<bool> exists(String unified) {
    return productDB.get(unified).then((product) => product != null);
  }

  Future<int> count() {
    return productDB.getAll().then((products) => products.length);
  }

  @override
  Future<List<Product>> getNotScheduled({Transaction? txn}) {
    final allFatoras = productDB.getAll();
    final filteres = allFatoras.then(
      (fatoras) => fatoras
          .where((fatora) => fatora.status == Status.notScheduled)
          .toList(),
    );
    return filteres;
  }
}
