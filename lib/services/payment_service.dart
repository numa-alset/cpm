import 'package:naji/models/enum_status.dart';
import 'package:naji/services/transaction_service.dart';

import '../models/payment.dart';
import '../repositories/payment_repository.dart';
import '../repositories/user_repository.dart';

class PaymentService {
  final PaymentRepository _paymentRepository;
  final UserRepository _userRepository;
  final TransactionService _transactionService;

  PaymentService(
    this._paymentRepository,
    this._userRepository,
    this._transactionService,
  );

  Future<void> createPayment(Payment payment) async {
    await _transactionService.runTransaction(() async {
      await _paymentRepository.create(payment);
      await _userRepository.changeBalance(payment.userUnified, -payment.amount);
    });
  }

  Future<void> updatePayment(Payment payment) async {
    await _transactionService.runTransaction(() async {
      final old = await _paymentRepository.get(payment.unified);
      if (old == null) return;

      if (DateTime.fromMillisecondsSinceEpoch(
        int.parse(payment.updatedAt.toString()),
      ).isAfter(DateTime.fromMillisecondsSinceEpoch(old.updatedAt))) {
        await _paymentRepository.update(payment);
      }
    });
  }

  Future<void> deletePayment(String unified) async {
    await _transactionService.runTransaction(() async {
      final old = await _paymentRepository.get(unified);
      if (old == null) return;
      final updated = old.copyWith(status: Status.notScheduled);
      await _paymentRepository.update(updated);
      await _paymentRepository.delete(unified);
      await _userRepository.changeBalance(old.userUnified, old.amount);
    });
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
