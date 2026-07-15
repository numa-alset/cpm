import 'package:naji/dao/fatora_product_dao.dart';
import 'package:naji/repositories/base_repository.dart';

import '../models/fatora_product.dart';

class FatoraProductRepository extends BaseRepository<FatoraProduct> {
  final FatoraProductDAO _invoiceItemDAO;

  FatoraProductRepository(this._invoiceItemDAO);

  @override
  Future<int> create(FatoraProduct item) => _invoiceItemDAO.insert(item);

  @override
  Future<int> update(FatoraProduct item) => _invoiceItemDAO.update(item);

  @override
  Future<int> delete(String unified) => _invoiceItemDAO.softDelete(unified);

  @override
  Future<FatoraProduct?> get(String unified) =>
      _invoiceItemDAO.getByUnified(unified);

  Future<List<FatoraProduct>> getByInvoice(String invoiceUnified) =>
      _invoiceItemDAO.getByInvoice(invoiceUnified);

  Future<double> calculateInvoiceTotal(String invoiceUnified) =>
      _invoiceItemDAO.calculateInvoiceTotal(invoiceUnified);

  @override
  Future<List<FatoraProduct>> getAll() {
    return _invoiceItemDAO.getAll();
  }

  @override
  Future<List<FatoraProduct>> getNotScheduled() {
    return _invoiceItemDAO.getNotScheduled();
  }
}
