import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:naji/core/models/currency.dart';
import 'package:naji/core/models/fatora.dart';
import 'package:naji/core/models/fatora_product.dart';
import 'package:naji/core/models/user_balance.dart';
import 'package:naji/core/router/route_pages.dart';
import 'package:naji/core/services/invoice_pdf_service.dart';
import 'package:naji/core/services/invoice_service.dart';
import 'package:naji/core/services/payment_service.dart';
import 'package:naji/core/services/user_report_service.dart';
import 'package:naji/feat/users/controllers/user_details_controller.dart';
import 'package:naji/feat/users/screen/edit_invoice_screen.dart';
import 'package:naji/feat/users/screen/edit_payment_screen.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/user.dart';
import '../../../../core/services/user_service.dart';

class UserDetailsScreen extends StatelessWidget {
  final String userUuid;

  const UserDetailsScreen({super.key, required this.userUuid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserDetailsController(
        userUnified: userUuid,
        userService: GetIt.I<UserService>(),
        invoiceService: GetIt.I<InvoiceService>(),
        paymentService: GetIt.I<PaymentService>(),
      )..load(),
      child: const _UserDetailsView(),
    );
  }
}

class _UserDetailsView extends StatefulWidget {
  const _UserDetailsView();

  @override
  State<_UserDetailsView> createState() => _UserDetailsViewState();
}

class _UserDetailsViewState extends State<_UserDetailsView> {
  final Set<String> _expandedInvoiceGroups = {};
  final Set<String> _expandedPaymentGroups = {};

  String _formatDate(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);

    return "${date.year}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _exportReport(
    BuildContext context,
    UserDetailsController controller, {
    required String format,
  }) async {
    final user = controller.user;
    if (user == null) return;

    try {
      if (format == 'pdf') {
        await UserReportService.sharePdfReport(
          user: user,
          balance: controller.balance,
          invoices: controller.invoices,
          payments: controller.payments,
        );
      } else {
        await UserReportService.shareExcelReport(
          user: user,
          balance: controller.balance,
          invoices: controller.invoices,
          payments: controller.payments,
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            format == 'pdf'
                ? 'تم تجهيز تقرير PDF للمستخدم'
                : 'تم تجهيز تقرير Excel للمستخدم',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر تصدير التقرير: $e')));
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("حذف الدفعة"),
            content: const Text(
              "هل أنت متأكد أنك تريد حذف هذه الدفعة؟ سيتم استرجاع المبلغ لرصيد العميل.",
            ),
            actions: [
              TextButton(
                onPressed: () => dialogContext.pop(false),
                child: const Text("إلغاء"),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => dialogContext.pop(true),
                child: const Text("حذف"),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _confirmDeleteInvoice(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("حذف الفاتورة"),
            content: const Text(
              "هل أنت متأكد أنك تريد حذف هذه الفاتورة؟ سيتم استرجاع المبلغ لرصيد العميل.",
            ),
            actions: [
              TextButton(
                onPressed: () => dialogContext.pop(false),
                child: const Text("إلغاء"),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => dialogContext.pop(true),
                child: const Text("حذف"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UserDetailsController>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (controller.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("تفاصيل المستخدم")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.error != null || controller.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("خطأ")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: colors.error,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  controller.error ?? "المستخدم غير موجود",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: controller.load,
                  icon: const Icon(Icons.refresh),
                  label: const Text("إعادة المحاولة"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = controller.user!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colors.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(
            user.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'تصدير PDF',
              onPressed: () =>
                  _exportReport(context, controller, format: 'pdf'),
              icon: const Icon(Icons.picture_as_pdf_rounded),
            ),
            IconButton(
              tooltip: 'تصدير Excel',
              onPressed: () =>
                  _exportReport(context, controller, format: 'excel'),
              icon: const Icon(Icons.table_view_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddOptions(context, user),
          icon: const Icon(Icons.add),
          label: const Text("إضافة"),
        ),
        body: RefreshIndicator(
          onRefresh: controller.load,
          child: Column(
            children: [
              _buildUserSummary(context, user, controller.balance),

              const SizedBox(height: 8),

              _buildTabs(context),

              Expanded(
                child: TabBarView(
                  children: [
                    _buildInvoicesTab(context, controller),
                    _buildPaymentsTab(context, controller),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // USER SUMMARY
  // ---------------------------------------------------------------------------

  Widget _buildUserSummary(
    BuildContext context,
    User user,
    UserBalance? balance,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final displayBalance = balance ?? const UserBalance(sy: 0.0, dollar: 0.0);
    final syNegative = displayBalance.sy < 0;
    final dollarNegative = displayBalance.dollar < 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: colors.onPrimaryContainer,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildBalanceCard(
                      context,
                      title: "الليرة السورية",
                      amount: displayBalance.sy,
                      symbol: Currency.sy.symbol,
                      icon: Icons.currency_exchange_rounded,
                      isNegative: syNegative,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _buildBalanceCard(
                      context,
                      title: "الدولار",
                      amount: displayBalance.dollar,
                      symbol: Currency.dollar.symbol,
                      icon: Icons.attach_money_rounded,
                      isNegative: dollarNegative,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context, {
    required String title,
    required double amount,
    required String symbol,
    required IconData icon,
    required bool isNegative,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final valueColor = isNegative ? colors.error : colors.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: valueColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: valueColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: valueColor),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  "${amount.toStringAsFixed(2)} $symbol",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TABS
  // ---------------------------------------------------------------------------

  Widget _buildTabs(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        indicator: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(11),
        ),
        labelColor: colors.onPrimary,
        unselectedLabelColor: colors.onSurfaceVariant,
        tabs: const [
          Tab(
            icon: Icon(Icons.receipt_long_rounded, size: 20),
            text: "الفواتير",
          ),
          Tab(icon: Icon(Icons.payments_rounded, size: 20), text: "الدفعات"),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INVOICES
  // ---------------------------------------------------------------------------

  Widget _buildInvoicesTab(
    BuildContext context,
    UserDetailsController controller,
  ) {
    if (controller.invoices.isEmpty) {
      return _buildEmptyState(
        context,
        "لا توجد فواتير",
        Icons.receipt_long_outlined,
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: controller.invoiceGroupKeys.length,
      itemBuilder: (context, groupIndex) {
        final groupKey = controller.invoiceGroupKeys[groupIndex];

        final groupedInvoices = controller.groupedInvoices[groupKey] ?? [];

        final isExpanded = _expandedInvoiceGroups.contains(groupKey);

        return _buildInvoiceGroup(
          context,
          controller,
          groupKey,
          groupedInvoices,
          isExpanded,
        );
      },
    );
  }

  Widget _buildInvoiceGroup(
    BuildContext context,
    UserDetailsController controller,
    String groupKey,
    List<dynamic> groupedInvoices,
    bool isExpanded,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedInvoiceGroups.add(groupKey);
              } else {
                _expandedInvoiceGroups.remove(groupKey);
              }
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: colors.onPrimaryContainer,
            ),
          ),
          title: Text(
            groupKey,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            "${groupedInvoices.length} فاتورة",
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          children: [
            ...List.generate(groupedInvoices.length, (index) {
              final invoiceRecord = groupedInvoices[index];

              final fatora = invoiceRecord.$1;
              final products = invoiceRecord.$2;

              return _buildInvoiceCard(context, controller, fatora, products);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    UserDetailsController controller,
    Fatora fatora,
    List<FatoraProduct> products,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final invoiceTotals = <String>[];

    if (fatora.totalSy != 0) {
      invoiceTotals.add(
        '${fatora.totalSy.toStringAsFixed(2)} ${Currency.sy.symbol}',
      );
    }

    if (fatora.totalDollar != 0) {
      invoiceTotals.add(
        '${fatora.totalDollar.toStringAsFixed(2)} ${Currency.dollar.symbol}',
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.only(bottom: 10),

        // -----------------------------------------------------------------------
        // HEADER
        // -----------------------------------------------------------------------
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            Icons.receipt_rounded,
            color: colors.onPrimaryContainer,
            size: 21,
          ),
        ),

        title: Text(
          "فاتورة",
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),

        subtitle: Text(
          "${_formatDate(fatora.date)} • ${products.length} منتجات",
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),

        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ...invoiceTotals.map(
              (value) => Text(
                value,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),

        // -----------------------------------------------------------------------
        // CONTENT
        // -----------------------------------------------------------------------
        children: [
          if (fatora.note != null && fatora.note!.trim().isNotEmpty)
            _buildNote(context, fatora.note!),

          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "لا توجد منتجات مسجلة",
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            )
          else
            ...products.map((product) => _buildProductRow(context, product)),

          const SizedBox(height: 8),

          // ---------------------------------------------------------------------
          // ACTIONS
          // ---------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                // Share
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      try {
                        await InvoicePdfService.shareInvoice(
                          user: controller.user!,
                          fatora: fatora,
                          products: products,
                        );
                      } catch (e) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("تعذر مشاركة الفاتورة: $e")),
                        );
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 19),
                    label: const Text("مشاركة الفاتورة PDF"),
                  ),
                ),

                const SizedBox(height: 8),

                // Edit + Delete
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditInvoiceScreen(
                                invoice: fatora,
                                invoiceProducts: products,
                              ),
                            ),
                          );

                          if (result == true && context.mounted) {
                            controller.load();
                          }
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text("تعديل"),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.error,
                        ),
                        onPressed: () async {
                          final confirm = await _confirmDeleteInvoice(context);

                          if (!confirm || !context.mounted) return;

                          final success = await controller.deleteInvoice(
                            fatora.unified,
                          );

                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("تم حذف الفاتورة بنجاح"),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text("حذف"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNote(BuildContext context, String note) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notes_rounded, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(BuildContext context, dynamic product) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final productTotal = product.price * product.quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${product.quantity} × ${product.price} ${product.currency.symbol}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            "${productTotal.toStringAsFixed(2)} ${product.currency.symbol}",
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PAYMENTS
  // ---------------------------------------------------------------------------

  Widget _buildPaymentsTab(
    BuildContext context,
    UserDetailsController controller,
  ) {
    if (controller.payments.isEmpty) {
      return _buildEmptyState(
        context,
        "لا توجد دفعات",
        Icons.payments_outlined,
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: controller.paymentGroupKeys.length,
      itemBuilder: (context, groupIndex) {
        final groupKey = controller.paymentGroupKeys[groupIndex];

        final groupedPayments = controller.groupedPayments[groupKey] ?? [];

        final isExpanded = _expandedPaymentGroups.contains(groupKey);

        return _buildPaymentGroup(
          context,
          controller,
          groupKey,
          groupedPayments,
          isExpanded,
        );
      },
    );
  }

  Widget _buildPaymentGroup(
    BuildContext context,
    UserDetailsController controller,
    String groupKey,
    List<dynamic> groupedPayments,
    bool isExpanded,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedPaymentGroups.add(groupKey);
            } else {
              _expandedPaymentGroups.remove(groupKey);
            }
          });
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.tertiaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.payments_rounded,
            color: colors.onTertiaryContainer,
          ),
        ),
        title: Text(
          groupKey,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          "${groupedPayments.length} دفعة",
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        children: [
          ...groupedPayments.map(
            (payment) => _buildPaymentCard(context, controller, payment),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    UserDetailsController controller,
    dynamic payment,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  color: colors.onTertiaryContainer,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "دفعة مالية",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(payment.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                "${payment.amount.toStringAsFixed(2)} ${payment.currency.symbol}",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.tertiary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditPaymentScreen(payment: payment),
                      ),
                    );

                    if (result == true && context.mounted) {
                      controller.load();
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text("تعديل"),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                  ),
                  onPressed: () async {
                    final confirm = await _confirmDelete(context);

                    if (!confirm || !context.mounted) return;

                    final success = await controller.deletePayment(
                      payment.unified,
                    );

                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("تم حذف الدفعة بنجاح")),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text("حذف"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 360,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 34, color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ADD
  // ---------------------------------------------------------------------------

  void _showAddOptions(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "إضافة عملية جديدة",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 16),

              _buildAddOption(
                context,
                icon: Icons.receipt_long_rounded,
                title: "إضافة فاتورة جديدة",
                subtitle: "تسجيل فاتورة ومنتجاتها",
                color: Theme.of(context).colorScheme.primary,
                onTap: () async {
                  sheetContext.pop();

                  final result = await context.push<bool>(
                    AppRouter.addInvoicePath,
                    extra: user.unified,
                  );

                  if (result == true && context.mounted) {
                    context.read<UserDetailsController>().load();
                  }
                },
              ),

              const SizedBox(height: 8),

              _buildAddOption(
                context,
                icon: Icons.payments_rounded,
                title: "إضافة دفعة مالية",
                subtitle: "تسجيل دفعة من المستخدم",
                color: Theme.of(context).colorScheme.tertiary,
                onTap: () async {
                  sheetContext.pop();

                  final result = await context.push<bool>(
                    AppRouter.addPaymentPath,
                    extra: user.unified,
                  );

                  if (result == true && context.mounted) {
                    context.read<UserDetailsController>().load();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_left_rounded),
          ],
        ),
      ),
    );
  }
}
