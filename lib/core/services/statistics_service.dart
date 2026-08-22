import 'package:naji/core/services/transaction_service.dart';

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

  /// حساب المبيعات اليومية مفصولة حسب العملة
  Future<Map<String, double>> calculateDailySales() async {
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

    double syTotal = 0.0;
    double dollarTotal = 0.0;

    for (var i in invoices) {
      syTotal += i.totalSy;
      dollarTotal += i.totalDollar;
    }

    return {'sy': syTotal, 'dollar': dollarTotal};
  }

  /// حساب مبيعات الشهر مفصولة حسب العملة
  Future<Map<String, double>> calculateMonthlySales() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final end = nextMonth
        .subtract(const Duration(milliseconds: 1))
        .millisecondsSinceEpoch;

    final invoices = await _transactionService.runTransaction((txn) async {
      return await _fatoraRepository.getBetweenDates(start, end, txn);
    });

    double syTotal = 0.0;
    double dollarTotal = 0.0;

    for (var i in invoices) {
      syTotal += i.totalSy;
      dollarTotal += i.totalDollar;
    }

    return {'sy': syTotal, 'dollar': dollarTotal};
  }

  /// حساب مشتريات الشهر مفصولة حسب العملة
  Future<Map<String, double>> calculateMonthlyPurchases() async {
    // يمكن تكرار منطق المبيعات أو ربطه بنوع الفاتورة إذا كان هناك تمييز بين شراء وبيع
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final end = nextMonth
        .subtract(const Duration(milliseconds: 1))
        .millisecondsSinceEpoch;

    final invoices = await _transactionService.runTransaction((txn) async {
      return await _fatoraRepository.getBetweenDates(start, end, txn);
    });

    double syTotal = 0.0;
    double dollarTotal = 0.0;

    for (var i in invoices) {
      syTotal += i.totalSy;
      dollarTotal += i.totalDollar;
    }

    return {'sy': syTotal, 'dollar': dollarTotal};
  }

  /// حساب الديون المستحقة لكل عملة بناءً على الحقول الجديدة totalSy و totalDollar
  Future<Map<String, double>> calculateOutstandingDebt() async {
    final users = await _transactionService.runTransaction((txn) async {
      return await _userRepository.getAll(txn);
    });

    double syDebt = 0.0;
    double dollarDebt = 0.0;

    for (var u in users) {
      if (u.totalSy > 0) syDebt += u.totalSy;
      if (u.totalDollar > 0) dollarDebt += u.totalDollar;
    }

    return {'sy': syDebt, 'dollar': dollarDebt};
  }

  /// التدفق النقدي للشهر الحالي مفصولاً حسب العملة
  Future<Map<String, double>> calculateCashFlow() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final end = nextMonth
        .subtract(const Duration(milliseconds: 1))
        .millisecondsSinceEpoch;

    final payments = await _transactionService.runTransaction((txn) async {
      return await _paymentRepository.getBetweenDates(start, end, txn);
    });

    double syPayments = 0.0;
    double dollarPayments = 0.0;

    for (var p in payments) {
      final isSy =
          p.currency.name.toLowerCase().contains('sy') == true ||
          p.currency.symbol.contains('ل.س') == true;
      if (isSy) {
        syPayments += p.amount;
      } else {
        dollarPayments += p.amount;
      }
    }

    final purchases = await calculateMonthlyPurchases();

    return {
      'sy': syPayments - purchases['sy']!,
      'dollar': dollarPayments - purchases['dollar']!,
    };
  }

  Future<List<String>> topCustomers({int limit = 5}) async {
    final users = await _transactionService.runTransaction((txn) async {
      return await _userRepository.getAll(txn);
    });
    // الترتيب بناءً على مجموع الأرصدة أو رصيد الليرة كمثال رئيسي
    users.sort((a, b) => b.totalSy.compareTo(a.totalSy));
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
    final results = await Future.wait([
      calculateDailySales(),
      calculateMonthlySales(),
      calculateMonthlyPurchases(),
      calculateOutstandingDebt(),
      calculateCashFlow(),
    ]);

    return {
      'dailySales': results[0],
      'monthlySales': results[1],
      'monthlyPurchases': results[2],
      'outstandingDebt': results[3],
      'cashFlow': results[4],
    };
  }
}
