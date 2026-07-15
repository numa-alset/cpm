import 'package:naji/database/fatora_db.dart';
import 'package:naji/models/enum_status.dart';

import '../models/fatora.dart';
import 'base_dao.dart';

class FatoraDAO extends BaseDAO<Fatora> {
  final FatoraDB fatoraDB = FatoraDB();
  @override
  Future<int> insert(Fatora item) {
    fatoraDB.insert(item);
    throw UnimplementedError();
  }

  @override
  Future<int> update(Fatora item) {
    fatoraDB.update(item);
    throw UnimplementedError();
  }

  @override
  Future<int> softDelete(String unified) {
    return fatoraDB.delete(unified);
  }

  @override
  Future<Fatora?> getByUnified(String unified) {
    return fatoraDB.get(unified);
  }

  @override
  Future<List<Fatora>> getAll() {
    return fatoraDB.getAll();
  }

  Future<List<Fatora>> getByUser(String userUnified) {
    final allFatoras = fatoraDB.getAll();
    final filteres = allFatoras.then(
      (fatoras) =>
          fatoras.where((fatora) => fatora.userUnified == userUnified).toList(),
    );
    return filteres;
  }

  Future<List<Fatora>> getBetweenDates(int startDate, int endDate) {
    final allFatoras = fatoraDB.getAll();
    final filteres = allFatoras.then(
      (fatoras) => fatoras
          .where(
            (fatora) => (fatora.date >= startDate && fatora.date <= endDate),
          )
          .toList(),
    );
    return filteres;
  }

  Future<List<Fatora>> getSellInvoices() {
    final allFatoras = fatoraDB.getAll();
    final filteres = allFatoras.then(
      (fatoras) =>
          fatoras.where((fatora) => fatora.type == InvoiceType.sale).toList(),
    );
    return filteres;
  }

  Future<List<Fatora>> getBuyInvoices() {
    final allFatoras = fatoraDB.getAll();
    final filteres = allFatoras.then(
      (fatoras) => fatoras
          .where((fatora) => fatora.type == InvoiceType.purchase)
          .toList(),
    );
    return filteres;
  }

  Future<double> calculateTotalSell() {
    final allFatoras = fatoraDB.getAll();
    final filteres = allFatoras.then(
      (fatoras) =>
          fatoras.where((fatora) => fatora.type == InvoiceType.sale).toList(),
    );
    final total = filteres.then(
      (fatoras) => fatoras.fold(0.0, (sum, fatora) => sum + fatora.total),
    );
    return total;
  }

  Future<double> calculateTotalBuy() {
    final allFatoras = fatoraDB.getAll();
    final filteres = allFatoras.then(
      (fatoras) => fatoras
          .where((fatora) => fatora.type == InvoiceType.purchase)
          .toList(),
    );
    final total = filteres.then(
      (fatoras) => fatoras.fold(0.0, (sum, fatora) => sum + fatora.total),
    );
    return total;
  }

  @override
  Future<List<Fatora>> getNotScheduled() {
    final allFatoras = fatoraDB.getAll();
    final filteres = allFatoras.then(
      (fatoras) => fatoras
          .where((fatora) => fatora.status == Status.notScheduled)
          .toList(),
    );
    return filteres;
  }
}
