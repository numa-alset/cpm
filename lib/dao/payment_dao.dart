import 'package:naji/database/payment_db.dart';

import '../models/payment.dart';
import 'base_dao.dart';

class PaymentDAO extends BaseDAO<Payment> {
  final PaymentDB paymentDB = PaymentDB();

  @override
  Future<int> insert(Payment item) {
    return paymentDB.insert(item);
  }

  @override
  Future<int> update(Payment item) {
    return paymentDB.update(item);
  }

  @override
  Future<int> softDelete(String unified) {
    return paymentDB.delete(unified);
  }

  @override
  Future<Payment?> getByUnified(String unified) {
    return paymentDB.get(unified);
  }

  @override
  Future<List<Payment>> getAll() {
    return paymentDB.getAll();
  }

  Future<List<Payment>> getByUser(String userUnified) {
    final allPayments = paymentDB.getAll();
    final filtered = allPayments.then(
      (payments) => payments
          .where((payment) => payment.userUnified == userUnified)
          .toList(),
    );
    return filtered;
  }

  Future<List<Payment>> getBetweenDates(int startDate, int endDate) {
    final allPayments = paymentDB.getAll();
    final filtered = allPayments.then(
      (payments) => payments
          .where(
            (payment) => payment.date >= startDate && payment.date <= endDate,
          )
          .toList(),
    );
    return filtered;
  }

  Future<double> calculatePaid(String userUnified) {
    final userPayments = getByUser(userUnified);
    final totalPaid = userPayments.then(
      (payments) => payments.fold(0.0, (sum, payment) => sum + payment.amount),
    );
    return totalPaid;
  }
}
