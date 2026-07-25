import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:naji/core/database/fatora_db.dart';
import 'package:naji/core/database/payment_db.dart';
import 'package:naji/core/database/product_db.dart';
import 'package:naji/core/database/products_fatoras_db.dart';
import 'package:naji/core/database/user_db.dart';
import 'package:naji/core/models/enum_status.dart';
import 'package:naji/core/models/fatora.dart';
import 'package:naji/core/models/fatora_product.dart';
import 'package:naji/core/models/payment.dart';
import 'package:naji/core/models/product.dart';
import 'package:naji/core/models/user.dart';
import 'package:naji/core/services/backup_service.dart';
import 'package:naji/core/services/invoice_service.dart';
import 'package:naji/core/services/payment_service.dart';
import 'package:naji/core/services/product_service.dart';
import 'package:naji/core/services/transaction_service.dart';
import 'package:naji/core/services/user_service.dart';
import 'package:share_plus/share_plus.dart';

enum SyncItemType { user, product, invoice, payment, fatoraProduct }

class SyncItem {
  final String unified;
  final String title;
  final String subtitle;
  final SyncItemType type;
  final dynamic originalObject;
  final List<SyncItem> children; // Added to hold FatoraProducts

  SyncItem({
    required this.unified,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.originalObject,
    this.children = const [],
  });
}

class HomeController extends ChangeNotifier {
  final UserService _userService = GetIt.I<UserService>();
  final ProductService _productService = GetIt.I<ProductService>();
  final InvoiceService _invoiceService = GetIt.I<InvoiceService>();
  final PaymentService _paymentService = GetIt.I<PaymentService>();
  final BackupService _backupService = GetIt.I<BackupService>();
  final TransactionService _transactionService = GetIt.I<TransactionService>();

  List<SyncItem> unscheduledItems = [];
  bool isLoading = true;
  String? error;

  Future<void> loadData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _userService.getNotScheduledUsers(),
        _productService.getNotScheduledProducts(),
        _invoiceService.getNotScheduledInvoices(),
        _paymentService.getNotScheduledPayments(),
        _invoiceService.getNotScheduledInvoicesProducts(),
      ]);

      final users = results[0] as List<User>;
      final products = results[1] as List<Product>;
      final invoices = results[2] as List<Fatora>;
      final payments = results[3] as List<Payment>;
      final fatoraProducts = results[4] as List<FatoraProduct>;

      final List<SyncItem> items = [];

      // 1. Add Users, Products, Payments
      items.addAll(
        users.map(
          (u) => SyncItem(
            unified: u.unified,
            title: u.name,
            subtitle: 'مستخدم',
            type: SyncItemType.user,
            originalObject: u,
          ),
        ),
      );

      items.addAll(
        products.map(
          (p) => SyncItem(
            unified: p.unified,
            title: p.name,
            subtitle: 'منتج',
            type: SyncItemType.product,
            originalObject: p,
          ),
        ),
      );

      items.addAll(
        payments.map(
          (p) => SyncItem(
            unified: p.unified,
            title: 'دفعة نقدية',
            subtitle: 'المبلغ: ${p.amount}',
            type: SyncItemType.payment,
            originalObject: p,
          ),
        ),
      );

      // 2. Map Products to their Invoices
      final Map<String, List<FatoraProduct>> productsByInvoice = {};
      for (var fp in fatoraProducts) {
        productsByInvoice.putIfAbsent(fp.fatoraUnified, () => []).add(fp);
      }

      // 3. Process Unscheduled Invoices and attach their products
      for (var i in invoices) {
        final productsForThisInvoice =
            productsByInvoice.remove(i.unified) ?? [];

        final children = productsForThisInvoice
            .map(
              (fp) => SyncItem(
                unified: fp.unified,
                title: fp.productName,
                subtitle: 'الكمية: ${fp.quantity} | الإجمالي: ${fp.total}',
                type: SyncItemType.fatoraProduct,
                originalObject: fp,
              ),
            )
            .toList();

        items.add(
          SyncItem(
            unified: i.unified,
            title: 'فاتورة ${i.type.value == "sale" ? "مبيعات" : "مشتريات"}',
            subtitle: 'المجموع: ${i.total}',
            type: SyncItemType.invoice,
            originalObject: i,
            children: children,
          ),
        );
      }

      // 4. Handle orphaned products (Products added to an invoice that was ALREADY scheduled)
      for (var entry in productsByInvoice.entries) {
        final parentInvoice = await _invoiceService.getInvoice(entry.key);
        final children = entry.value
            .map(
              (fp) => SyncItem(
                unified: fp.unified,
                title: fp.productName,
                subtitle: 'الكمية: ${fp.quantity} | الإجمالي: ${fp.total}',
                type: SyncItemType.fatoraProduct,
                originalObject: fp,
              ),
            )
            .toList();

        if (parentInvoice != null) {
          items.add(
            SyncItem(
              unified: parentInvoice.unified,
              title:
                  'تعديلات فاتورة ${parentInvoice.type.value == "sale" ? "مبيعات" : "مشتريات"}',
              subtitle: 'تم إضافة عناصر جديدة',
              type: SyncItemType.invoice,
              originalObject: parentInvoice,
              children: children,
            ),
          );
        } else {
          // If parent is somehow completely missing, just show items standalone
          items.addAll(children);
        }
      }

      unscheduledItems = items;
    } catch (e) {
      error = "حدث خطأ أثناء تحميل البيانات: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> scheduleAll() async {
    if (unscheduledItems.isEmpty) return false;
    isLoading = true;
    notifyListeners();

    try {
      final file = await _backupService.exportUnsynced();
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'بيانات الجدولة'),
      );

      await _transactionService.runTransaction((txn) async {
        for (var item in unscheduledItems) {
          await _updateItemStatusInTxn(item, txn);
          for (var child in item.children) {
            await _updateItemStatusInTxn(child, txn);
          }
        }
      });

      await loadData();
      return true;
    } catch (e) {
      error = "فشل في جدولة الكل: $e";
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> scheduleSingle(SyncItem item) async {
    try {
      List<XFile> filesToShare = [];

      // Helper to export and attach a file
      Future<void> exportAndAttach(SyncItem i) async {
        final file = await _backupService.exportSingleRecord(
          type: i.type.name,
          unified: i.unified,
        );
        filesToShare.add(XFile(file.path));
      }

      // 1. Export main item and all children
      await exportAndAttach(item);
      for (var child in item.children) {
        await exportAndAttach(child);
      }

      // 2. Share them together in one batch
      await SharePlus.instance.share(
        ShareParams(files: filesToShare, subject: 'تصدير ${item.title}'),
      );

      // 3. Update DB for item and children
      await _transactionService.runTransaction((txn) async {
        await _updateItemStatusInTxn(item, txn);
        for (var child in item.children) {
          await _updateItemStatusInTxn(child, txn);
        }
      });

      unscheduledItems.removeWhere(
        (element) => element.unified == item.unified,
      );
      notifyListeners();
      return true;
    } catch (e) {
      error = "فشل في جدولة العنصر: $e";
      notifyListeners();
      return false;
    }
  }

  Future<void> _updateItemStatusInTxn(SyncItem item, dynamic txn) async {
    switch (item.type) {
      case SyncItemType.user:
        final obj = (item.originalObject as User).copyWith(
          status: Status.scheduled,
        );
        await UserDB().update(obj, txn);
        break;
      case SyncItemType.product:
        final obj = (item.originalObject as Product).copyWith(
          status: Status.scheduled,
        );
        await ProductDB().update(obj, txn);
        break;
      case SyncItemType.invoice:
        final obj = (item.originalObject as Fatora).copyWith(
          status: Status.scheduled,
        );
        await FatoraDB().update(obj, txn);
        break;
      case SyncItemType.payment:
        final obj = (item.originalObject as Payment).copyWith(
          status: Status.scheduled,
        );
        await PaymentDB().update(obj, txn);
        break;
      case SyncItemType.fatoraProduct:
        final obj = (item.originalObject as FatoraProduct).copyWith(
          status: Status.scheduled,
        );
        await FatoraProductsDB().update(obj, txn);
        break;
    }
  }
}
