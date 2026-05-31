import 'package:venastudio/common.dart';

class CustomerAnalyticsPage extends ConsumerWidget {
  const CustomerAnalyticsPage({super.key});

  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color success = Color(0xff13A76B);
  static const Color amber = Color(0xffF4A62A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(genericAnalyticsProvider('customers'));

    return Scaffold(
      backgroundColor: bg,
      appBar: _appBar(ref),
      body: RefreshIndicator(
        color: teal,
        onRefresh: () => ref.read(genericAnalyticsProvider('customers').notifier).load(),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator(color: teal)),
          error: (e, _) => ListView(padding: const EdgeInsets.all(16), children: [Text('$e')]),
          data: (data) {
            final topCustomers = analyticsList(data['top_customers']);
            final visitFrequency = analyticsList(data['visit_frequency']);

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
                      crossAxisCount: wide ? 4 : 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: wide ? 2.1 : 1.55,
                      children: [
                        AnalyticsCard(
                          title: 'Total Customers',
                          value: '${data['total_customers'] ?? 0}',
                          subtitle: 'Unique customers',
                          icon: Icons.people_rounded,
                          color: teal,
                        ),
                        AnalyticsCard(
                          title: 'New Customers',
                          value: '${data['new_customers'] ?? 0}',
                          subtitle: 'First-time clients',
                          icon: Icons.person_add_alt_rounded,
                          color: success,
                        ),
                        AnalyticsCard(
                          title: 'Returning',
                          value: '${data['returning_customers'] ?? 0}',
                          subtitle: 'Repeat clients',
                          icon: Icons.favorite_rounded,
                          color: success,
                        ),
                        AnalyticsCard(
                          title: 'Retention',
                          value: '${_num(data['retention_rate']).toStringAsFixed(1)}%',
                          subtitle: 'Return rate',
                          icon: Icons.insights_rounded,
                          color: amber,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                AnalyticsSection(
                  title: 'Top Customers',
                  subtitle: 'Customers ranked by total spend in this period.',
                  child: topCustomers.isEmpty
                      ? _empty('No customer data found for this period.')
                      : Column(
                          children: topCustomers.map((row) {
                            final name = '${row['name'] ?? 'Customer'}';
                            final phone = '${row['phone'] ?? ''}';
                            final visits = '${row['visits'] ?? 0}';
                            final spent = _num(row['total_spent']);

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0x2243C5D8),
                                child: Icon(Icons.person_rounded, color: teal),
                              ),
                              title: Text(name, style: _titleStyle),
                              subtitle: Text('$phone • $visits visits', style: _subStyle),
                              trailing: Text(spent.money, style: _titleStyle),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),
                AnalyticsSection(
                  title: 'Visit Frequency',
                  subtitle: 'How many times customers came back.',
                  child: visitFrequency.isEmpty
                      ? _empty('No visit frequency data found.')
                      : Column(
                          children: visitFrequency.map((row) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.repeat_rounded, color: teal),
                              title: Text('${row['label']} visits', style: _titleStyle),
                              trailing: Text('${row['customers']} customers', style: _titleStyle),
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
      title: const Text('Customer Analytics', style: TextStyle(fontWeight: FontWeight.w900)),
      actions: [
        IconButton(
          onPressed: () => ref.read(genericAnalyticsProvider('customers').notifier).load(),
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
}
