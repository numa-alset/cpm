import 'package:flutter/material.dart';

import '../../../../core/models/user.dart';

Future<bool?> showDeleteUserDialog(BuildContext context, User user) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 42),
      title: const Text("حذف المستخدم", textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(radius: 28, child: Icon(Icons.store)),
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
          const SizedBox(height: 12),
          // عرض الأرصدة الثنائية (ليرة ودولار)
          Text(
            "رصيد الليرة: ${user.totalSy.toStringAsFixed(2)} ل.س",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "رصيد الدولار: ${user.totalDollar.toStringAsFixed(2)} \$",
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
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
      ],
    ),
  );
}
