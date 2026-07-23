import 'package:naji/core/dao/fatora_product_dao.dart';
import 'package:naji/core/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../models/fatora_product.dart';

class FatoraProductRepository extends BaseRepository<FatoraProduct> {
  final FatoraProductDAO _invoiceItemDAO;

  FatoraProductRepository(this._invoiceItemDAO);

  @override
  Future<int> create(FatoraProduct item, Transaction txn) =>
      _invoiceItemDAO.insert(item, txn);

  @override
  Future<int> update(FatoraProduct item, Transaction txn) =>
      _invoiceItemDAO.update(item, txn);

  @override
  Future<int> delete(String unified, Transaction txn) =>
      _invoiceItemDAO.softDelete(unified, txn);

  @override
  Future<FatoraProduct?> get(String unified, Transaction txn) =>
      _invoiceItemDAO.getByUnified(unified, txn);

  Future<List<FatoraProduct>> getByInvoice(
    String invoiceUnified,
    Transaction txn,
  ) => _invoiceItemDAO.getByInvoice(invoiceUnified, txn);

  Future<double> calculateInvoiceTotal(
    String invoiceUnified,
    Transaction txn,
  ) => _invoiceItemDAO.calculateInvoiceTotal(invoiceUnified, txn);

  @override
  Future<List<FatoraProduct>> getAll(Transaction txn) {
    return _invoiceItemDAO.getAll(txn);
  }

  @override
  Future<List<FatoraProduct>> getNotScheduled(Transaction txn) {
    return _invoiceItemDAO.getNotScheduled(txn);
  }
}
