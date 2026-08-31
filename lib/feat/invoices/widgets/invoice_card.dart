import 'package:flutter/material.dart';
import 'package:naji/core/models/currency.dart';
import 'package:naji/core/models/fatora.dart';
import 'package:naji/core/models/fatora_product.dart';

class InvoiceCard extends StatelessWidget {
  final Fatora invoice;
  final bool expanded;
  final bool loadingProducts;

  final List<FatoraProduct> products;

  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final String userName;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.expanded,
    required this.products,
    required this.loadingProducts,
    required this.onToggle,
    required this.onDelete,
    required this.onShare,
    required this.userName,
  });

  String _date(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // -------------------------------------------------------------------
          // INVOICE HEADER
          // -------------------------------------------------------------------
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.primary,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: colors.onPrimaryContainer,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName.isNotEmpty
                              ? userName
                              : 'فاتورة', // Show name instead of generic text
                          maxLines: 1,
                          overflow: TextOverflow
                              .ellipsis, // Prevents overflow if name is too long
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _date(invoice.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (invoice.totalSy != 0)
                        _Amount(amount: invoice.totalSy, symbol: 'ل.س'),

                      if (invoice.totalDollar != 0)
                        _Amount(amount: invoice.totalDollar, symbol: '\$'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // EXPANDED CONTENT
          // -------------------------------------------------------------------
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _ExpandedInvoice(
              invoice: invoice,
              products: products,
              loadingProducts: loadingProducts,
              onDelete: onDelete,
              onShare: onShare,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedInvoice extends StatelessWidget {
  final Fatora invoice;
  final List<FatoraProduct> products;
  final bool loadingProducts;

  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _ExpandedInvoice({
    required this.invoice,
    required this.products,
    required this.loadingProducts,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: colors.outlineVariant),

        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'المنتجات',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 8),

              if (loadingProducts)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (products.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'لا توجد منتجات',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                ...products.map((product) => _ProductRow(product: product)),

              if (invoice.note?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: 10),
                Text(
                  'ملاحظة',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(invoice.note ?? ""),
              ],

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('مشاركة'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('حذف'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  final FatoraProduct product;

  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 3),

                Text(
                  '${product.quantity} × '
                  '${product.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '${product.total.toStringAsFixed(2)} '
            '${product.currency == Currency.sy ? 'ل.س' : '\$'}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  final double amount;
  final String symbol;

  const _Amount({required this.amount, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${amount.toStringAsFixed(2)} $symbol',
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}
