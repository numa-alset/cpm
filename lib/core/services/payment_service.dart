import 'package:naji/core/models/enum_status.dart';
import 'package:naji/core/services/transaction_service.dart';

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
    await _transactionService.runTransaction((txn) async {
      await _paymentRepository.create(payment, txn);
      await _userRepository.changeBalance(
        payment.userUnified,
        -payment.amount,
        txn,
      );
    });
  }

  Future<void> updatePayment(Payment payment) async {
    await _transactionService.runTransaction((txn) async {
      final old = await _paymentRepository.get(payment.unified, txn);
      if (old == null) return;

      if (DateTime.fromMillisecondsSinceEpoch(
        int.parse(payment.updatedAt.toString()),
      ).isAfter(DateTime.fromMillisecondsSinceEpoch(old.updatedAt))) {
        await _paymentRepository.update(payment, txn);
      }
    });
  }

  Future<void> deletePayment(String unified) async {
    await _transactionService.runTransaction((txn) async {
      final old = await _paymentRepository.get(unified, txn);
      if (old == null) return;
      final updated = old.copyWith(status: Status.notScheduled);
      await _paymentRepository.update(updated, txn);
      await _paymentRepository.delete(unified, txn);
      await _userRepository.changeBalance(old.userUnified, old.amount, txn);
    });
  }

  Future<List<Payment>> getPayments() async {
    return await _transactionService.runTransaction((txn) async {
      return await _paymentRepository.getAll(txn);
    });
  }

  Future<List<Payment>> getPaymentsByUser(String userUnified) async {
    return await _transactionService.runTransaction((txn) async {
      return await _paymentRepository.getByUser(userUnified, txn);
    });
  }

  Future<double> calculatePaid(String userUnified) async {
    return await _transactionService.runTransaction((txn) async {
      return await _paymentRepository.calculatePaid(userUnified, txn);
    });
  }

  Future<List<Payment>> getNotScheduledPayments() async {
    return await _transactionService.runTransaction((txn) async {
      return await _paymentRepository.getNotScheduled(txn);
    });
  }
}
