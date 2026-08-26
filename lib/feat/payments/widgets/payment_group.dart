import 'package:flutter/material.dart';
import 'package:naji/core/models/payment.dart';
import 'package:naji/feat/payments/controller/payment_controller.dart';
import 'package:naji/feat/payments/widgets/payment_card.dart';

class PaymentGroupWidget extends StatelessWidget {
  final PaymentGroup group;
  final bool collapsed;
  final String Function(String) userName;
  final VoidCallback onToggle;
  final Future<void> Function(Payment) onDelete;

  const PaymentGroupWidget({
    super.key,
    required this.group,
    required this.collapsed,
    required this.userName,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------------------------------------------------------------
        // GROUP HEADER
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
                        "${group.count} دفعة",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                if (group.totalSy != 0)
                  _GroupAmount(amount: group.totalSy, symbol: "ل.س"),

                if (group.totalDollar != 0) ...[
                  const SizedBox(width: 6),
                  _GroupAmount(amount: group.totalDollar, symbol: "\$"),
                ],
              ],
            ),
          ),
        ),

        // ---------------------------------------------------------------------
        // PAYMENTS
        // ---------------------------------------------------------------------
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: collapsed
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: group.payments
                .map(
                  (payment) => PaymentCard(
                    payment: payment,
                    userName: userName(payment.userUnified),
                    onDelete: () => onDelete(payment),
                  ),
                )
                .toList(),
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
        "${amount.toStringAsFixed(2)} $symbol",
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: colors.onPrimaryContainer,
        ),
      ),
    );
  }
}
