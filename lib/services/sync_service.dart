import 'package:naji/database/products_fatoras_db.dart';

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

  Future<void> syncUser(User user) async {
    final old = await userDB.get(user.unified);

    if (old == null) {
      await userDB.insert(user);
      return;
    }

    if (DateTime.parse(
      user.updatedAt.toString(),
    ).isAfter(DateTime.parse(old.updatedAt.toString()))) {
      await userDB.update(user);
    }
  }

  Future<void> syncProduct(Product product) async {
    final old = await productDB.get(product.unified);

    if (old == null) {
      await productDB.insert(product);
      return;
    }

    if (DateTime.parse(
      product.updatedAt.toString(),
    ).isAfter(DateTime.parse(old.updatedAt.toString()))) {
      await productDB.update(product);
    }
  }

  Future<void> syncFatora(Fatora fatora) async {
    final old = await fatoraDB.get(fatora.unified);

    if (old == null) {
      await fatoraDB.insert(fatora);
      return;
    }

    if (DateTime.parse(
      fatora.updatedAt.toString(),
    ).isAfter(DateTime.parse(old.updatedAt.toString()))) {
      await fatoraDB.update(fatora);
    }
  }

  Future<void> syncPayment(Payment payment) async {
    final old = await paymentDB.get(payment.unified);

    if (old == null) {
      await paymentDB.insert(payment);
      return;
    }

    if (DateTime.parse(
      payment.updatedAt.toString(),
    ).isAfter(DateTime.parse(old.updatedAt.toString()))) {
      await paymentDB.update(payment);
    }
  }

  Future<void> syncFatoraProduct(FatoraProduct fp) async {
    final old = await fatoraProductsDB.get(fp.unified);

    if (old == null) {
      await fatoraProductsDB.insert(fp);
      return;
    }

    if (DateTime.parse(
      fp.updatedAt.toString(),
    ).isAfter(DateTime.parse(old.updatedAt.toString()))) {
      await fatoraProductsDB.update(fp);
    }
  }
}
