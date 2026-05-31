import 'package:venastudio/common.dart';

class ProfitabilityAnalyticsPage extends ConsumerWidget {
  const ProfitabilityAnalyticsPage({super.key});

  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color success = Color(0xff13A76B);
  static const Color amber = Color(0xffF4A62A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(genericAnalyticsProvider('profitability'));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: dark,
        elevation: 0,
        title: const Text('Profitability', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () => ref.read(genericAnalyticsProvider('profitability').notifier).load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: teal,
        onRefresh: () => ref.read(genericAnalyticsProvider('profitability').notifier).load(),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator(color: teal)),
          error: (e, _) => ListView(padding: const EdgeInsets.all(16), children: [Text('$e')]),
          data: (data) {
            final topServices = analyticsList(data['top_services']);
            final categories = analyticsList(data['category_performance']);
            final slow = analyticsList(data['slow_services']);

            final revenue = topServices.fold<double>(0, (s, e) => s + _num(e['gross_sales'] ?? e['net_sales'] ?? e['value']));

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const AnalyticsPeriodBar(),
                const SizedBox(height: 16),
                AnalyticsCard(
                  title: 'Service Revenue',
                  value: revenue.money,
                  subtitle: 'From service performance endpoint',
                  icon: Icons.sell_rounded,
                  color: success,
                ),
                const SizedBox(height: 16),
                AnalyticsSection(
                  title: 'Best Performing Services',
                  subtitle: 'Use this to promote what already sells.',
                  child: topServices.isEmpty
                      ? const Text('No service performance data found.', style: TextStyle(color: muted, fontWeight: FontWeight.w700))
                      : Column(
                          children: topServices.map((row) {
                            final name = '${row['service_name'] ?? row['label'] ?? 'Service'}';
                            final qty = '${row['quantity_sold'] ?? row['quantity'] ?? 0}';
                            final sales = _num(row['gross_sales'] ?? row['net_sales'] ?? row['value']);

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0x2243C5D8),
                                child: Icon(Icons.spa_rounded, color: teal),
                              ),
                              title: Text(name, style: _titleStyle),
                              subtitle: Text('$qty sold', style: _subStyle),
                              trailing: Text(sales.money, style: _titleStyle),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),
                AnalyticsSection(
                  title: 'Category Performance',
                  subtitle: 'Revenue grouped by service category.',
                  child: categories.isEmpty
                      ? const Text('No category data found.', style: TextStyle(color: muted, fontWeight: FontWeight.w700))
                      : Column(
                          children: categories.map((row) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.category_rounded, color: teal),
                              title: Text('${row['category_name'] ?? 'Uncategorized'}', style: _titleStyle),
                              trailing: Text(_num(row['revenue']).money, style: _titleStyle),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),
                AnalyticsSection(
                  title: 'Slow Services',
                  subtitle: 'Services that may need pricing, bundling, or marketing review.',
                  child: slow.isEmpty
                      ? const Text('No slow service data found.', style: TextStyle(color: muted, fontWeight: FontWeight.w700))
                      : Column(
                          children: slow.map((row) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.trending_down_rounded, color: amber),
                              title: Text('${row['service_name'] ?? 'Service'}', style: _titleStyle),
                              subtitle: Text('${row['quantity_sold'] ?? 0} sold', style: _subStyle),
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
