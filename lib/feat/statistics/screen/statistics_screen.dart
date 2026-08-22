import 'package:flutter/material.dart';
import 'package:naji/feat/statistics/controller/statistics_controller.dart';
import 'package:provider/provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StatisticsController()..loadData(),
      child: const _StatisticsView(),
    );
  }
}

class _StatisticsView extends StatelessWidget {
  const _StatisticsView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StatisticsController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("الإحصائيات والتقارير"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.isLoading ? null : controller.loadData,
          ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    controller.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.loadData,
                    child: const Text("إعادة المحاولة"),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: controller.loadData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- Financial Summary Cards with Dual Currency Support ---
                  _DualStatCard(
                    title: "المبيعات اليومية",
                    values: controller.dailySales,
                    icon: Icons.today,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _DualStatCard(
                    title: "مبيعات الشهر",
                    values: controller.monthlySales,
                    icon: Icons.calendar_month,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _DualStatCard(
                    title: "مشتريات الشهر",
                    values: controller.monthlyPurchases,
                    icon: Icons.shopping_bag,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _DualStatCard(
                    title: "التدفق النقدي",
                    values: controller.cashFlow,
                    icon: Icons.account_balance_wallet,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 12),
                  _DualStatCard(
                    title: "إجمالي الديون المستحقة",
                    values: controller.outstandingDebt,
                    icon: Icons.money_off,
                    color: Colors.red.shade700,
                  ),

                  const SizedBox(height: 32),

                  // --- Top 5 Lists Section ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Products Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  "أفضل المنتجات",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTopList(
                              controller.topProductsList,
                              "لا توجد منتجات",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Top Customers Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.workspace_premium,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "أفضل العملاء",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTopList(
                              controller.topCustomersList,
                              "لا يوجد عملاء",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildTopList(List<String> items, String emptyMessage) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            emptyMessage,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey.shade200,
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  items[index],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Reusable card widget for dual currency metric display
class _DualStatCard extends StatelessWidget {
  final String title;
  final Map<String, double> values;
  final IconData icon;
  final Color color;

  const _DualStatCard({
    required this.title,
    required this.values,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final syVal = values['sy'] ?? 0.0;
    final dollarVal = values['dollar'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Syrian Pounds Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "الليرة السورية",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${syVal < 0 ? '-' : ''}${syVal.abs().toStringAsFixed(2)} ل.س",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: syVal < 0 ? Colors.red : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 20),
              // Dollar Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "الدولار الأمريكي",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${dollarVal < 0 ? '-' : ''}${dollarVal.abs().toStringAsFixed(2)} \$",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dollarVal < 0 ? Colors.red : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
