import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:naji/core/services/statistics_service.dart';

class StatisticsController extends ChangeNotifier {
  final StatisticsService _statisticsService = GetIt.I<StatisticsService>();

  bool isLoading = true;
  String? error;

  // Data Holders
  Map<String, dynamic> summary = {};
  List<String> topCustomersList = [];
  List<String> topProductsList = [];

  Future<void> loadData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _statisticsService.dashboardSummary(),
        _statisticsService.topCustomers(limit: 5),
        _statisticsService.topProducts(limit: 5),
      ]);

      summary = results[0] as Map<String, dynamic>;
      topCustomersList = results[1] as List<String>;
      topProductsList = results[2] as List<String>;
    } catch (e) {
      error = "حدث خطأ أثناء تحميل الإحصائيات: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Getters for Syrian Pounds (SYP)
  Map<String, double> get dailySales =>
      summary['dailySales'] ?? {'sy': 0.0, 'dollar': 0.0};
  Map<String, double> get monthlySales =>
      summary['monthlySales'] ?? {'sy': 0.0, 'dollar': 0.0};
  Map<String, double> get monthlyPurchases =>
      summary['monthlyPurchases'] ?? {'sy': 0.0, 'dollar': 0.0};
  Map<String, double> get outstandingDebt =>
      summary['outstandingDebt'] ?? {'sy': 0.0, 'dollar': 0.0};
  Map<String, double> get cashFlow =>
      summary['cashFlow'] ?? {'sy': 0.0, 'dollar': 0.0};
}
