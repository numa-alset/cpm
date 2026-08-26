import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:naji/core/models/currency.dart';
import 'package:naji/core/models/fatora.dart';
import 'package:naji/core/models/fatora_product.dart';
import 'package:naji/core/models/payment.dart';
import 'package:naji/core/models/user.dart';
import 'package:naji/core/services/backup_service.dart';
import 'package:naji/core/services/invoice_service.dart';
import 'package:naji/core/services/payment_service.dart';
import 'package:naji/core/services/transaction_service.dart';
import 'package:naji/core/services/user_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

enum SyncItemType { user, invoice, payment, fatoraProduct }

class SyncDetail {
  const SyncDetail({required this.label, required this.value});

  final String label;
  final String value;
}

class SyncItem {
  const SyncItem({
    required this.unified,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.originalObject,
    this.children = const [],
    this.details = const [],
  });

  final String unified;
  final String title;
  final String subtitle;
  final SyncItemType type;
  final dynamic originalObject;

  final List<SyncItem> children;
  final List<SyncDetail> details;

  bool get hasChildren => children.isNotEmpty;

  bool get hasDetails => details.isNotEmpty;

  bool get isExpandable {
    return hasChildren ||
        hasDetails ||
        type == SyncItemType.invoice ||
        type == SyncItemType.payment;
  }
}

class HomeController extends ChangeNotifier {
  HomeController({
    UserService? userService,
    InvoiceService? invoiceService,
    PaymentService? paymentService,
    BackupService? backupService,
    TransactionService? transactionService,
  }) : _userService = userService ?? GetIt.I<UserService>(),
       _invoiceService = invoiceService ?? GetIt.I<InvoiceService>(),
       _paymentService = paymentService ?? GetIt.I<PaymentService>(),
       _backupService = backupService ?? GetIt.I<BackupService>(),
       _transactionService =
           transactionService ?? GetIt.I<TransactionService>();

  final UserService _userService;
  final InvoiceService _invoiceService;
  final PaymentService _paymentService;
  final BackupService _backupService;
  final TransactionService _transactionService;

  List<SyncItem> _items = [];

  bool _isLoading = false;
  bool _isScheduling = false;
  String? _error;

  List<SyncItem> get unscheduledItems => List.unmodifiable(_items);

  bool get isLoading => _isLoading;

  bool get isScheduling => _isScheduling;

  String? get error => _error;

  bool get hasItems => _items.isNotEmpty;

  int get itemCount => _items.length;

  int get childCount {
    return _items.fold(0, (total, item) => total + item.children.length);
  }

  int get totalCount => itemCount + childCount;

  int get userCount {
    return _items.where((item) => item.type == SyncItemType.user).length;
  }

  int get invoiceCount {
    return _items.where((item) => item.type == SyncItemType.invoice).length;
  }

  int get paymentCount {
    return _items.where((item) => item.type == SyncItemType.payment).length;
  }

  int get productCount {
    return _items
        .where((item) => item.type == SyncItemType.fatoraProduct)
        .length;
  }

  Future<void> loadData() async {
    if (_isScheduling) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _userService.getNotScheduledUsers(),
        _invoiceService.getNotScheduledInvoices(),
        _paymentService.getNotScheduledPayments(),
        _invoiceService.getNotScheduledInvoicesProducts(),
      ]);

      final users = results[0] as List<User>;
      final invoices = results[1] as List<Fatora>;
      final payments = results[2] as List<Payment>;
      final products = results[3] as List<FatoraProduct>;

      _items = _buildItems(
        users: users,
        invoices: invoices,
        payments: payments,
        products: products,
      );
    } catch (e, stackTrace) {
      debugPrint('HomeController.loadData error: $e');
      debugPrintStack(stackTrace: stackTrace);

      _error = 'حدث خطأ أثناء تحميل البيانات.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<SyncItem> _buildItems({
    required List<User> users,
    required List<Fatora> invoices,
    required List<Payment> payments,
    required List<FatoraProduct> products,
  }) {
    final items = <SyncItem>[];

    final usersByUnified = <String, User>{
      for (final user in users) user.unified: user,
    };

    // ============================================================
    // USERS
    // ============================================================

    for (final user in users) {
      items.add(
        SyncItem(
          unified: user.unified,
          title: user.name,
          subtitle: user.location.isEmpty ? 'مستخدم' : user.location,
          type: SyncItemType.user,
          originalObject: user,
          details: _userDetails(user),
        ),
      );
    }

    // ============================================================
    // PAYMENTS
    // ============================================================

    for (final payment in payments) {
      final user = usersByUnified[payment.userUnified];

      items.add(
        SyncItem(
          unified: payment.unified,
          title: 'دفعة',
          subtitle: _paymentSubtitle(payment),
          type: SyncItemType.payment,
          originalObject: payment,
          details: _paymentDetails(payment, userName: user?.name),
        ),
      );
    }

    // ============================================================
    // GROUP PRODUCTS BY INVOICE
    // ============================================================

    final productsByInvoice = <String, List<FatoraProduct>>{};

    for (final product in products) {
      productsByInvoice
          .putIfAbsent(product.fatoraUnified, () => [])
          .add(product);
    }

    // ============================================================
    // INVOICES
    // ============================================================

    for (final invoice in invoices) {
      final invoiceProducts = productsByInvoice.remove(invoice.unified) ?? [];

      final user = usersByUnified[invoice.userUnified];

      items.add(
        SyncItem(
          unified: invoice.unified,
          title: 'فاتورة',
          subtitle: _invoiceSubtitle(invoice),
          type: SyncItemType.invoice,
          originalObject: invoice,
          children: invoiceProducts
              .map(_productToSyncItem)
              .toList(growable: false),
          details: _invoiceDetails(invoice, userName: user?.name),
        ),
      );
    }

    // ============================================================
    // ORPHAN PRODUCTS
    //
    // These are products whose invoice is not part of the
    // unscheduled invoice list.
    //
    // We keep them visible instead of losing them.
    // ============================================================

    for (final entry in productsByInvoice.entries) {
      for (final product in entry.value) {
        items.add(_productToSyncItem(product));
      }
    }

    return items;
  }

  // ============================================================
  // USER
  // ============================================================

  List<SyncDetail> _userDetails(User user) {
    final details = <SyncDetail>[];

    if (user.location.trim().isNotEmpty) {
      details.add(SyncDetail(label: 'الموقع', value: user.location));
    }

    if (user.totalSy != 0) {
      details.add(
        SyncDetail(
          label: 'الرصيد السوري',
          value: _formatMoney(user.totalSy, Currency.sy),
        ),
      );
    }

    if (user.totalDollar != 0) {
      details.add(
        SyncDetail(
          label: 'الرصيد بالدولار',
          value: _formatMoney(user.totalDollar, Currency.dollar),
        ),
      );
    }

    return details;
  }

  // ============================================================
  // PAYMENT
  // ============================================================

  String _paymentSubtitle(Payment payment) {
    return _formatMoney(payment.amount, payment.currency);
  }

  List<SyncDetail> _paymentDetails(Payment payment, {String? userName}) {
    final details = <SyncDetail>[];

    if (userName != null && userName.trim().isNotEmpty) {
      details.add(SyncDetail(label: 'العميل / المورد', value: userName));
    }

    details.add(
      SyncDetail(
        label: 'المبلغ',
        value: _formatMoney(payment.amount, payment.currency),
      ),
    );

    details.add(SyncDetail(label: 'التاريخ', value: _formatDate(payment.date)));

    return details;
  }

  // ============================================================
  // INVOICE
  // ============================================================

  String _invoiceSubtitle(Fatora invoice) {
    final parts = <String>[];

    if (invoice.totalSy != 0) {
      parts.add(_formatMoney(invoice.totalSy, Currency.sy));
    }

    if (invoice.totalDollar != 0) {
      parts.add(_formatMoney(invoice.totalDollar, Currency.dollar));
    }

    return parts.isEmpty ? 'بدون مبلغ' : parts.join(' • ');
  }

  List<SyncDetail> _invoiceDetails(Fatora invoice, {String? userName}) {
    final details = <SyncDetail>[];

    if (userName != null && userName.trim().isNotEmpty) {
      details.add(SyncDetail(label: 'العميل / المورد', value: userName));
    }

    details.add(SyncDetail(label: 'التاريخ', value: _formatDate(invoice.date)));

    if (invoice.writer.trim().isNotEmpty) {
      details.add(SyncDetail(label: 'الكاتب', value: invoice.writer));
    }

    if (invoice.totalSy != 0) {
      details.add(
        SyncDetail(
          label: 'المجموع السوري',
          value: _formatMoney(invoice.totalSy, Currency.sy),
        ),
      );
    }

    if (invoice.totalDollar != 0) {
      details.add(
        SyncDetail(
          label: 'المجموع بالدولار',
          value: _formatMoney(invoice.totalDollar, Currency.dollar),
        ),
      );
    }

    if (invoice.note != null && invoice.note!.trim().isNotEmpty) {
      details.add(SyncDetail(label: 'ملاحظات', value: invoice.note!));
    }

    return details;
  }

  // ============================================================
  // PRODUCT
  // ============================================================

  SyncItem _productToSyncItem(FatoraProduct product) {
    return SyncItem(
      unified: product.unified,
      title: product.productName,
      subtitle: _formatMoney(product.total, product.currency),
      type: SyncItemType.fatoraProduct,
      originalObject: product,
      details: [
        SyncDetail(label: 'الكمية', value: _formatNumber(product.quantity)),
        SyncDetail(
          label: 'سعر الوحدة',
          value: _formatMoney(product.price, product.currency),
        ),
        SyncDetail(
          label: 'الإجمالي',
          value: _formatMoney(product.total, product.currency),
        ),
      ],
    );
  }

  // ============================================================
  // FORMATTING
  // ============================================================

  String _formatMoney(double amount, Currency currency) {
    final value = _formatNumber(amount);

    switch (currency) {
      case Currency.sy:
        return '$value ل.س';

      case Currency.dollar:
        return '$value \$';
    }
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  String _formatDate(int timestamp) {
    // Supports both milliseconds and seconds timestamps.
    final milliseconds = timestamp < 100000000000
        ? timestamp * 1000
        : timestamp;

    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // SCHEDULE ALL
  // ============================================================

  Future<bool> scheduleAll() async {
    if (_items.isEmpty || _isScheduling) {
      return false;
    }

    _isScheduling = true;
    _error = null;
    notifyListeners();

    try {
      final file = await _backupService.exportUnsynced();

      final result = await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'بيانات الجدولة'),
      );

      if (!_shareWasAccepted(result)) {
        return false;
      }

      await _transactionService.runTransaction((txn) async {
        for (final item in _items) {
          await _updateItemStatusInTxn(item, txn);

          for (final child in item.children) {
            await _updateItemStatusInTxn(child, txn);
          }
        }
      });

      await loadData();

      return true;
    } catch (e, stackTrace) {
      debugPrint('scheduleAll error: $e');
      debugPrintStack(stackTrace: stackTrace);

      _error = 'فشل في جدولة البيانات.';
      return false;
    } finally {
      _isScheduling = false;
      notifyListeners();
    }
  }

  // ============================================================
  // SCHEDULE ONE
  // ============================================================

  Future<bool> scheduleSingle(SyncItem item) async {
    if (_isScheduling) {
      return false;
    }

    _isScheduling = true;
    _error = null;
    notifyListeners();

    try {
      final files = <XFile>[];

      final file = await _backupService.exportSingleRecord(
        type: _exportType(item.type),
        unified: item.unified,
      );

      files.add(XFile(file.path));

      for (final child in item.children) {
        final childFile = await _backupService.exportSingleRecord(
          type: _exportType(child.type),
          unified: child.unified,
        );

        files.add(XFile(childFile.path));
      }

      final result = await SharePlus.instance.share(
        ShareParams(files: files, subject: 'تصدير ${item.title}'),
      );

      if (!_shareWasAccepted(result)) {
        return false;
      }

      await _transactionService.runTransaction((txn) async {
        await _updateItemStatusInTxn(item, txn);

        for (final child in item.children) {
          await _updateItemStatusInTxn(child, txn);
        }
      });

      _items.removeWhere((element) => element.unified == item.unified);

      notifyListeners();

      return true;
    } catch (e, stackTrace) {
      debugPrint('scheduleSingle error: $e');
      debugPrintStack(stackTrace: stackTrace);

      _error = 'فشل في جدولة العنصر.';
      notifyListeners();

      return false;
    } finally {
      _isScheduling = false;
      notifyListeners();
    }
  }

  String _exportType(SyncItemType type) {
    switch (type) {
      case SyncItemType.user:
        return 'user';

      case SyncItemType.invoice:
        return 'fatora';

      case SyncItemType.payment:
        return 'payment';

      case SyncItemType.fatoraProduct:
        return 'fatoraProduct';
    }
  }

  bool _shareWasAccepted(ShareResult result) {
    return result.status != ShareResultStatus.dismissed;
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> _updateItemStatusInTxn(SyncItem item, Transaction txn) async {
    switch (item.type) {
      case SyncItemType.user:
        await _userService.markScheduled(item.originalObject as User, txn);
        break;

      case SyncItemType.invoice:
        await _invoiceService.markScheduled(item.originalObject as Fatora, txn);
        break;

      case SyncItemType.payment:
        await _paymentService.markScheduled(
          item.originalObject as Payment,
          txn,
        );
        break;

      case SyncItemType.fatoraProduct:
        await _invoiceService.markProductScheduled(
          item.originalObject as FatoraProduct,
          txn,
        );
        break;
    }
  }

  void clearError() {
    if (_error == null) return;

    _error = null;
    notifyListeners();
  }
}
