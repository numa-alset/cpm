import 'package:naji/dao/fatora_dao.dart';
import 'package:naji/dao/fatora_product_dao.dart';
import 'package:naji/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../models/fatora.dart';
import '../models/fatora_product.dart';

class FatoraRepository extends BaseRepository<Fatora> {
  final FatoraDAO _invoiceDAO;
  final FatoraProductDAO _invoiceItemDAO;

  FatoraRepository(this._invoiceDAO, this._invoiceItemDAO);

  @override
  Future<int> create(Fatora fatora, {Transaction? txn}) =>
      _invoiceDAO.insert(fatora, txn: txn);

  @override
  Future<int> update(Fatora fatora, {Transaction? txn}) =>
      _invoiceDAO.update(fatora, txn: txn);

  @override
  Future<int> delete(String unified, {Transaction? txn}) =>
      _invoiceDAO.softDelete(unified, txn: txn);

  @override
  Future<Fatora?> get(String unified, {Transaction? txn}) =>
      _invoiceDAO.getByUnified(unified, txn: txn);

  @override
  Future<List<Fatora>> getAll() => _invoiceDAO.getAll();

  Future<List<Fatora>> getByUser(String userUnified) =>
      _invoiceDAO.getByUser(userUnified);

  Future<List<Fatora>> getBetweenDates(int startDate, int endDate) =>
      _invoiceDAO.getBetweenDates(startDate, endDate);

  Future<List<Fatora>> getSellInvoices() => _invoiceDAO.getSellInvoices();

  Future<List<Fatora>> getBuyInvoices() => _invoiceDAO.getBuyInvoices();

  Future<double> calculateTotal() => _invoiceDAO.calculateTotalSell();

  Future<Map<Fatora, List<FatoraProduct>>> getCompleteInvoice(
    String unified,
  ) async {
    final fatora = await _invoiceDAO.getByUnified(unified);
    if (fatora == null) return {};
    final items = await _invoiceItemDAO.getByInvoice(unified);
    return {fatora: items};
  }

  @override
  Future<List<Fatora>> getNotScheduled() {
    return _invoiceDAO.getNotScheduled();
  }
}
