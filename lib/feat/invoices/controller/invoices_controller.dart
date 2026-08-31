import 'package:flutter/material.dart';
import 'package:naji/core/models/fatora.dart';
import 'package:naji/core/models/fatora_product.dart';
import 'package:naji/core/services/invoice_service.dart';
import 'package:naji/core/services/user_service.dart';

enum GroupingFilter { day, month, year }

class InvoiceGroup {
  final String key;
  final List<Fatora> invoices;

  InvoiceGroup({required this.key, required this.invoices});

  int get count => invoices.length;

  double get totalSy {
    return invoices.fold(0, (sum, invoice) => sum + invoice.totalSy);
  }

  double get totalDollar {
    return invoices.fold(0, (sum, invoice) => sum + invoice.totalDollar);
  }
}

class InvoicesController extends ChangeNotifier {
  final InvoiceService _invoiceService;
  final UserService _userService;

  InvoicesController(this._invoiceService, this._userService);

  bool isLoading = false;
  String? error;

  List<Fatora> invoices = [];
  List<InvoiceGroup> groups = [];

  GroupingFilter currentFilter = GroupingFilter.month;

  /// Date groups collapsed state.
  final Set<String> collapsedGroups = {};

  /// Invoice expanded state.
  final Map<String, bool> _expandedInvoices = {};

  /// Products loaded for each expanded invoice.
  final Map<String, List<FatoraProduct>> invoiceProducts = {};

  /// Loading state while fetching invoice products.
  final Set<String> loadingProducts = {};

  // map users

  // ---------------------------------------------------------------------------
  // LOAD
  // ---------------------------------------------------------------------------

  /// Map holding user names by their unified ID
  Map<String, String> userNamesMap = {};

  Future<void> loadInvoices() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Fetch both concurrently for better performance
      final results = await Future.wait([
        _invoiceService.getInvoices(),
        _userService.getAllUsers(), // Replace with your actual method
      ]);

      invoices = results[0] as List<Fatora>;
      final users = results[1] as List<dynamic>; // Replace with your User model

      // Build the map instantly: unified -> name
      userNamesMap = {for (var user in users) user.unified: user.name};

      invoices.sort((a, b) => b.date.compareTo(a.date));

      // ... existing cleanup logic ...

      _applyGrouping();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to safely get a name
  String getUserName(String? userUnified) {
    if (userUnified == null) return 'عميل غير معروف'; // Unknown customer
    return userNamesMap[userUnified] ?? 'عميل غير معروف';
  }

  // ---------------------------------------------------------------------------
  // FILTER & GROUPING
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

  void _applyGrouping() {
    final Map<String, List<Fatora>> grouped = {};

    for (final invoice in invoices) {
      final key = _generateHeaderForDate(invoice.date, currentFilter);
      grouped.putIfAbsent(key, () => []).add(invoice);
    }

    groups = grouped.entries
        .map((entry) => InvoiceGroup(key: entry.key, invoices: entry.value))
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
  // COLLAPSE GROUPS
  // ---------------------------------------------------------------------------

  bool isGroupCollapsed(String key) {
    return collapsedGroups.contains(key);
  }

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

  // ---------------------------------------------------------------------------
  // INVOICE EXPANSION & PRODUCTS
  // ---------------------------------------------------------------------------

  bool isInvoiceExpanded(String unified) {
    return _expandedInvoices[unified] ?? false;
  }

  List<FatoraProduct> productsFor(String unified) {
    return invoiceProducts[unified] ?? [];
  }

  bool isLoadingProducts(String unified) {
    return loadingProducts.contains(unified);
  }

  Future<void> toggleInvoice(String unified) async {
    final expanded = isInvoiceExpanded(unified);
    _expandedInvoices[unified] = !expanded;
    notifyListeners();

    if (!expanded && !invoiceProducts.containsKey(unified)) {
      await _loadProducts(unified);
    }
  }

  Future<void> _loadProducts(String unified) async {
    loadingProducts.add(unified);
    notifyListeners();

    try {
      final products = await _invoiceService.getInvoiceProducts(unified);
      invoiceProducts[unified] = products;
    } catch (e) {
      error = e.toString();
    } finally {
      loadingProducts.remove(unified);
      notifyListeners();
    }
  }

  Future<void> refreshInvoiceProducts(String unified) async {
    await _loadProducts(unified);
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  Future<void> deleteInvoice(Fatora invoice) async {
    await _invoiceService.deleteInvoice(invoice.unified);

    invoices.removeWhere((item) => item.unified == invoice.unified);
    _expandedInvoices.remove(invoice.unified);
    invoiceProducts.remove(invoice.unified);

    _applyGrouping();

    notifyListeners();
  }
}
