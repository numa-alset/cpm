import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:naji/core/models/fatora.dart';
import 'package:naji/core/models/user.dart';
import 'package:naji/core/repositories/fatora_repository.dart';
import 'package:naji/core/repositories/user_repository.dart';
import 'package:naji/locator/locator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final FatoraRepository _fatoraRepository;
  late final UserRepository _userRepository;

  @override
  void initState() {
    super.initState();
    _fatoraRepository = getIt<FatoraRepository>();
    _userRepository = getIt<UserRepository>();
  }

  Future<List<Map<String, dynamic>>> _getUnscheduledTasksWithUsers() async {
    final invoices = await _fatoraRepository.getNotScheduled();
    final List<Map<String, dynamic>> tasksWithUsers = [];

    for (var invoice in invoices) {
      final user = await _userRepository.get(invoice.userUnified);
      tasksWithUsers.add({
        'invoice': invoice,
        'user': user,
      });
    }

    return tasksWithUsers;
  }

  String _formatDate(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  String _getInvoiceTypeLabel(InvoiceType type) {
    return type == InvoiceType.sale ? 'بيع' : 'شراء';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المهام غير المجدولة'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getUnscheduledTasksWithUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('خطأ: ${snapshot.error}'),
            );
          }

          final tasksWithUsers = snapshot.data ?? [];

          if (tasksWithUsers.isEmpty) {
            return const Center(
              child: Text('لا توجد مهام غير مجدولة'),
            );
          }

          return ListView.builder(
            itemCount: tasksWithUsers.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final task = tasksWithUsers[index];
              final invoice = task['invoice'] as Fatora;
              final user = task['user'] as User?;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              user?.name ?? 'مستخدم غير معروف',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: invoice.type == InvoiceType.sale
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              _getInvoiceTypeLabel(invoice.type),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: invoice.type == InvoiceType.sale
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'التاريخ: ${_formatDate(invoice.date)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'المبلغ: ${invoice.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (invoice.note != null && invoice.note!.isNotEmpty) ...[
                        const SizedBox(height: 8.0),
                        Text(
                          'ملاحظات: ${invoice.note}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
