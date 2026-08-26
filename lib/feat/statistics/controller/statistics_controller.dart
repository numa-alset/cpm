import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:naji/core/services/statistics_service.dart';

enum StatisticPeriod { all, today, thisMonth, lastMonth, thisYear, custom }

class StatisticController extends ChangeNotifier {
  StatisticController({StatisticService? statisticService})
    : _statisticService = statisticService ?? GetIt.I<StatisticService>();

  final StatisticService _statisticService;

  StatisticData? _data;

  bool _isLoading = false;
  String? _error;

  StatisticPeriod _period = StatisticPeriod.thisMonth;

  DateTime? _customStartDate;
  DateTime? _customEndDate;

  StatisticData? get data => _data;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get hasData => _data != null;

  StatisticPeriod get period => _period;

  DateTime? get customStartDate => _customStartDate;

  DateTime? get customEndDate => _customEndDate;

  Future<void> loadData() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final range = _getRange();

      _data = await _statisticService.getStatistics(
        startDate: range.$1,
        endDate: range.$2,
      );
    } catch (e, stackTrace) {
      debugPrint('StatisticController.loadData error: $e');
      debugPrintStack(stackTrace: stackTrace);

      _error = 'حدث خطأ أثناء تحميل الإحصائيات.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPeriod(StatisticPeriod period) async {
    _period = period;

    if (period != StatisticPeriod.custom) {
      _customStartDate = null;
      _customEndDate = null;
    }

    await loadData();
  }

  Future<void> setCustomRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _customStartDate = startDate;
    _customEndDate = endDate;

    _period = StatisticPeriod.custom;

    await loadData();
  }

  Future<void> selectCustomRange(BuildContext context) async {
    final initialStart =
        _customStartDate ?? DateTime.now().subtract(const Duration(days: 30));

    final initialEnd = _customEndDate ?? DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      locale: const Locale('ar'),
    );

    if (picked == null) {
      return;
    }

    await setCustomRange(startDate: picked.start, endDate: picked.end);
  }

  void clearError() {
    if (_error == null) return;

    _error = null;
    notifyListeners();
  }

  (DateTime?, DateTime?) _getRange() {
    final now = DateTime.now();

    switch (_period) {
      case StatisticPeriod.all:
        return (null, null);

      case StatisticPeriod.today:
        return (
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day),
        );

      case StatisticPeriod.thisMonth:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0),
        );

      case StatisticPeriod.lastMonth:
        return (
          DateTime(now.year, now.month - 1, 1),
          DateTime(now.year, now.month, 0),
        );

      case StatisticPeriod.thisYear:
        return (DateTime(now.year, 1, 1), DateTime(now.year, 12, 31));

      case StatisticPeriod.custom:
        return (_customStartDate, _customEndDate);
    }
  }

  String get periodLabel {
    switch (_period) {
      case StatisticPeriod.all:
        return 'الكل';

      case StatisticPeriod.today:
        return 'اليوم';

      case StatisticPeriod.thisMonth:
        return 'هذا الشهر';

      case StatisticPeriod.lastMonth:
        return 'الشهر الماضي';

      case StatisticPeriod.thisYear:
        return 'هذه السنة';

      case StatisticPeriod.custom:
        return 'مخصص';
    }
  }
}
