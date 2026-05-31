import 'package:venastudio/common.dart';

class AnalyticsDashboardPage extends ConsumerWidget {
  const AnalyticsDashboardPage({super.key});

  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color danger = Color(0xffD94B4B);
  static const Color success = Color(0xff13A76B);
  static const Color amber = Color(0xffF4A62A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsDashboardProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: bg,
        foregroundColor: dark,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () => _reload(ref),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: teal,
        onRefresh: () => _reload(ref),
        child: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: teal),
          ),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _errorBox('$e'),
              const SizedBox(height: 14),
              AnalyticsPeriodBar(onChanged: () => _reload(ref)),
            ],
          ),
          data: (summary) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                AnalyticsPeriodBar(onChanged: () => _reload(ref)),
                const SizedBox(height: 16),
                _hero(summary, ref),
                const SizedBox(height: 16),
                _summaryGrid(context, summary),
                const SizedBox(height: 16),
                _topServices(summary),
                const SizedBox(height: 16),
                _predictorPreview(context, ref),
                const SizedBox(height: 16),
                _moduleGrid(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _reload(WidgetRef ref) async {
    await ref.read(analyticsDashboardProvider.notifier).load();
    await ref.read(customerPredictorProvider.notifier).load();
  }

  Widget _hero(AnalyticsSummary summary, WidgetRef ref) {
    final filters = ref.watch(analyticsFiltersProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [teal, Color(0xff2AA8C4)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: teal.withOpacity(.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0x33FFFFFF),
            child: Icon(Icons.auto_graph_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vena Intelligence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${filters.label} • ${filters.displayRange}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Revenue ${summary.totalSales.money} • ${summary.totalOrders} orders',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid(BuildContext context, AnalyticsSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1100
            ? 4
            : width >= 760
                ? 3
                : width >= 480
                    ? 2
                    : 1;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: width < 480 ? 3.3 : 2.2,
          children: [
            AnalyticsCard(
              title: 'Revenue',
              value: summary.totalSales.money,
              subtitle: 'Selected period',
              icon: Icons.trending_up_rounded,
              color: success,
              onTap: () => _open(context, const SalesAnalyticsPage()),
            ),
            AnalyticsCard(
              title: 'Orders',
              value: '${summary.totalOrders}',
              subtitle: 'Transactions',
              icon: Icons.receipt_long_rounded,
              color: teal,
            ),
            AnalyticsCard(
              title: 'Customers',
              value: '${summary.totalCustomers}',
              subtitle: 'Unique clients',
              icon: Icons.people_alt_rounded,
              color: amber,
              onTap: () => _open(context, const CustomerAnalyticsPage()),
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
    );
  }

  Widget _topServices(AnalyticsSummary summary) {
    final rows = summary.topServices.take(6).toList();

    return AnalyticsSection(
      title: 'Top Services',
      subtitle: 'Best performing services for the selected period.',
      child: rows.isEmpty
          ? const Text(
              'No service data found for this period.',
              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
            )
          : Column(
              children: rows.map((row) {
                final label = '${row['label'] ?? row['service_name'] ?? 'Service'}';
                final value = _toDouble(row['value'] ?? row['gross_sales']);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x2243C5D8),
                    child: Icon(Icons.spa_rounded, color: teal),
                  ),
                  title: Text(
                    label,
                    style: const TextStyle(
                      color: dark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  trailing: Text(
                    value.money,
                    style: const TextStyle(
                      color: dark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _predictorPreview(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerPredictorProvider);

    return AnalyticsSection(
      title: 'Customer Return Predictor',
      subtitle: 'Customers who need follow-up in this period.',
      trailing: TextButton.icon(
        onPressed: () => _open(context, const CustomerReturnPredictorPage()),
        icon: const Icon(Icons.psychology_rounded, color: teal),
        label: const Text(
          'Open',
          style: TextStyle(color: teal, fontWeight: FontWeight.w900),
        ),
      ),
      child: state.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(14),
          child: LinearProgressIndicator(color: teal),
        ),
        error: (e, _) => const Text(
          'Predictor data is temporarily unavailable.',
          style: TextStyle(color: muted, fontWeight: FontWeight.w700),
        ),
        data: (rows) {
          final risky = rows.where((e) => e.isAtRisk).take(4).toList();

          if (risky.isEmpty) {
            return const Text(
              'No high-risk customers found for this period.',
              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
            );
          }

          return Column(
            children: risky.map((c) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: danger.withOpacity(.12),
                  child: const Icon(Icons.person_search_rounded, color: danger),
                ),
                title: Text(
                  c.customerName,
                  style: const TextStyle(
                    color: dark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  '${c.phone} • ${c.status} • ${c.daysSinceLastVisit} days away',
                  style: const TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: Text(
                  '${c.returnProbability.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: danger,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _moduleGrid(BuildContext context) {
    final modules = [
      (
        Icons.insights_rounded,
        'Executive Overview',
        'Business command center',
        const ExecutiveOverviewPage()
      ),
      (
        Icons.point_of_sale_rounded,
        'Sales Analytics',
        'Revenue, payment methods, trends',
        const SalesAnalyticsPage()
      ),
      (
        Icons.people_rounded,
        'Customer Analytics',
        'Spend, loyalty, behavior',
        const CustomerAnalyticsPage()
      ),
      (
        Icons.favorite_rounded,
        'Retention Analytics',
        'Repeat visits and churn',
        const RetentionAnalyticsPage()
      ),
      (
        Icons.groups_rounded,
        'Workforce Analytics',
        'Staff sales and commissions',
        const WorkforceAnalyticsPage()
      ),
      (
        Icons.inventory_rounded,
        'Inventory Analytics',
        'Stock, low items, movement',
        const InventoryAnalyticsPage()
      ),
      (
        Icons.account_balance_wallet_rounded,
        'Finance Analytics',
        'Cashflow and payment channels',
        const FinanceAnalyticsPage()
      ),
      (
        Icons.sell_rounded,
        'Profitability',
        'Margins and service performance',
        const ProfitabilityAnalyticsPage()
      ),
      (
        Icons.psychology_alt_rounded,
        'Return Predictor',
        'Customers needing follow-up',
        const CustomerReturnPredictorPage()
      ),
    ];

    return AnalyticsSection(
      title: 'Analytics Modules',
      subtitle: 'Open detailed intelligence areas.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 750;

          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isWide ? 2 : 1,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: isWide ? 4.8 : 4,
            children: modules.map((m) {
              return Material(
                color: const Color(0xffFAFEFF),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () => _open(context, m.$4),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xffCFEFF4)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: teal.withOpacity(.12),
                          child: Icon(m.$1, color: teal),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.$2,
                                style: const TextStyle(
                                  color: dark,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                m.$3,
                                style: const TextStyle(
                                  color: muted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: muted),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  static Widget _errorBox(String message) {
    return AnalyticsSection(
      title: 'Analytics Error',
      subtitle: 'The server returned an error.',
      child: Text(message),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
