import 'package:naji/core/models/enum_status.dart';
import 'package:naji/core/services/transaction_service.dart';
import 'package:sqflite/sqflite.dart';

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
      final newPayment = payment.copyWith(status: Status.notScheduled);

      await _paymentRepository.create(newPayment, txn);

      // Payment decreases the user's balance.
      await _userRepository.changeBalance(
        newPayment.userUnified,
        -newPayment.amount,
        newPayment.currency,
        txn,
      );
    });
  }

  Future<void> updatePayment(Payment payment) async {
    await _transactionService.runTransaction((txn) async {
      final old = await _paymentRepository.get(payment.unified, txn);

      if (old == null) return;

      // Ignore an older update.
      if (payment.updatedAt <= old.updatedAt) {
        return;
      }

      /*
       * First undo the effect of the OLD payment.
       *
       * createPayment() subtracts the payment amount from
       * the user's balance, so here we add it back.
       */
      await _userRepository.changeBalance(
        old.userUnified,
        old.amount,
        old.currency,
        txn,
      );

      /*
       * Then apply the NEW payment.
       *
       * This subtracts the new amount using the NEW currency.
       *
       * This is important when, for example:
       *
       * OLD: 100,000 SY
       * NEW: 100 USD
       *
       * The old 100,000 SY is restored and 100 USD is deducted.
       */
      await _userRepository.changeBalance(
        payment.userUnified,
        -payment.amount,
        payment.currency,
        txn,
      );

      /*
       * Save the updated payment and mark it as not scheduled
       * because it needs to be synchronized again.
       */
      await _paymentRepository.update(
        payment.copyWith(status: Status.notScheduled),
        txn,
      );
    });
  }

  Future<void> deletePayment(String unified) async {
    await _transactionService.runTransaction((txn) async {
      final old = await _paymentRepository.get(unified, txn);

      if (old == null) return;

      /*
       * The payment originally decreased the balance,
       * so deleting it restores the amount.
       */
      await _userRepository.changeBalance(
        old.userUnified,
        old.amount,
        old.currency,
        txn,
      );

      /*
       * Mark it as not scheduled before deleting if this is
       * part of your sync strategy.
       */
      final updated = old.copyWith(status: Status.notScheduled);

      await _paymentRepository.update(updated, txn);

      await _paymentRepository.delete(unified, txn);
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

  Future<int> markScheduled(Payment payment, Transaction txn) async {
    return await _paymentRepository.markSync(payment.unified, txn);
  }
}
