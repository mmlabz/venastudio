import 'package:venastudio/common.dart';

class WorkforceAnalyticsPage extends ConsumerWidget {
  const WorkforceAnalyticsPage({super.key});

  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color success = Color(0xff13A76B);
  static const Color amber = Color(0xffF4A62A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(genericAnalyticsProvider('workforce'));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: dark,
        elevation: 0,
        title: const Text('Workforce Analytics', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () => ref.read(genericAnalyticsProvider('workforce').notifier).load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: teal,
        onRefresh: () => ref.read(genericAnalyticsProvider('workforce').notifier).load(),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator(color: teal)),
          error: (e, _) => ListView(padding: const EdgeInsets.all(16), children: [Text('$e')]),
          data: (data) {
            final employees = analyticsList(data['employee_sales']);
            final commission = Map<String, dynamic>.from(data['commission_summary'] ?? {});
            final totalSales = employees.fold<double>(0, (s, e) => s + _num(e['gross_sales']));
            final services = employees.fold<int>(0, (s, e) => s + _int(e['services_done']));

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
                          title: 'Staff Revenue',
                          value: totalSales.money,
                          subtitle: 'Assigned sales',
                          icon: Icons.groups_rounded,
                          color: teal,
                        ),
                        AnalyticsCard(
                          title: 'Services Done',
                          value: '$services',
                          subtitle: 'Completed services',
                          icon: Icons.spa_rounded,
                          color: success,
                        ),
                        AnalyticsCard(
                          title: 'Commissions',
                          value: _num(commission['total_commission']).money,
                          subtitle: 'Total commission',
                          icon: Icons.payments_rounded,
                          color: amber,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                AnalyticsSection(
                  title: 'Employee Performance',
                  subtitle: 'Sales and services by beautician.',
                  child: employees.isEmpty
                      ? const Text('No employee data found.', style: TextStyle(color: muted, fontWeight: FontWeight.w700))
                      : Column(
                          children: employees.map((row) {
                            final name = '${row['employee_name'] ?? 'Unassigned'}';
                            final sales = _num(row['gross_sales']);
                            final done = _int(row['services_done']);
                            final comm = _num(row['total_commission']);

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0x2243C5D8),
                                child: Icon(Icons.person_rounded, color: teal),
                              ),
                              title: Text(name, style: _titleStyle),
                              subtitle: Text('$done services • commission ${comm.money}', style: _subStyle),
                              trailing: Text(sales.money, style: _titleStyle),
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

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
