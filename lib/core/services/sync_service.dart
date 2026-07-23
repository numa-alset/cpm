import 'package:naji/core/database/products_fatoras_db.dart';
import 'package:naji/core/services/transaction_service.dart';

import '../database/fatora_db.dart';
import '../database/payment_db.dart';
import '../database/product_db.dart';
import '../database/user_db.dart';
import '../models/fatora.dart';
import '../models/fatora_product.dart';
import '../models/payment.dart';
import '../models/product.dart';
import '../models/user.dart';

class SyncService {
  final UserDB userDB = UserDB();
  final ProductDB productDB = ProductDB();
  final FatoraDB fatoraDB = FatoraDB();
  final PaymentDB paymentDB = PaymentDB();
  final FatoraProductsDB fatoraProductsDB = FatoraProductsDB();
  final TransactionService _transactionService = TransactionService();

  Future<void> syncUser(User user) async {
    await _transactionService.runTransaction((txn) async {
      final old = await userDB.get(user.unified, txn);

      if (old == null) {
        await userDB.insert(user, txn);
        return;
      }

      if (DateTime.parse(
        user.updatedAt.toString(),
      ).isAfter(DateTime.parse(old.updatedAt.toString()))) {
        await userDB.update(user, txn);
      }
    });
  }

  Future<void> syncProduct(Product product) async {
    await _transactionService.runTransaction((txn) async {
      final old = await productDB.get(product.unified, txn);

      if (old == null) {
        await productDB.insert(product, txn);
        return;
      }

      if (DateTime.parse(
        product.updatedAt.toString(),
      ).isAfter(DateTime.parse(old.updatedAt.toString()))) {
        await productDB.update(product, txn);
      }
    });
  }

  Future<void> syncFatora(Fatora fatora) async {
    await _transactionService.runTransaction((txn) async {
      final old = await fatoraDB.get(fatora.unified, txn);

      if (old == null) {
        await fatoraDB.insert(fatora, txn);
        return;
      }

      if (DateTime.parse(
        fatora.updatedAt.toString(),
      ).isAfter(DateTime.parse(old.updatedAt.toString()))) {
        await fatoraDB.update(fatora, txn);
      }
    });
  }

  Future<void> syncPayment(Payment payment) async {
    await _transactionService.runTransaction((txn) async {
      final old = await paymentDB.get(payment.unified, txn);

      if (old == null) {
        await paymentDB.insert(payment, txn);
        return;
      }

      if (DateTime.parse(
        payment.updatedAt.toString(),
      ).isAfter(DateTime.parse(old.updatedAt.toString()))) {
        await paymentDB.update(payment, txn);
      }
    });
  }

  Future<void> syncFatoraProduct(FatoraProduct fp) async {
    await _transactionService.runTransaction((txn) async {
      final old = await fatoraProductsDB.get(fp.unified, txn);

      if (old == null) {
        await fatoraProductsDB.insert(fp, txn);
        return;
      }

      if (DateTime.parse(
        fp.updatedAt.toString(),
      ).isAfter(DateTime.parse(old.updatedAt.toString()))) {
        await fatoraProductsDB.update(fp, txn);
      }
    });
  }
}
