import '../models/payment.dart';
import '../repositories/payment_repository.dart';
import '../repositories/user_repository.dart';

class PaymentService {
  final PaymentRepository _paymentRepository;
  final UserRepository _userRepository;

  PaymentService(this._paymentRepository, this._userRepository);

  Future<void> createPayment(Payment payment) async {
    try {
      await _paymentRepository.create(payment);
      await _userRepository.changeBalance(payment.userUnified, -payment.amount);
    } catch (e) {
      throw Exception("Failed to create payment: $e");
    }
  }

  Future<void> updatePayment(Payment payment) async {
    final old = await _paymentRepository.get(payment.unified);
    if (old == null) return;

    try {
      if (DateTime.fromMillisecondsSinceEpoch(
        int.parse(payment.updatedAt.toString()),
      ).isAfter(DateTime.fromMillisecondsSinceEpoch(old.updatedAt))) {
        await _paymentRepository.update(payment);
      }
    } catch (e) {
      throw Exception("Failed to update payment: $e");
    }
  }

  Future<void> deletePayment(String unified) async {
    // Delete payment logic
    final old = await _paymentRepository.get(unified);
    if (old == null) return;
    try {
      await _paymentRepository.delete(unified);
      await _userRepository.changeBalance(old.userUnified, old.amount);
    } catch (e) {
      throw Exception("Failed to create payment: $e");
    }
  }

  Future<List<Payment>> getPayments() async {
    return await _paymentRepository.getAll();
  }

  Future<List<Payment>> getPaymentsByUser(String userUnified) async {
    return await _paymentRepository.getByUser(userUnified);
  }

  Future<double> calculatePaid(String userUnified) async {
    return await _paymentRepository.calculatePaid(userUnified);
  }
}
