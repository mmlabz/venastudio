import 'package:venastudio/common.dart';

class CustomerReturnPredictorPage extends ConsumerWidget {
  const CustomerReturnPredictorPage({super.key});

  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color danger = Color(0xffD94B4B);
  static const Color success = Color(0xff13A76B);
  static const Color amber = Color(0xffF4A62A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerPredictorProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: dark,
        elevation: 0,
        title: const Text('Customer Return Predictor', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () => ref.read(customerPredictorProvider.notifier).load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: teal,
        onRefresh: () => ref.read(customerPredictorProvider.notifier).load(),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator(color: teal)),
          error: (e, _) => ListView(padding: const EdgeInsets.all(16), children: [Text('$e')]),
          data: (rows) {
            final highRisk = rows.where((e) => e.isAtRisk).length;
            final likely = rows.where((e) => !e.isAtRisk).length;

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
                          title: 'Customers Scored',
                          value: '${rows.length}',
                          subtitle: 'Predictor sample',
                          icon: Icons.psychology_alt_rounded,
                          color: teal,
                        ),
                        AnalyticsCard(
                          title: 'Likely to Return',
                          value: '$likely',
                          subtitle: 'Healthy customers',
                          icon: Icons.favorite_rounded,
                          color: success,
                        ),
                        AnalyticsCard(
                          title: 'Need Follow-up',
                          value: '$highRisk',
                          subtitle: 'At risk customers',
                          icon: Icons.warning_amber_rounded,
                          color: danger,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                AnalyticsSection(
                  title: 'Customer Follow-up List',
                  subtitle: 'Prioritize low score customers first.',
                  child: rows.isEmpty
                      ? const Text('No predictor data found.', style: TextStyle(color: muted, fontWeight: FontWeight.w700))
                      : Column(
                          children: rows.map((c) {
                            final color = c.returnProbability >= 70
                                ? success
                                : c.returnProbability >= 50
                                    ? amber
                                    : danger;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(.12),
                                child: Icon(Icons.person_search_rounded, color: color),
                              ),
                              title: Text(c.customerName, style: _titleStyle),
                              subtitle: Text(
                                '${c.phone} • ${c.status} • ${c.visits} visits • ${c.daysSinceLastVisit} days away',
                                style: _subStyle,
                              ),
                              trailing: Text(
                                '${c.returnProbability.toStringAsFixed(0)}%',
                                style: TextStyle(color: color, fontWeight: FontWeight.w900),
                              ),
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
}
