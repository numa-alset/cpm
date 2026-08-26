import 'package:flutter/material.dart';
import 'package:naji/core/models/currency.dart';
import 'package:naji/core/models/enum_status.dart';
import 'package:naji/core/models/payment.dart';
import 'package:naji/core/models/user.dart';
import 'package:naji/core/services/device_service.dart';
import 'package:naji/core/services/id_service.dart';
import 'package:naji/core/services/payment_service.dart';
import 'package:naji/core/services/user_service.dart';

enum GroupingFilter { day, month, year }

class PaymentGroup {
  final String key;
  final List<Payment> payments;

  PaymentGroup({required this.key, required this.payments});

  bool get isEmpty => payments.isEmpty;

  int get count => payments.length;

  double get totalSy => payments
      .where((payment) => payment.currency == Currency.sy)
      .fold(0, (sum, payment) => sum + payment.amount);

  double get totalDollar => payments
      .where((payment) => payment.currency == Currency.dollar)
      .fold(0, (sum, payment) => sum + payment.amount);
}

class PaymentsController extends ChangeNotifier {
  final PaymentService _paymentService;
  final UserService _userService;

  PaymentsController({
    required PaymentService paymentService,
    required UserService userService,
  }) : _paymentService = paymentService,
       _userService = userService;

  List<User> users = [];

  List<Payment> _allPayments = [];

  Map<String, String> _userNamesMap = {};

  List<PaymentGroup> groups = [];

  final Set<String> collapsedGroups = {};

  GroupingFilter currentFilter = GroupingFilter.month;

  bool isLoading = true;
  String? error;

  // ---------------------------------------------------------------------------
  // LOAD
  // ---------------------------------------------------------------------------

  Future<void> loadData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _paymentService.getPayments(),
        _userService.getAllUsers(),
      ]);

      _allPayments = results[0] as List<Payment>;
      users = results[1] as List<User>;

      _userNamesMap = {for (final user in users) user.unified: user.name};

      _allPayments.sort((a, b) => b.date.compareTo(a.date));

      _applyGrouping();
    } catch (e) {
      error = "حدث خطأ أثناء تحميل البيانات: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // ADD
  // ---------------------------------------------------------------------------

  Future<bool> addPayment({
    required String userUnified,
    required double amount,
    required Currency currency,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      final payment = Payment(
        unified: IdService.generate(),
        userUnified: userUnified,
        amount: amount,
        date: now,
        createdAt: now,
        updatedAt: now,
        status: Status.notScheduled,
        currency: currency,
        deviceId: DeviceService.deviceIdKey,
      );

      await _paymentService.createPayment(payment);

      await loadData();

      return true;
    } catch (e) {
      error = "فشل في إضافة الدفعة: $e";
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // FILTER
  // ---------------------------------------------------------------------------

  void changeFilter(GroupingFilter filter) {
    if (currentFilter == filter) {
      return;
    }

    currentFilter = filter;

    collapsedGroups.clear();

    _applyGrouping();

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // COLLAPSE
  // ---------------------------------------------------------------------------

  void toggleGroup(String key) {
    if (collapsedGroups.contains(key)) {
      collapsedGroups.remove(key);
    } else {
      collapsedGroups.add(key);
    }

    notifyListeners();
  }

  void expandAll() {
    collapsedGroups.clear();
    notifyListeners();
  }

  void collapseAll() {
    collapsedGroups
      ..clear()
      ..addAll(groups.map((group) => group.key));

    notifyListeners();
  }

  bool isGroupCollapsed(String key) {
    return collapsedGroups.contains(key);
  }

  // ---------------------------------------------------------------------------
  // GROUPING
  // ---------------------------------------------------------------------------

  void _applyGrouping() {
    final Map<String, List<Payment>> grouped = {};

    for (final payment in _allPayments) {
      final key = _generateHeaderForDate(payment.date, currentFilter);

      grouped.putIfAbsent(key, () => []);

      grouped[key]!.add(payment);
    }

    groups = grouped.entries
        .map((entry) => PaymentGroup(key: entry.key, payments: entry.value))
        .toList();
  }

  String _generateHeaderForDate(int milliseconds, GroupingFilter filter) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);

    switch (filter) {
      case GroupingFilter.day:
        return "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";

      case GroupingFilter.month:
        return "${date.year} / ${date.month.toString().padLeft(2, '0')}";

      case GroupingFilter.year:
        return "${date.year}";
    }
  }

  // ---------------------------------------------------------------------------
  // USERS
  // ---------------------------------------------------------------------------

  String getUserName(String unified) {
    return _userNamesMap[unified] ?? "عميل غير معروف";
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  Future<bool> deletePayment(String unified) async {
    try {
      await _paymentService.deletePayment(unified);

      _allPayments.removeWhere((payment) => payment.unified == unified);

      _applyGrouping();

      notifyListeners();

      return true;
    } catch (e) {
      error = "فشل في حذف الدفعة: $e";
      notifyListeners();

      return false;
    }
  }
}
