import 'package:venastudio/common.dart';

class ExecutiveOverviewPage extends ConsumerWidget {
  const ExecutiveOverviewPage({super.key});

  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color success = Color(0xff13A76B);
  static const Color amber = Color(0xffF4A62A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsDashboardProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: dark,
        elevation: 0,
        title: const Text('Executive Overview', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () => ref.read(analyticsDashboardProvider.notifier).load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: teal,
        onRefresh: () => ref.read(analyticsDashboardProvider.notifier).load(),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator(color: teal)),
          error: (e, _) => ListView(padding: const EdgeInsets.all(16), children: [Text('$e')]),
          data: (summary) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const AnalyticsPeriodBar(),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 750;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: wide ? 4 : 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: wide ? 2.1 : 1.55,
                      children: [
                        AnalyticsCard(
                          title: 'Revenue',
                          value: summary.totalSales.money,
                          subtitle: 'Selected period',
                          icon: Icons.trending_up_rounded,
                          color: success,
                        ),
                        AnalyticsCard(
                          title: 'Orders',
                          value: '${summary.totalOrders}',
                          subtitle: 'Total transactions',
                          icon: Icons.receipt_long_rounded,
                          color: teal,
                        ),
                        AnalyticsCard(
                          title: 'Customers',
                          value: '${summary.totalCustomers}',
                          subtitle: 'Unique clients',
                          icon: Icons.people_alt_rounded,
                          color: amber,
                        ),
                        AnalyticsCard(
                          title: 'Average Order',
                          value: summary.averageOrderValue.money,
                          subtitle: 'Revenue per order',
                          icon: Icons.payments_rounded,
                          color: success,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                AnalyticsSection(
                  title: 'Daily Revenue',
                  subtitle: 'Revenue movement within the selected period.',
                  child: summary.dailySales.isEmpty
                      ? const Text('No daily revenue found.', style: TextStyle(color: muted, fontWeight: FontWeight.w700))
                      : Column(
                          children: summary.dailySales.map((row) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.calendar_today_rounded, color: teal),
                              title: Text('${row['label'] ?? ''}', style: _titleStyle),
                              trailing: Text(_num(row['value'] ?? row['revenue']).money, style: _titleStyle),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),
                AnalyticsSection(
                  title: 'Top Services',
                  subtitle: 'Best sellers in this period.',
                  child: summary.topServices.isEmpty
                      ? const Text('No top services found.', style: TextStyle(color: muted, fontWeight: FontWeight.w700))
                      : Column(
                          children: summary.topServices.map((row) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0x2243C5D8),
                                child: Icon(Icons.spa_rounded, color: teal),
                              ),
                              title: Text('${row['label'] ?? row['service_name'] ?? 'Service'}', style: _titleStyle),
                              subtitle: Text('${row['quantity'] ?? row['quantity_sold'] ?? 0} sold', style: _subStyle),
                              trailing: Text(_num(row['value'] ?? row['gross_sales']).money, style: _titleStyle),
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
