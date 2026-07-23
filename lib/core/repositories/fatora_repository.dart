import 'package:naji/core/dao/fatora_dao.dart';
import 'package:naji/core/dao/fatora_product_dao.dart';
import 'package:naji/core/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../models/fatora.dart';
import '../models/fatora_product.dart';

class FatoraRepository extends BaseRepository<Fatora> {
  final FatoraDAO _invoiceDAO;
  final FatoraProductDAO _invoiceItemDAO;

  FatoraRepository(this._invoiceDAO, this._invoiceItemDAO);

  @override
  Future<int> create(Fatora fatora, Transaction txn) =>
      _invoiceDAO.insert(fatora, txn);

  @override
  Future<int> update(Fatora fatora, Transaction txn) =>
      _invoiceDAO.update(fatora, txn);

  @override
  Future<int> delete(String unified, Transaction txn) =>
      _invoiceDAO.softDelete(unified, txn);

  @override
  Future<Fatora?> get(String unified, Transaction txn) =>
      _invoiceDAO.getByUnified(unified, txn);

  @override
  Future<List<Fatora>> getAll(Transaction txn) => _invoiceDAO.getAll(txn);

  Future<List<Fatora>> getByUser(String userUnified, Transaction txn) =>
      _invoiceDAO.getByUser(userUnified, txn);

  Future<List<Fatora>> getBetweenDates(
    int startDate,
    int endDate,
    Transaction txn,
  ) => _invoiceDAO.getBetweenDates(startDate, endDate, txn);

  Future<List<Fatora>> getSellInvoices(Transaction txn) =>
      _invoiceDAO.getSellInvoices(txn);

  Future<List<Fatora>> getBuyInvoices(Transaction txn) =>
      _invoiceDAO.getBuyInvoices(txn);

  Future<double> calculateTotal(Transaction txn) =>
      _invoiceDAO.calculateTotalSell(txn);

  Future<Map<Fatora, List<FatoraProduct>>> getCompleteInvoice(
    String unified,
    Transaction txn,
  ) async {
    final fatora = await _invoiceDAO.getByUnified(unified, txn);
    if (fatora == null) return {};
    final items = await _invoiceItemDAO.getByInvoice(unified, txn);
    return {fatora: items};
  }

  @override
  Future<List<Fatora>> getNotScheduled(Transaction txn) {
    return _invoiceDAO.getNotScheduled(txn);
  }
}
