import 'package:naji/core/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../dao/payment_dao.dart';
import '../models/payment.dart';

class PaymentRepository extends BaseRepository<Payment> {
  final PaymentDAO _paymentDAO;

  PaymentRepository(this._paymentDAO);

  @override
  Future<int> create(Payment payment, {Transaction? txn}) =>
      _paymentDAO.insert(payment, txn: txn);

  @override
  Future<int> update(Payment payment, {Transaction? txn}) =>
      _paymentDAO.update(payment, txn: txn);

  @override
  Future<int> delete(String unified, {Transaction? txn}) =>
      _paymentDAO.softDelete(unified, txn: txn);

  @override
  Future<Payment?> get(String unified, {Transaction? txn}) =>
      _paymentDAO.getByUnified(unified, txn: txn);

  @override
  Future<List<Payment>> getAll() => _paymentDAO.getAll();

  Future<List<Payment>> getByUser(String userUnified) =>
      _paymentDAO.getByUser(userUnified);

  Future<List<Payment>> getBetweenDates(int startDate, int endDate) =>
      _paymentDAO.getBetweenDates(startDate, endDate);

  Future<double> calculatePaid(String userUnified) =>
      _paymentDAO.calculatePaid(userUnified);

  @override
  Future<List<Payment>> getNotScheduled() {
    return _paymentDAO.getNotScheduled();
  }
}
