import 'package:naji/core/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../dao/payment_dao.dart';
import '../models/payment.dart';

class PaymentRepository extends BaseRepository<Payment> {
  final PaymentDAO _paymentDAO;

  PaymentRepository(this._paymentDAO);

  @override
  Future<int> create(Payment payment, Transaction txn) =>
      _paymentDAO.insert(payment, txn);

  @override
  Future<int> update(Payment payment, Transaction txn) =>
      _paymentDAO.update(payment, txn);

  @override
  Future<int> delete(String unified, Transaction txn) =>
      _paymentDAO.softDelete(unified, txn);

  @override
  Future<Payment?> get(String unified, Transaction txn) =>
      _paymentDAO.getByUnified(unified, txn);

  @override
  Future<List<Payment>> getAll(Transaction txn) => _paymentDAO.getAll(txn);

  Future<List<Payment>> getByUser(String userUnified, Transaction txn) =>
      _paymentDAO.getByUser(userUnified, txn);

  Future<List<Payment>> getBetweenDates(
    int startDate,
    int endDate,
    Transaction txn,
  ) => _paymentDAO.getBetweenDates(startDate, endDate, txn);

  Future<double> calculatePaid(String userUnified, Transaction txn) =>
      _paymentDAO.calculatePaid(userUnified, txn);

  @override
  Future<List<Payment>> getNotScheduled(Transaction txn) {
    return _paymentDAO.getNotScheduled(txn);
  }
}
