import 'package:flutter/material.dart';
import 'package:naji/core/services/invoice_service.dart';
import 'package:naji/core/services/payment_service.dart';

import '../../../../core/models/fatora.dart';
import '../../../../core/models/fatora_product.dart';
import '../../../../core/models/payment.dart';
import '../../../../core/models/user.dart';
import '../../../../core/services/user_service.dart';

class UserDetailsController extends ChangeNotifier {
  final String userUnified;
  final UserService _userService;
  final InvoiceService _invoiceService;
  final PaymentService _paymentService;

  UserDetailsController({
    required this.userUnified,
    required UserService userService,
    required InvoiceService invoiceService,
    required PaymentService paymentService,
  }) : _userService = userService,
       _invoiceService = invoiceService,
       _paymentService = paymentService;

  User? user;
  // Using Dart Records to tie the invoice and its products together
  List<(Fatora, List<FatoraProduct>)> invoices = [];
  List<Payment> payments = [];

  bool loading = true;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      // 1. Fetch user, raw invoices, and payments in parallel
      final results = await Future.wait([
        _userService.getUser(userUnified),
        _invoiceService.getInvoicesByUser(userUnified),
        _paymentService.getPaymentsByUser(userUnified),
      ]);

      user = results[0] as User?;
      final rawInvoices = results[1] as List<Fatora>;
      payments = results[2] as List<Payment>;

      // 2. Fetch products for each invoice in parallel
      final invoiceProductsFutures = rawInvoices.map((fatora) async {
        final products = await _invoiceService.getInvoiceProducts(
          fatora.unified,
        );
        return (fatora, products);
      });

      invoices = await Future.wait(invoiceProductsFutures);

      // 3. Sort both lists from newest to oldest
      invoices.sort((a, b) => b.$1.date.compareTo(a.$1.date));
      payments.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
