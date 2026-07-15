import 'package:naji/dao/fatora_product_dao.dart';

import '../models/fatora_product.dart';

class FatoraProductRepository {
  final FatoraProductDAO _invoiceItemDAO;

  FatoraProductRepository(this._invoiceItemDAO);

  Future<int> create(FatoraProduct item) => _invoiceItemDAO.insert(item);

  Future<int> update(FatoraProduct item) => _invoiceItemDAO.update(item);

  Future<int> delete(String unified) => _invoiceItemDAO.softDelete(unified);

  Future<FatoraProduct?> get(String unified) =>
      _invoiceItemDAO.getByUnified(unified);

  Future<List<FatoraProduct>> getByInvoice(String invoiceUnified) =>
      _invoiceItemDAO.getByInvoice(invoiceUnified);

  Future<double> calculateInvoiceTotal(String invoiceUnified) =>
      _invoiceItemDAO.calculateInvoiceTotal(invoiceUnified);
}
