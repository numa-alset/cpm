import 'package:flutter/material.dart';
import 'package:naji/core/models/currency.dart';
import 'package:naji/core/models/payment.dart';

class PaymentCard extends StatelessWidget {
  final Payment payment;
  final String userName;
  final VoidCallback onDelete;

  const PaymentCard({
    super.key,
    required this.payment,
    required this.userName,
    required this.onDelete,
  });

  String _formatDate(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);

    return "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isDollar = payment.currency == Currency.dollar;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isDollar
                    ? Icons.attach_money_rounded
                    : Icons.account_balance_wallet_outlined,
                color: colors.onSecondaryContainer,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(payment.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${payment.amount.toStringAsFixed(2)} ${payment.currency.symbol}",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.primary,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  "دفعة",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            PopupMenuButton<_PaymentAction>(
              tooltip: "المزيد",
              onSelected: (action) {
                if (action == _PaymentAction.delete) {
                  onDelete();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _PaymentAction.delete,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: colors.error,
                    ),
                    title: Text("حذف", style: TextStyle(color: colors.error)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _PaymentAction { delete }
