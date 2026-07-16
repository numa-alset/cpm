import 'package:naji/dao/fatora_product_dao.dart';
import 'package:naji/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../models/fatora_product.dart';

class FatoraProductRepository extends BaseRepository<FatoraProduct> {
  final FatoraProductDAO _invoiceItemDAO;

  FatoraProductRepository(this._invoiceItemDAO);

  @override
  Future<int> create(FatoraProduct item, {Transaction? txn}) =>
      _invoiceItemDAO.insert(item, txn: txn);

  @override
  Future<int> update(FatoraProduct item, {Transaction? txn}) =>
      _invoiceItemDAO.update(item, txn: txn);

  @override
  Future<int> delete(String unified, {Transaction? txn}) =>
      _invoiceItemDAO.softDelete(unified, txn: txn);

  @override
  Future<FatoraProduct?> get(String unified, {Transaction? txn}) =>
      _invoiceItemDAO.getByUnified(unified, txn: txn);

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
