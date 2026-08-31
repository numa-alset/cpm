import 'package:flutter/material.dart';
import 'package:naji/core/models/fatora.dart';
import 'package:naji/core/models/fatora_product.dart';
import 'package:naji/feat/invoices/controller/invoices_controller.dart';
import 'package:naji/feat/invoices/widgets/invoice_card.dart';

class InvoiceGroupWidget extends StatelessWidget {
  final InvoiceGroup group;
  final bool collapsed;

  final bool Function(String) isExpanded;
  final VoidCallback onToggle;

  final Future<void> Function(Fatora) onDelete;
  final Future<void> Function(Fatora) onShare;

  final List<FatoraProduct> Function(String) productsFor;
  final bool Function(String) isLoadingProducts;
  final Future<void> Function(String) onToggleInvoice;
  final String Function(String) getUserName;

  const InvoiceGroupWidget({
    super.key,
    required this.group,
    required this.collapsed,
    required this.isExpanded,
    required this.onToggle,
    required this.onDelete,
    required this.onShare,
    required this.productsFor,
    required this.isLoadingProducts,
    required this.onToggleInvoice,
    required this.getUserName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------------------------------------------------------------
        // DATE GROUP HEADER
        // ---------------------------------------------------------------------
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: collapsed ? 0 : 0.5,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colors.primary,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.key,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${group.count} فاتورة',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                if (group.totalSy != 0)
                  _GroupAmount(amount: group.totalSy, symbol: 'ل.س'),

                if (group.totalDollar != 0) ...[
                  const SizedBox(width: 6),
                  _GroupAmount(amount: group.totalDollar, symbol: '\$'),
                ],
              ],
            ),
          ),
        ),

        // ---------------------------------------------------------------------
        // INVOICES
        // ---------------------------------------------------------------------
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: collapsed
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: group.invoices.map((invoice) {
              return InvoiceCard(
                invoice: invoice,
                expanded: isExpanded(invoice.unified),
                products: productsFor(invoice.unified),
                loadingProducts: isLoadingProducts(invoice.unified),
                onToggle: () => onToggleInvoice(invoice.unified),
                onDelete: () => onDelete(invoice),
                onShare: () => onShare(invoice),
                userName: getUserName(invoice.userUnified),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _GroupAmount extends StatelessWidget {
  final double amount;
  final String symbol;

  const _GroupAmount({required this.amount, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${amount.toStringAsFixed(2)} $symbol',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: colors.onPrimaryContainer,
        ),
      ),
    );
  }
}
