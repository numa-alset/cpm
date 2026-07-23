import 'package:naji/core/database/products_fatoras_db.dart';
import 'package:naji/core/models/enum_status.dart';
import 'package:sqflite/sqflite.dart';

import '../models/fatora_product.dart';
import 'base_dao.dart';

class FatoraProductDAO extends BaseDAO<FatoraProduct> {
  final FatoraProductsDB fatoraProductDB = FatoraProductsDB();

  @override
  Future<int> insert(FatoraProduct item, Transaction txn) {
    return fatoraProductDB.insert(item, txn);
  }

  @override
  Future<int> update(FatoraProduct item, Transaction txn) {
    return fatoraProductDB.update(item, txn);
  }

  @override
  Future<int> softDelete(String unified, Transaction txn) {
    return fatoraProductDB.delete(unified, txn);
  }

  @override
  Future<FatoraProduct?> getByUnified(String unified, Transaction txn) {
    return fatoraProductDB.get(unified, txn);
  }

  @override
  Future<List<FatoraProduct>> getAll(Transaction txn) {
    return fatoraProductDB.getAll(txn);
  }

  Future<List<FatoraProduct>> getByInvoice(
    String fatoraUnified,
    Transaction txn,
  ) {
    final allFatoraProducts = fatoraProductDB.getAll(txn);
    final filtered = allFatoraProducts.then(
      (products) => products
          .where((product) => product.fatoraUnified == fatoraUnified)
          .toList(),
    );
    return filtered;
  }

  Future<double> calculateInvoiceTotal(String fatoraUnified, Transaction txn) {
    final allFatoraProducts = getByInvoice(fatoraUnified, txn);
    final total = allFatoraProducts.then(
      (products) => products.fold(0.0, (sum, product) => sum + product.total),
    );
    return total;
  }

  @override
  Future<List<FatoraProduct>> getNotScheduled(Transaction txn) {
    final allFatoras = fatoraProductDB.getAll(txn);
    final filteres = allFatoras.then(
      (fatoras) => fatoras
          .where((fatora) => fatora.status == Status.notScheduled)
          .toList(),
    );
    return filteres;
  }
}
