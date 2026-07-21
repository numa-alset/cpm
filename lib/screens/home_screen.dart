import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:naji/core/models/fatora.dart';
import 'package:naji/core/models/payment.dart';
import 'package:naji/core/models/product.dart';
import 'package:naji/core/models/user.dart';
import 'package:naji/core/repositories/fatora_repository.dart';
import 'package:naji/core/repositories/payment_repository.dart';
import 'package:naji/core/repositories/product_repository.dart';
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
  late final PaymentRepository _paymentRepository;
  late final ProductRepository _productRepository;

  @override
  void initState() {
    super.initState();
    _fatoraRepository = getIt<FatoraRepository>();
    _userRepository = getIt<UserRepository>();
    _paymentRepository = getIt<PaymentRepository>();
    _productRepository = getIt<ProductRepository>();
  }

  Future<Map<String, dynamic>> _getUnscheduledData() async {
    final invoices = await _fatoraRepository.getNotScheduled();
    final users = await _userRepository.getNotScheduled();
    final payments = await _paymentRepository.getNotScheduled();
    final products = await _productRepository.getNotScheduled();

    final List<Map<String, dynamic>> invoicesWithUsers = [];
    for (var invoice in invoices) {
      final user = await _userRepository.get(invoice.userUnified);
      invoicesWithUsers.add({'invoice': invoice, 'user': user});
    }

    final List<Map<String, dynamic>> paymentsWithUsers = [];
    for (var payment in payments) {
      final user = await _userRepository.get(payment.userUnified);
      paymentsWithUsers.add({'payment': payment, 'user': user});
    }

    return {
      'invoices': invoicesWithUsers,
      'users': users,
      'payments': paymentsWithUsers,
      'products': products,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المهام غير المجدولة')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUnscheduledData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }

          final data = snapshot.data ?? {};
          final invoicesData =
              (data['invoices'] ?? []) as List<Map<String, dynamic>>;
          final users = (data['users'] ?? []) as List<User>;
          final paymentsData =
              (data['payments'] ?? []) as List<Map<String, dynamic>>;
          final products = (data['products'] ?? []) as List<Product>;

          final hasData =
              invoicesData.isNotEmpty ||
              users.isNotEmpty ||
              paymentsData.isNotEmpty ||
              products.isNotEmpty;

          if (!hasData) {
            return const Center(child: Text('لا توجد مهام غير مجدولة'));
          }

          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              if (invoicesData.isNotEmpty)
                _UnscheduledSection(
                  title: 'الفواتير غير المجدولة',
                  count: invoicesData.length,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invoicesData.length,
                    itemBuilder: (context, index) {
                      final task = invoicesData[index];
                      return UnscheduledInvoiceCard(
                        invoice: task['invoice'] as Fatora,
                        user: task['user'] as User?,
                        onUserTap: () => _navigateToUserDetails(
                          context,
                          task['user'] as User?,
                        ),
                        onInvoiceTap: () => _navigateToInvoiceDetails(
                          context,
                          task['invoice'] as Fatora,
                        ),
                      );
                    },
                  ),
                ),
              if (paymentsData.isNotEmpty)
                _UnscheduledSection(
                  title: 'المدفوعات غير المجدولة',
                  count: paymentsData.length,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: paymentsData.length,
                    itemBuilder: (context, index) {
                      final task = paymentsData[index];
                      return UnscheduledPaymentCard(
                        payment: task['payment'] as Payment,
                        user: task['user'] as User?,
                        onUserTap: () => _navigateToUserDetails(
                          context,
                          task['user'] as User?,
                        ),
                        onPaymentTap: () => _navigateToPaymentDetails(
                          context,
                          task['payment'] as Payment,
                        ),
                      );
                    },
                  ),
                ),
              if (users.isNotEmpty)
                _UnscheduledSection(
                  title: 'المستخدمون غير المجدولون',
                  count: users.length,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return UnscheduledUserCard(
                        user: users[index],
                        onTap: () =>
                            _navigateToUserDetails(context, users[index]),
                      );
                    },
                  ),
                ),
              if (products.isNotEmpty)
                _UnscheduledSection(
                  title: 'المنتجات غير المجدولة',
                  count: products.length,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return UnscheduledProductCard(
                        product: products[index],
                        onTap: () =>
                            _navigateToProductDetails(context, products[index]),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToInvoiceDetails(BuildContext context, Fatora invoice) {
    Navigator.of(context).pushNamed('fatora_screen', arguments: invoice);
  }

  void _navigateToPaymentDetails(BuildContext context, Payment payment) {
    Navigator.of(
      context,
    ).pushNamed('payment_details_screen', arguments: payment);
  }

  void _navigateToUserDetails(BuildContext context, User? user) {
    if (user == null) return;
    Navigator.of(context).pushNamed('user_details_screen', arguments: user);
  }

  void _navigateToProductDetails(BuildContext context, Product product) {
    Navigator.of(
      context,
    ).pushNamed('product_details_screen', arguments: product);
  }
}

class _UnscheduledSection extends StatelessWidget {
  final String title;
  final int count;
  final Widget child;

  const _UnscheduledSection({
    required this.title,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        child,
        const SizedBox(height: 8),
      ],
    );
  }
}

class UnscheduledInvoiceCard extends StatelessWidget {
  final Fatora invoice;
  final User? user;
  final VoidCallback onUserTap;
  final VoidCallback onInvoiceTap;

  const UnscheduledInvoiceCard({
    required this.invoice,
    required this.user,
    required this.onUserTap,
    required this.onInvoiceTap,
    super.key,
  });

  String _formatDate(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  String _getInvoiceTypeLabel(InvoiceType type) {
    return type == InvoiceType.sale ? 'بيع' : 'شراء';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onUserTap,
                    child: Text(
                      user?.name ?? 'مستخدم غير معروف',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
            const SizedBox(height: 12.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onInvoiceTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'عرض التفاصيل',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UnscheduledUserCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const UnscheduledUserCard({
    required this.user,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: ListTile(
        onTap: onTap,
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(user.location),
        trailing: const Icon(Icons.arrow_forward, color: Colors.blue),
      ),
    );
  }
}

class UnscheduledPaymentCard extends StatelessWidget {
  final Payment payment;
  final User? user;
  final VoidCallback onUserTap;
  final VoidCallback onPaymentTap;

  const UnscheduledPaymentCard({
    required this.payment,
    required this.user,
    required this.onUserTap,
    required this.onPaymentTap,
    super.key,
  });

  String _formatDate(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onUserTap,
                    child: Text(
                      user?.name ?? 'مستخدم غير معروف',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    "كاش",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[700],
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
                  'التاريخ: ${_formatDate(payment.date)}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'المبلغ: ${payment.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPaymentTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'عرض التفاصيل',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UnscheduledProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const UnscheduledProductCard({
    required this.product,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'السعر: ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 15,
                ),
              ),
              child: const Text(
                'التفاصيل',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
