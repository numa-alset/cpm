import 'package:flutter/material.dart';
import 'package:naji/core/models/enum_status.dart';
import 'package:naji/core/models/payment.dart';
import 'package:naji/core/models/user.dart';
import 'package:naji/core/services/id_service.dart';
import 'package:naji/core/services/payment_service.dart';
import 'package:naji/core/services/user_service.dart';

enum GroupingFilter { day, month, year }

class PaymentsController extends ChangeNotifier {
  final PaymentService _paymentService;
  final UserService _userService;
  List<User> users = [];
  PaymentsController({
    required PaymentService paymentService,
    required UserService userService,
  }) : _paymentService = paymentService,
       _userService = userService;

  List<Payment> _allPayments = [];
  Map<String, String> _userNamesMap = {};

  List<dynamic> displayItems = [];

  // Track which headers are currently collapsed
  Set<String> collapsedGroups = {};

  GroupingFilter currentFilter = GroupingFilter.month;

  bool isLoading = true;
  String? error;

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

      // 2. STORE THE USERS HERE
      users = results[1] as List<User>;

      _userNamesMap = {for (var user in users) user.unified: user.name};

      _allPayments.sort((a, b) => b.date.compareTo(a.date));

      _applyGrouping();
    } catch (e) {
      error = "حدث خطأ أثناء تحميل البيانات: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPayment({
    required String userUnified,
    required double amount,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      final payment = Payment(
        unified: IdService.generate(), // Make sure IdService is imported
        userUnified: userUnified,
        amount: amount,
        date: now, // Defaults to now, but you could add a date picker if needed
        createdAt: now,
        updatedAt: now,
        status: Status.notScheduled,
        deviceId:
            "default_device", // Replace with DeviceService.deviceIdKey if you use it
      );

      await _paymentService.createPayment(payment);

      // Reload data to recalculate groups and sort properly
      await loadData();
      return true;
    } catch (e) {
      error = "فشل في إضافة الدفعة: $e";
      notifyListeners();
      return false;
    }
  }

  void changeFilter(GroupingFilter filter) {
    if (currentFilter == filter) return;
    currentFilter = filter;
    collapsedGroups.clear(); // Reset collapsed state when changing filters
    _applyGrouping();
    notifyListeners();
  }

  void toggleGroup(String header) {
    if (collapsedGroups.contains(header)) {
      collapsedGroups.remove(header); // Expand
    } else {
      collapsedGroups.add(header); // Collapse
    }
    _applyGrouping();
    notifyListeners();
  }

  void _applyGrouping() {
    displayItems.clear();
    if (_allPayments.isEmpty) return;

    String currentHeader = "";
    bool isCurrentGroupCollapsed = false;

    for (var payment in _allPayments) {
      final header = _generateHeaderForDate(payment.date, currentFilter);

      // If the header changes, add a Header item to the list
      if (header != currentHeader) {
        displayItems.add(header);
        currentHeader = header;
        // Check if this new group is collapsed
        isCurrentGroupCollapsed = collapsedGroups.contains(header);
      }

      // Only add the payment item if its group is NOT collapsed
      if (!isCurrentGroupCollapsed) {
        displayItems.add(payment);
      }
    }
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

  String getUserName(String unified) {
    return _userNamesMap[unified] ?? "عميل غير معروف";
  }

  Future<bool> deletePayment(String unified) async {
    try {
      await _paymentService.deletePayment(unified);

      _allPayments.removeWhere((p) => p.unified == unified);
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
