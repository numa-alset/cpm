import 'package:flutter/material.dart';
import 'package:naji/core/services/statistics_service.dart';
import 'package:naji/feat/statistics/controller/statistics_controller.dart';
import 'package:provider/provider.dart';

class StatisticScreen extends StatelessWidget {
  const StatisticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StatisticController()..loadData(),
      child: const _StatisticView(),
    );
  }
}

class _StatisticView extends StatelessWidget {
  const _StatisticView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإحصائيات'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: context.read<StatisticController>().loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: const _StatisticBody(),
    );
  }
}

class _StatisticBody extends StatelessWidget {
  const _StatisticBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticController>(
      builder: (context, controller, _) {
        if (controller.isLoading && !controller.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error != null && !controller.hasData) {
          return _ErrorState(
            message: controller.error!,
            onRetry: controller.loadData,
          );
        }

        final data = controller.data;

        if (data == null) {
          return _ErrorState(
            message: 'لا توجد بيانات.',
            onRetry: controller.loadData,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _PeriodSelector(controller: controller),

              const SizedBox(height: 16),

              _OverviewCard(summary: data.summary),

              const SizedBox(height: 16),

              _TodayCard(today: data.today),

              const SizedBox(height: 16),

              _BalanceCard(balance: data.summary.balance),

              const SizedBox(height: 16),

              _MonthlyCard(monthly: data.monthly),

              const SizedBox(height: 16),

              _UserBalancesCard(balances: data.userBalances),

              const SizedBox(height: 16),

              _RecentInvoicesCard(invoices: data.recentInvoices),

              const SizedBox(height: 16),

              _RecentPaymentsCard(payments: data.recentPayments),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// PERIOD
// ============================================================

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.controller});

  final StatisticController controller;

  @override
  Widget build(BuildContext context) {
    final periods = [
      (StatisticPeriod.today, 'اليوم'),
      (StatisticPeriod.thisMonth, 'هذا الشهر'),
      (StatisticPeriod.lastMonth, 'الشهر الماضي'),
      (StatisticPeriod.thisYear, 'هذه السنة'),
      (StatisticPeriod.all, 'الكل'),
      (StatisticPeriod.custom, 'مخصص'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final period in periods)
              ChoiceChip(
                label: Text(period.$2),
                selected: controller.period == period.$1,
                onSelected: (_) async {
                  if (period.$1 == StatisticPeriod.custom) {
                    await controller.selectCustomRange(context);
                    return;
                  }

                  await controller.setPeriod(period.$1);
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// OVERVIEW
// ============================================================

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.summary});

  final StatisticSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نظرة عامة', style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _StatisticTile(
                    icon: Icons.people_outline,
                    label: 'المستخدمون',
                    value: '${summary.userCount}',
                  ),
                ),
                Expanded(
                  child: _StatisticTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'الفواتير',
                    value: '${summary.invoiceCount}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _StatisticTile(
                    icon: Icons.payments_outlined,
                    label: 'الدفعات',
                    value: '${summary.paymentCount}',
                  ),
                ),
                Expanded(
                  child: _StatisticTile(
                    icon: Icons.inventory_2_outlined,
                    label: 'المنتجات',
                    value: '${summary.productCount}',
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

class _StatisticTile extends StatelessWidget {
  const _StatisticTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(end: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon),

          const SizedBox(height: 8),

          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TODAY
// ============================================================

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.today});

  final StatisticDailySummary today;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اليوم', style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 16),

            _InfoRow(
              icon: Icons.receipt_long_outlined,
              label: 'الفواتير',
              value: '${today.invoiceCount}',
            ),

            _MoneyRow(
              icon: Icons.add_business_outlined,
              label: 'إجمالي الفواتير',
              amount: today.invoiceTotal,
            ),

            const Divider(height: 24),

            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'الدفعات',
              value: '${today.paymentCount}',
            ),

            _MoneyRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'إجمالي الدفعات',
              amount: today.paymentTotal,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BALANCE
// ============================================================

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final StatisticCurrencyAmount balance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الرصيد المستحق',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 6),

            Text(
              'الفواتير ناقص الدفعات',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 18),

            if (balance.sy != 0)
              _BalanceAmount(amount: balance.sy, currency: 'ل.س'),

            if (balance.dollar != 0)
              _BalanceAmount(amount: balance.dollar, currency: '\$'),

            if (balance.sy == 0 && balance.dollar == 0)
              const Text('لا يوجد رصيد مستحق'),
          ],
        ),
      ),
    );
  }
}

class _BalanceAmount extends StatelessWidget {
  const _BalanceAmount({required this.amount, required this.currency});

  final double amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(amount > 0 ? Icons.trending_up : Icons.trending_down),

          const SizedBox(width: 10),

          Text(
            _formatNumber(amount),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(width: 6),

          Text(currency),
        ],
      ),
    );
  }
}

// ============================================================
// MONTHLY
// ============================================================

class _MonthlyCard extends StatelessWidget {
  const _MonthlyCard({required this.monthly});

  final List<StatisticMonthlySummary> monthly;

  @override
  Widget build(BuildContext context) {
    if (monthly.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('لا توجد بيانات شهرية.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'النشاط الشهري',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 16),

            for (final month in monthly.reversed) _MonthlyRow(month: month),
          ],
        ),
      ),
    );
  }
}

class _MonthlyRow extends StatelessWidget {
  const _MonthlyRow({required this.month});

  final StatisticMonthlySummary month;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${month.month}/${month.year}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

              Text('${month.invoiceCount} فواتير'),

              const SizedBox(width: 12),

              Text('${month.paymentCount} دفعات'),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _CompactMoney(
                  label: 'فواتير',
                  amount: month.invoiceTotal,
                ),
              ),

              Expanded(
                child: _CompactMoney(
                  label: 'دفعات',
                  amount: month.paymentTotal,
                ),
              ),
            ],
          ),

          const Divider(height: 20),
        ],
      ),
    );
  }
}

class _CompactMoney extends StatelessWidget {
  const _CompactMoney({required this.label, required this.amount});

  final String label;
  final StatisticCurrencyAmount amount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),

        const SizedBox(height: 4),

        if (amount.sy != 0)
          Text(
            '${_formatNumber(amount.sy)} ل.س',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

        if (amount.dollar != 0)
          Text(
            '${_formatNumber(amount.dollar)} \$',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

        if (amount.sy == 0 && amount.dollar == 0)
          Text(
            '0',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

// ============================================================
// USER BALANCES
// ============================================================

class _UserBalancesCard extends StatelessWidget {
  const _UserBalancesCard({required this.balances});

  final List<StatisticUserBalance> balances;

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = balances
        .where((user) => user.balanceSy != 0 || user.balanceDollar != 0)
        .toList();

    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أرصدة المستخدمين',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 12),

            for (final user in visible) _UserBalanceRow(user: user),
          ],
        ),
      ),
    );
  }
}

class _UserBalanceRow extends StatelessWidget {
  const _UserBalanceRow({required this.user});

  final StatisticUserBalance user;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(user.name),
      subtitle: user.location.isEmpty ? null : Text(user.location),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (user.balanceSy != 0) Text('${_formatNumber(user.balanceSy)} ل.س'),

          if (user.balanceDollar != 0)
            Text('${_formatNumber(user.balanceDollar)} \$'),
        ],
      ),
    );
  }
}

// ============================================================
// RECENT INVOICES
// ============================================================

class _RecentInvoicesCard extends StatelessWidget {
  const _RecentInvoicesCard({required this.invoices});

  final List<StatisticRecentInvoice> invoices;

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('آخر الفواتير', style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 12),

            for (final invoice in invoices) _RecentInvoiceRow(invoice: invoice),
          ],
        ),
      ),
    );
  }
}

class _RecentInvoiceRow extends StatelessWidget {
  const _RecentInvoiceRow({required this.invoice});

  final StatisticRecentInvoice invoice;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
      title: Text(
        invoice.userName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_formatDate(invoice.date)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (invoice.totalSy != 0)
            Text('${_formatNumber(invoice.totalSy)} ل.س'),

          if (invoice.totalDollar != 0)
            Text('${_formatNumber(invoice.totalDollar)} \$'),
        ],
      ),
    );
  }
}

// ============================================================
// RECENT PAYMENTS
// ============================================================

class _RecentPaymentsCard extends StatelessWidget {
  const _RecentPaymentsCard({required this.payments});

  final List<StatisticRecentPayment> payments;

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('آخر الدفعات', style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 12),

            for (final payment in payments) _RecentPaymentRow(payment: payment),
          ],
        ),
      ),
    );
  }
}

class _RecentPaymentRow extends StatelessWidget {
  const _RecentPaymentRow({required this.payment});

  final StatisticRecentPayment payment;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
      title: Text(
        payment.userName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_formatDate(payment.date)),
      trailing: Text(
        '${_formatNumber(payment.amount)} '
        '${_currencyLabel(payment.currency)}',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ============================================================
// INFO
// ============================================================

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 20),

          const SizedBox(width: 10),

          Expanded(child: Text(label)),

          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.icon,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final String label;
  final StatisticCurrencyAmount amount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 4),
              Text(label, style: textTheme.bodyMedium),
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //
              // const SizedBox(height: 4),
              if (amount.sy != 0)
                Text(
                  '${_formatNumber(amount.sy)} ل.س',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

              if (amount.dollar != 0)
                Text(
                  '${_formatNumber(amount.dollar)} \$',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

              if (amount.sy == 0 && amount.dollar == 0)
                Text(
                  '0',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),

            const SizedBox(height: 12),

            Text(message, textAlign: TextAlign.center),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FORMATTERS
// ============================================================

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2);
}

String _formatDate(int timestamp) {
  final milliseconds = timestamp < 100000000000 ? timestamp * 1000 : timestamp;

  final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);

  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String _currencyLabel(String value) {
  switch (value.toLowerCase()) {
    case 'sy':
    case 'syp':
      return 'ل.س';

    case 'dollar':
    case 'usd':
    case r'$':
      return '\$';

    default:
      return value;
  }
}
