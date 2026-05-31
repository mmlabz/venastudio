import 'package:venastudio/common.dart';

class SalesAnalyticsPage extends ConsumerWidget {
  const SalesAnalyticsPage({super.key});

  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color success = Color(0xff13A76B);
  static const Color amber = Color(0xffF4A62A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(genericAnalyticsProvider('sales'));

    return Scaffold(
      backgroundColor: bg,
      appBar: _appBar(ref),
      body: RefreshIndicator(
        color: teal,
        onRefresh: () => ref.read(genericAnalyticsProvider('sales').notifier).load(),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator(color: teal)),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [Text('$e')],
          ),
          data: (data) {
            final revenueByDay = analyticsList(data['revenue_by_day']);
            final paymentMethods = analyticsList(data['revenue_by_payment_method']);
            final discounts = _num(data['total_discounts']);

            final totalRevenue = revenueByDay.fold<double>(
              0,
              (sum, row) => sum + _num(row['revenue'] ?? row['value']),
            );

            final orders = revenueByDay.fold<int>(
              0,
              (sum, row) => sum + _int(row['orders_count']),
            );

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
                      childAspectRatio: wide ? 2.2 : 3.5,
                      children: [
                        AnalyticsCard(
                          title: 'Revenue',
                          value: totalRevenue.money,
                          subtitle: 'Selected period',
                          icon: Icons.trending_up_rounded,
                          color: success,
                        ),
                        AnalyticsCard(
                          title: 'Orders',
                          value: '$orders',
                          subtitle: 'Total transactions',
                          icon: Icons.receipt_long_rounded,
                          color: teal,
                        ),
                        AnalyticsCard(
                          title: 'Discounts',
                          value: discounts.money,
                          subtitle: 'Discounts issued',
                          icon: Icons.local_offer_rounded,
                          color: amber,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                AnalyticsSection(
                  title: 'Revenue by Day',
                  subtitle: 'Daily sales for the selected period.',
                  child: revenueByDay.isEmpty
                      ? _empty('No revenue data found for this period.')
                      : Column(
                          children: revenueByDay.map((row) {
                            final label = '${row['label'] ?? ''}';
                            final revenue = _num(row['revenue'] ?? row['value']);
                            final count = _int(row['orders_count']);

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0x2243C5D8),
                                child: Icon(Icons.calendar_today_rounded, color: teal),
                              ),
                              title: Text(label, style: _titleStyle),
                              subtitle: Text('$count orders', style: _subStyle),
                              trailing: Text(revenue.money, style: _titleStyle),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),
                AnalyticsSection(
                  title: 'Payment Methods',
                  subtitle: 'Cash, M-PESA, Equity and other payment channels.',
                  child: paymentMethods.isEmpty
                      ? _empty('No payment method data found.')
                      : Column(
                          children: paymentMethods.map((row) {
                            final label = '${row['label'] ?? 'Unknown'}';
                            final revenue = _num(row['revenue']);
                            final tx = _int(row['transactions']);

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.payments_rounded, color: teal),
                              title: Text(label, style: _titleStyle),
                              subtitle: Text('$tx transactions', style: _subStyle),
                              trailing: Text(revenue.money, style: _titleStyle),
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

  AppBar _appBar(WidgetRef ref) {
    return AppBar(
      backgroundColor: bg,
      foregroundColor: dark,
      elevation: 0,
      title: const Text('Sales Analytics', style: TextStyle(fontWeight: FontWeight.w900)),
      actions: [
        IconButton(
          onPressed: () => ref.read(genericAnalyticsProvider('sales').notifier).load(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  static final _titleStyle = const TextStyle(color: dark, fontWeight: FontWeight.w900);
  static final _subStyle = const TextStyle(color: muted, fontWeight: FontWeight.w700);

  static Widget _empty(String text) => Text(text, style: _subStyle);

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
