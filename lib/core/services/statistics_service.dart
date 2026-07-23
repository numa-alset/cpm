import 'package:naji/core/services/transaction_service.dart';

import '../models/fatora.dart';
import '../repositories/fatora_product_repository.dart';
import '../repositories/fatora_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/user_repository.dart';

class StatisticsService {
  final FatoraRepository _fatoraRepository;
  final PaymentRepository _paymentRepository;
  final UserRepository _userRepository;
  final FatoraProductRepository _fatoraProductRepository;
  final TransactionService _transactionService;

  StatisticsService(
    this._fatoraRepository,
    this._paymentRepository,
    this._userRepository,
    this._fatoraProductRepository,
    this._transactionService,
  );

  Future<double> calculateUserBalance(String userUnified) async {
    final user = await _transactionService.runTransaction((txn) async {
      return await _userRepository.get(userUnified, txn);
    });
    return user?.total ?? 0.0;
  }

  Future<double> calculateDailySales() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;
    final invoices = await _transactionService.runTransaction((txn) async {
      return await _fatoraRepository.getBetweenDates(start, end, txn);
    });
    final total = invoices
        .where((i) => i.type == InvoiceType.sale)
        .fold(0.0, (sum, i) => sum + i.total);
    return total;
  }

  Future<double> calculateMonthlySales() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final end = nextMonth
        .subtract(Duration(milliseconds: 1))
        .millisecondsSinceEpoch;
    final invoices = await _transactionService.runTransaction((txn) async {
      return await _fatoraRepository.getBetweenDates(start, end, txn);
    });
    final total = invoices
        .where((i) => i.type == InvoiceType.sale)
        .fold(0.0, (sum, i) => sum + i.total);
    return total;
  }

  Future<double> calculateMonthlyPurchases() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final end = nextMonth
        .subtract(Duration(milliseconds: 1))
        .millisecondsSinceEpoch;
    final invoices = await _transactionService.runTransaction((txn) async {
      return await _fatoraRepository.getBetweenDates(start, end, txn);
    });
    final total = invoices
        .where((i) => i.type == InvoiceType.purchase)
        .fold(0.0, (sum, i) => sum + i.total);
    return total;
  }

  Future<double> calculateOutstandingDebt() async {
    final users = await _transactionService.runTransaction((txn) async {
      return await _userRepository.getAll(txn);
    });
    final total = users.fold(
      0.0,
      (sum, u) => sum + (u.total > 0 ? u.total : 0.0),
    );
    return total;
  }

  /// Cash flow for current month = total payments received - total purchases
  Future<double> calculateCashFlow() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final end = nextMonth
        .subtract(Duration(milliseconds: 1))
        .millisecondsSinceEpoch;

    final payments = await _transactionService.runTransaction((txn) async {
      return await _paymentRepository.getBetweenDates(start, end, txn);
    });
    final paymentsTotal = payments.fold(0.0, (s, p) => s + p.amount);

    final purchases = await _transactionService.runTransaction((txn) async {
      return await _fatoraRepository.getBetweenDates(start, end, txn);
    });
    final purchasesTotal = purchases
        .where((i) => i.type == InvoiceType.purchase)
        .fold(0.0, (s, i) => s + i.total);

    return paymentsTotal - purchasesTotal;
  }

  Future<List<String>> topCustomers({int limit = 5}) async {
    final users = await _transactionService.runTransaction((txn) async {
      return await _userRepository.getAll(txn);
    });
    users.sort((a, b) => b.total.compareTo(a.total));
    return users.take(limit).map((u) => u.name).toList();
  }

  Future<List<String>> topProducts({int limit = 5}) async {
    final items = await _transactionService.runTransaction((txn) async {
      return await _fatoraProductRepository.getAll(txn);
    });
    final Map<String, double> totals = {};
    for (var item in items) {
      final key = item.productName;
      totals[key] = (totals[key] ?? 0.0) + item.total;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  Future<Map<String, dynamic>> dashboardSummary() async {
    final futures = await Future.wait([
      calculateDailySales(),
      calculateMonthlySales(),
      calculateMonthlyPurchases(),
      calculateOutstandingDebt(),
      calculateCashFlow(),
    ]);

    return {
      'dailySales': futures[0],
      'monthlySales': futures[1],
      'monthlyPurchases': futures[2],
      'outstandingDebt': futures[3],
      'cashFlow': futures[4],
    };
  }
}
