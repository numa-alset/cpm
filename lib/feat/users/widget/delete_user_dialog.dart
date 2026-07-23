import 'package:flutter/material.dart';

import '../../../../core/models/user.dart';

Future<bool?> showDeleteUserDialog(BuildContext context, User user) {
  return showDialog<bool>(
    context: context,
    // 1. Name the dialog's context "dialogContext" instead of "_"
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 42),
      title: const Text("حذف المستخدم", textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            child: Icon(
              user.type == UserType.buyer ? Icons.shopping_cart : Icons.store,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            user.location,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "الرصيد: ${user.total.toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          const Text(
            "لن يمكن التراجع عن هذه العملية.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
      actions: [
        TextButton(
          // 2. Use dialogContext here
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text("إلغاء"),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.delete),
          label: const Text("حذف"),
          // 3. Use dialogContext here
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
      ],
    ),
  );
}
