import 'dart:convert';
import 'dart:io';

import 'package:naji/database/products_fatoras_db.dart';
import 'package:path_provider/path_provider.dart';

import '../database/fatora_db.dart';
import '../database/payment_db.dart';
import '../database/product_db.dart';
import '../database/user_db.dart';

class BackupService {
  final UserDB _userDB = UserDB();
  final ProductDB _productDB = ProductDB();
  final FatoraDB _fatoraDB = FatoraDB();
  final PaymentDB _paymentDB = PaymentDB();
  final FatoraProductsDB _fatoraProductsDB = FatoraProductsDB();

  Future<File> exportBackup() async {
    final users = await _userDB.getAll();
    final products = await _productDB.getAll();
    final fatoras = await _fatoraDB.getAll();
    final payments = await _paymentDB.getAll();

    final fatoraProducts = <dynamic>[];

    for (var f in fatoras) {
      fatoraProducts.addAll(await _fatoraProductsDB.getByFatora(f.unified));
    }

    final backup = {
      "version": 1,
      "createdAt": DateTime.now().toIso8601String(),
      "users": users.map((e) => e.toJson()).toList(),
      "products": products.map((e) => e.toJson()).toList(),
      "fatoras": fatoras.map((e) => e.toJson()).toList(),
      "payments": payments.map((e) => e.toJson()).toList(),
      "fatoraProducts": fatoraProducts.map((e) => e.toJson()).toList(),
    };

    final dir = await getApplicationDocumentsDirectory();

    final file = File("${dir.path}/backup.json");

    await file.writeAsString(
      const JsonEncoder.withIndent("  ").convert(backup),
    );

    return file;
  }
}
