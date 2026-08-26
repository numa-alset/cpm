import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
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

class SyncItem {
  const SyncItem({
    required this.unified,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.originalObject,
    this.children = const [],
  });

  final String unified;
  final String title;
  final String subtitle;
  final SyncItemType type;
  final dynamic originalObject;
  final List<SyncItem> children;

  bool get hasChildren => children.isNotEmpty;
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
    return _items.where((e) => e.type == SyncItemType.user).length;
  }

  int get invoiceCount {
    return _items.where((e) => e.type == SyncItemType.invoice).length;
  }

  int get paymentCount {
    return _items.where((e) => e.type == SyncItemType.payment).length;
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

    // ------------------------------------------------------------
    // USERS
    // ------------------------------------------------------------

    for (final user in users) {
      items.add(
        SyncItem(
          unified: user.unified,
          title: user.name,
          subtitle: user.location,
          type: SyncItemType.user,
          originalObject: user,
        ),
      );
    }

    // ------------------------------------------------------------
    // PAYMENTS
    // ------------------------------------------------------------

    for (final payment in payments) {
      items.add(
        SyncItem(
          unified: payment.unified,
          title: 'دفعة',
          subtitle: _paymentSubtitle(payment),
          type: SyncItemType.payment,
          originalObject: payment,
        ),
      );
    }

    // ------------------------------------------------------------
    // PRODUCTS GROUPED BY INVOICE
    // ------------------------------------------------------------

    final productsByInvoice = <String, List<FatoraProduct>>{};

    for (final product in products) {
      productsByInvoice
          .putIfAbsent(product.fatoraUnified, () => [])
          .add(product);
    }

    // ------------------------------------------------------------
    // INVOICES
    // ------------------------------------------------------------

    for (final invoice in invoices) {
      final invoiceProducts = productsByInvoice.remove(invoice.unified) ?? [];

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
        ),
      );
    }

    // ------------------------------------------------------------
    // PRODUCTS WHOSE INVOICE IS ALREADY SCHEDULED
    //
    // This can happen when a new item is added to an existing
    // invoice after the invoice itself was already scheduled.
    // ------------------------------------------------------------

    for (final entry in productsByInvoice.entries) {
      final parentInvoice = invoices.cast<Fatora?>().firstWhere(
        (invoice) => invoice?.unified == entry.key,
        orElse: () => null,
      );

      if (parentInvoice != null) {
        items.add(
          SyncItem(
            unified: parentInvoice.unified,
            title: 'تعديل فاتورة',
            subtitle: 'تمت إضافة عناصر جديدة',
            type: SyncItemType.invoice,
            originalObject: parentInvoice,
            children: entry.value
                .map(_productToSyncItem)
                .toList(growable: false),
          ),
        );
      } else {
        // We don't know the parent invoice.
        // Keep the items visible instead of losing them.
        items.addAll(entry.value.map(_productToSyncItem));
      }
    }

    return items;
  }

  SyncItem _productToSyncItem(FatoraProduct product) {
    return SyncItem(
      unified: product.unified,
      title: product.productName,
      subtitle: 'الكمية: ${product.quantity} • الإجمالي: ${product.total}',
      type: SyncItemType.fatoraProduct,
      originalObject: product,
    );
  }

  String _paymentSubtitle(Payment payment) {
    return '${payment.amount} ${payment.currency}';
  }

  String _invoiceSubtitle(Fatora invoice) {
    final parts = <String>[];

    if (invoice.totalSy != 0) {
      parts.add('${invoice.totalSy} ل.س');
    }

    if (invoice.totalDollar != 0) {
      parts.add('${invoice.totalDollar} \$');
    }

    return parts.isEmpty ? 'بدون مبلغ' : parts.join(' • ');
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
    // ShareResultStatus.dismissed means the user closed/cancelled
    // the share sheet.
    return result.status != ShareResultStatus.dismissed;
  }

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> _updateItemStatusInTxn(SyncItem item, Transaction txn) async {
    print(item.type);
    print((item.originalObject as User).status);
    switch (item.type) {
      case SyncItemType.user:
        final user = item.originalObject as User;

        await _userService.markScheduled(user, txn);

        break;

      case SyncItemType.invoice:
        final invoice = item.originalObject as Fatora;

        await _invoiceService.markScheduled(invoice, txn);

        break;

      case SyncItemType.payment:
        final payment = item.originalObject as Payment;

        await _paymentService.markScheduled(payment, txn);

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
