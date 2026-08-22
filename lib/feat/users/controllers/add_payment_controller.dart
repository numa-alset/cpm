import 'package:flutter/material.dart';
import 'package:naji/core/models/currency.dart';
import 'package:naji/core/services/device_service.dart';
import 'package:naji/core/services/payment_service.dart';

import '../../../../core/models/enum_status.dart';
import '../../../../core/models/payment.dart';
import '../../../../core/services/id_service.dart';

class AddPaymentController extends ChangeNotifier {
  final String userUnified;
  final PaymentService _paymentService;

  AddPaymentController({
    required this.userUnified,
    required PaymentService paymentService,
  }) : _paymentService = paymentService;

  DateTime selectedDate = DateTime.now();
  Currency selectedCurrency = Currency.sy;
  bool isLoading = false;
  String? error;

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setCurrency(Currency currency) {
    selectedCurrency = currency;
    notifyListeners();
  }

  Future<bool> savePayment(double amount) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final payment = Payment(
        unified: IdService.generate(),
        userUnified: userUnified,
        amount: amount,
        date: selectedDate.millisecondsSinceEpoch,
        currency: selectedCurrency,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        deviceId: DeviceService.deviceIdKey,
        status: Status.notScheduled,
      );

      await _paymentService.createPayment(payment);

      isLoading = false;
      notifyListeners();
      return true; // Success
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false; // Failed
    }
  }
}
