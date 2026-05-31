import 'package:venastudio/common.dart';

class FinanceAnalyticsPage extends ConsumerWidget {
  const FinanceAnalyticsPage({super.key});

  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color success = Color(0xff13A76B);
  static const Color amber = Color(0xffF4A62A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(genericAnalyticsProvider('finance'));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: dark,
        elevation: 0,
        title: const Text('Finance Analytics', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () => ref.read(genericAnalyticsProvider('finance').notifier).load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: teal,
        onRefresh: () => ref.read(genericAnalyticsProvider('finance').notifier).load(),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator(color: teal)),
          error: (e, _) => ListView(padding: const EdgeInsets.all(16), children: [Text('$e')]),
          data: (data) {
            final paymentMethods = analyticsList(data['revenue_by_payment_method']);
            final revenueByDay = analyticsList(data['revenue_by_day']);
            final totalRevenue = revenueByDay.fold<double>(0, (s, e) => s + _num(e['revenue'] ?? e['value']));
            final discounts = _num(data['total_discounts']);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const AnalyticsPeriodBar(),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 700;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: wide ? 3 : 1,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: wide ? 2.2 : 3.4,
                      children: [
                        AnalyticsCard(
                          title: 'Gross Revenue',
                          value: totalRevenue.money,
                          subtitle: 'Selected period',
                          icon: Icons.account_balance_wallet_rounded,
                          color: success,
                        ),
                        AnalyticsCard(
                          title: 'Discounts',
                          value: discounts.money,
                          subtitle: 'Revenue given away',
                          icon: Icons.local_offer_rounded,
                          color: amber,
                        ),
                        AnalyticsCard(
                          title: 'Net Estimate',
                          value: (totalRevenue - discounts).money,
                          subtitle: 'Revenue minus discounts',
                          icon: Icons.savings_rounded,
                          color: teal,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                AnalyticsSection(
                  title: 'Payment Channel Breakdown',
                  subtitle: 'Shows where money came from.',
                  child: paymentMethods.isEmpty
                      ? const Text('No payment channel data found.', style: TextStyle(color: muted, fontWeight: FontWeight.w700))
                      : Column(
                          children: paymentMethods.map((row) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.payments_rounded, color: teal),
                              title: Text('${row['label'] ?? 'Unknown'}', style: _titleStyle),
                              subtitle: Text('${row['transactions'] ?? 0} transactions', style: _subStyle),
                              trailing: Text(_num(row['revenue']).money, style: _titleStyle),
                            );
                          }).toList(),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static final _titleStyle = const TextStyle(color: dark, fontWeight: FontWeight.w900);
  static final _subStyle = const TextStyle(color: muted, fontWeight: FontWeight.w700);

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
