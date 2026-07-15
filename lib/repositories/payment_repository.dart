import '../dao/payment_dao.dart';
import '../models/payment.dart';

class PaymentRepository {
  final PaymentDAO _paymentDAO;

  PaymentRepository(this._paymentDAO);

  Future<int> create(Payment payment) => _paymentDAO.insert(payment);

  Future<int> update(Payment payment) => _paymentDAO.update(payment);

  Future<int> delete(String unified) => _paymentDAO.softDelete(unified);

  Future<Payment?> get(String unified) => _paymentDAO.getByUnified(unified);

  Future<List<Payment>> getAll() => _paymentDAO.getAll();

  Future<List<Payment>> getByUser(String userUnified) =>
      _paymentDAO.getByUser(userUnified);

  Future<List<Payment>> getBetweenDates(int startDate, int endDate) =>
      _paymentDAO.getBetweenDates(startDate, endDate);

  Future<double> calculatePaid(String userUnified) =>
      _paymentDAO.calculatePaid(userUnified);
}
