import 'dart:convert';
import 'dart:io';

import '../models/fatora.dart';
import '../models/fatora_product.dart';
import '../models/payment.dart';
import '../models/product.dart';
import '../models/user.dart';
import 'sync_service.dart';

class ImportService {
  final SyncService sync = SyncService();

  Future<void> importBackup(File file) async {
    final json = jsonDecode(await file.readAsString());

    for (var item in json["users"]) {
      await sync.syncUser(User.fromJson(item));
    }

    for (var item in json["products"]) {
      await sync.syncProduct(Product.fromJson(item));
    }

    for (var item in json["fatoras"]) {
      await sync.syncFatora(Fatora.fromJson(item));
    }

    for (var item in json["payments"]) {
      await sync.syncPayment(Payment.fromJson(item));
    }

    for (var item in json["fatoraProducts"]) {
      await sync.syncFatoraProduct(FatoraProduct.fromJson(item));
    }
  }
}
