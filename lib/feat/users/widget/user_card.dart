import 'package:flutter/material.dart';

import '../../../../core/models/user.dart';

class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const UserCard({
    super.key,
    required this.user,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isBuyer = user.type == UserType.buyer;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isBuyer
                    ? Colors.blue.shade100
                    : Colors.orange.shade100,
                child: Icon(
                  isBuyer ? Icons.shopping_cart : Icons.store,
                  color: isBuyer ? Colors.blue : Colors.orange,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: Icon(
                            isBuyer ? Icons.shopping_cart : Icons.store,
                            size: 18,
                          ),
                          label: Text(isBuyer ? "مشتري" : "بائع"),
                        ),

                        Chip(
                          avatar: const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 18,
                          ),
                          label: Text(user.total.toStringAsFixed(2)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              PopupMenuButton<_MenuAction>(
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
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _MenuAction.details,
                    child: ListTile(
                      leading: Icon(Icons.visibility_outlined),
                      title: Text("التفاصيل"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.edit,
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text("تعديل"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: _MenuAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text("حذف", style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
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
}

enum _MenuAction { details, edit, delete }
