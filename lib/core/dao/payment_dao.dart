import 'package:naji/core/database/payment_db.dart';
import 'package:naji/core/models/enum_status.dart';
import 'package:sqflite/sqflite.dart';

import '../models/payment.dart';
import 'base_dao.dart';

class PaymentDAO extends BaseDAO<Payment> {
  final PaymentDB paymentDB = PaymentDB();

  @override
  Future<int> insert(Payment item, Transaction txn) {
    return paymentDB.insert(item, txn);
  }

  @override
  Future<int> update(Payment item, Transaction txn) {
    return paymentDB.update(item, txn);
  }

  @override
  Future<int> softDelete(String unified, Transaction txn) {
    return paymentDB.delete(unified, txn);
  }

  @override
  Future<Payment?> getByUnified(String unified, Transaction txn) {
    return paymentDB.get(unified, txn);
  }

  @override
  Future<List<Payment>> getAll(Transaction txn) {
    return paymentDB.getAll(txn);
  }

  Future<List<Payment>> getByUser(String userUnified, Transaction txn) {
    final allPayments = paymentDB.getAll(txn);
    final filtered = allPayments.then(
      (payments) => payments
          .where((payment) => payment.userUnified == userUnified)
          .toList(),
    );
    return filtered;
  }

  Future<List<Payment>> getBetweenDates(
    int startDate,
    int endDate,
    Transaction txn,
  ) {
    final allPayments = paymentDB.getAll(txn);
    final filtered = allPayments.then(
      (payments) => payments
          .where(
            (payment) => payment.date >= startDate && payment.date <= endDate,
          )
          .toList(),
    );
    return filtered;
  }

  Future<double> calculatePaid(String userUnified, Transaction txn) {
    final userPayments = getByUser(userUnified, txn);
    final totalPaid = userPayments.then(
      (payments) => payments.fold(0.0, (sum, payment) => sum + payment.amount),
    );
    return totalPaid;
  }

  @override
  Future<List<Payment>> getNotScheduled(Transaction txn) {
    final allFatoras = paymentDB.getAll(txn);
    final filteres = allFatoras.then(
      (fatoras) => fatoras
          .where((fatora) => fatora.status == Status.notScheduled)
          .toList(),
    );
    return filteres;
  }
}
