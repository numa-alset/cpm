import 'package:naji/repositories/base_repository.dart';

import '../dao/payment_dao.dart';
import '../models/payment.dart';

class PaymentRepository extends BaseRepository<Payment> {
  final PaymentDAO _paymentDAO;

  PaymentRepository(this._paymentDAO);

  @override
  Future<int> create(Payment payment) => _paymentDAO.insert(payment);

  @override
  Future<int> update(Payment payment) => _paymentDAO.update(payment);

  @override
  Future<int> delete(String unified) => _paymentDAO.softDelete(unified);

  @override
  Future<Payment?> get(String unified) => _paymentDAO.getByUnified(unified);

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
