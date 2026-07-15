import 'package:naji/database/products_fatoras_db.dart';

import '../models/fatora_product.dart';
import 'base_dao.dart';

class FatoraProductDAO extends BaseDAO<FatoraProduct> {
  final FatoraProductsDB fatoraProductDB = FatoraProductsDB();

  @override
  Future<int> insert(FatoraProduct item) {
    return fatoraProductDB.insert(item);
  }

  @override
  Future<int> update(FatoraProduct item) {
    return fatoraProductDB.update(item);
  }

  @override
  Future<int> softDelete(String unified) {
    return fatoraProductDB.delete(unified);
  }

  @override
  Future<FatoraProduct?> getByUnified(String unified) {
    return fatoraProductDB.get(unified);
  }

  @override
  Future<List<FatoraProduct>> getAll() {
    return fatoraProductDB.getAll();
  }

  Future<List<FatoraProduct>> getByInvoice(String fatoraUnified) {
    final allFatoraProducts = fatoraProductDB.getAll();
    final filtered = allFatoraProducts.then(
      (products) => products
          .where((product) => product.fatoraUnified == fatoraUnified)
          .toList(),
    );
    return filtered;
  }

  Future<double> calculateInvoiceTotal(String fatoraUnified) {
    final allFatoraProducts = getByInvoice(fatoraUnified);
    final total = allFatoraProducts.then(
      (products) => products.fold(0.0, (sum, product) => sum + product.total),
    );
    return total;
  }
}
