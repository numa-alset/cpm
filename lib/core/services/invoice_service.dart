import 'package:naji/core/models/enum_status.dart';
import 'package:naji/core/services/id_service.dart';

import '../models/fatora.dart';
import '../models/fatora_product.dart';
import '../repositories/fatora_product_repository.dart';
import '../repositories/fatora_repository.dart';
import '../repositories/user_repository.dart';
import 'transaction_service.dart';

class InvoiceService {
  final FatoraRepository _fatoraRepository;
  final FatoraProductRepository _fatoraProductRepository;
  final UserRepository _userRepository;
  final TransactionService _transactionService;

  InvoiceService(
    this._fatoraRepository,
    this._fatoraProductRepository,
    this._userRepository,
    this._transactionService,
  );

  Future<void> createInvoice(Fatora fatora, List<FatoraProduct> items) async {
    await _transactionService.runTransaction((txn) async {
      fatora = fatora.copyWith(
        unified: generateUUID(),
        status: Status.notScheduled,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _fatoraRepository.create(fatora, txn: txn);
      for (var item in items) {
        item = item.copyWith(
          unified: generateUUID(),
          status: Status.notScheduled,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await _fatoraProductRepository.create(item, txn: txn);
      }
      double total = items.fold(0, (sum, item) => sum + item.total);
      await _userRepository.changeBalance(fatora.userUnified, total, txn);
    });
  }

  Future<void> updateInvoice(Fatora fatora, List<FatoraProduct> items) async {
    await _transactionService.runTransaction((txn) async {
      final oldFatora = await _fatoraRepository.get(fatora.unified);
      if (oldFatora == null) {
        throw Exception("Invoice not found");
      }

      final oldItems = await _fatoraProductRepository.getByInvoice(
        fatora.unified,
      );
      double oldTotal = oldItems.fold(0, (sum, item) => sum + item.total);
      await _userRepository.changeBalance(
        oldFatora.userUnified,
        -oldTotal,
        txn,
      );

      for (var oldItem in oldItems) {
        await _fatoraProductRepository.delete(oldItem.unified, txn: txn);
      }

      fatora = fatora.copyWith(
        status: Status.notScheduled,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _fatoraRepository.update(fatora, txn: txn);

      for (var item in items) {
        item = item.copyWith(
          unified: generateUUID(),
          status: Status.notScheduled,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await _fatoraProductRepository.create(item, txn: txn);
      }

      double newTotal = items.fold(0, (sum, item) => sum + item.total);
      await _userRepository.changeBalance(fatora.userUnified, newTotal, txn);
    });
  }

  Future<void> deleteInvoice(String unified) async {
    await _transactionService.runTransaction((txn) async {
      final fatora = await _fatoraRepository.get(unified);
      if (fatora == null) {
        throw Exception("Invoice not found");
      }

      final items = await _fatoraProductRepository.getByInvoice(unified);
      double total = items.fold(0, (sum, item) => sum + item.total);
      await _userRepository.changeBalance(fatora.userUnified, -total, txn);

      // Update status to not scheduled
      await _fatoraRepository.update(
        fatora.copyWith(status: Status.notScheduled),
        txn: txn,
      );

      await _fatoraRepository.delete(unified, txn: txn);
      for (var item in items) {
        await _fatoraProductRepository.delete(item.unified, txn: txn);
      }
    });
  }

  Future<Fatora?> getInvoice(String unified) async {
    return await _fatoraRepository.get(unified);
  }

  Future<List<Fatora>> getInvoices() async {
    return await _fatoraRepository.getAll();
  }

  Future<List<Fatora>> getInvoicesByUser(String userUnified) async {
    return await _fatoraRepository.getByUser(userUnified);
  }

  Future<double> calculateInvoice(String unified) async {
    return await _fatoraProductRepository.calculateInvoiceTotal(unified);
  }

  String generateUUID() {
    return IdService.generate();
  }
}
