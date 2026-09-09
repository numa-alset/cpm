import 'package:flutter/material.dart';

import '../../../../core/models/user.dart';
import '../../../../core/models/user_balance.dart';

class UserCard extends StatelessWidget {
  final User user;
  final UserBalance balance;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const UserCard({
    super.key,
    required this.user,
    required this.balance,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final syNegative = balance.sy < 0;
    final dollarNegative = balance.dollar < 0;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // ---------------------------------------------------------------
              // HEADER
              // ---------------------------------------------------------------
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 25,
                      color: colors.onPrimaryContainer,
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
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 15,
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

                  PopupMenuButton<_MenuAction>(
                    tooltip: "المزيد",
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) {
                      switch (value) {
                        case _MenuAction.details:
                          onTap?.call();
                          break;

                        case _MenuAction.edit:
                          onEdit?.call();
                          break;

                        case _MenuAction.delete:
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: _MenuAction.details,
                        child: ListTile(
                          leading: Icon(Icons.visibility_outlined),
                          title: Text("التفاصيل"),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: _MenuAction.edit,
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text("تعديل"),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: _MenuAction.delete,
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_outline,
                            color: colors.error,
                          ),
                          title: Text(
                            "حذف",
                            style: TextStyle(color: colors.error),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ---------------------------------------------------------------
              // BALANCES
              // ---------------------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: _BalanceItem(
                      title: "الليرة السورية",
                      amount: balance.sy,
                      symbol: "ل.س",
                      icon: Icons.account_balance_wallet_outlined,
                      negative: syNegative,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _BalanceItem(
                      title: "الدولار",
                      amount: balance.dollar,
                      symbol: "\$",
                      icon: Icons.attach_money_rounded,
                      negative: dollarNegative,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ---------------------------------------------------------------
              // DETAILS BUTTON
              // ---------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text("عرض التفاصيل"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String title;
  final double amount;
  final String symbol;
  final IconData icon;
  final bool negative;

  const _BalanceItem({
    required this.title,
    required this.amount,
    required this.symbol,
    required this.icon,
    required this.negative,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final valueColor = negative ? colors.error : colors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: valueColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: valueColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: valueColor),

          const SizedBox(width: 7),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  "${amount.toStringAsFixed(2)} $symbol",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
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
}

enum _MenuAction { details, edit, delete }
