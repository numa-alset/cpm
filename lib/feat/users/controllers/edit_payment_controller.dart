import 'package:flutter/material.dart';
import 'package:naji/core/models/currency.dart';
import 'package:naji/core/models/payment.dart';
import 'package:naji/core/services/payment_service.dart';

class EditPaymentController extends ChangeNotifier {
  final Payment payment;
  final PaymentService _paymentService;

  late DateTime selectedDate;
  late Currency selectedCurrency;
  late double amount;
  bool isLoading = false;
  String? error;

  EditPaymentController({
    required this.payment,
    required PaymentService paymentService,
  })  : _paymentService = paymentService,
        selectedDate = DateTime.fromMillisecondsSinceEpoch(payment.date),
        selectedCurrency = payment.currency,
        amount = payment.amount;

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setCurrency(Currency currency) {
    selectedCurrency = currency;
    notifyListeners();
  }

  void setAmount(double newAmount) {
    amount = newAmount;
    notifyListeners();
  }

  Future<bool> savePayment() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final updatedPayment = payment.copyWith(
        amount: amount,
        date: selectedDate.millisecondsSinceEpoch,
        currency: selectedCurrency,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _paymentService.updatePayment(updatedPayment);

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
