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
      // Fetch all statistics in parallel for faster loading
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

  // Helper getters for clean UI access
  double get dailySales => summary['dailySales'] ?? 0.0;
  double get monthlySales => summary['monthlySales'] ?? 0.0;
  double get monthlyPurchases => summary['monthlyPurchases'] ?? 0.0;
  double get outstandingDebt => summary['outstandingDebt'] ?? 0.0;
  double get cashFlow => summary['cashFlow'] ?? 0.0;
}
