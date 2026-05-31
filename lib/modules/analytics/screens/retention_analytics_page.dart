import 'package:venastudio/common.dart';

class RetentionAnalyticsPage extends ConsumerWidget {
  const RetentionAnalyticsPage({super.key});

  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color danger = Color(0xffD94B4B);
  static const Color success = Color(0xff13A76B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerState = ref.watch(genericAnalyticsProvider('retention'));
    final predictorState = ref.watch(customerPredictorProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: dark,
        elevation: 0,
        title: const Text('Retention Analytics', style: TextStyle(fontWeight: FontWeight.w900)),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AnalyticsPeriodBar(onChanged: () => _reload(ref)),
            const SizedBox(height: 16),
            customerState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: teal)),
              error: (e, _) => Text('$e'),
              data: (data) {
                final total = _num(data['total_customers']);
                final returning = _num(data['returning_customers']);
                final rate = _num(data['retention_rate']);

                return AnalyticsSection(
                  title: 'Retention Score',
                  subtitle: 'Repeat customer strength for the selected period.',
                  child: Column(
                    children: [
                      RetentionGauge(value: rate),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth > 650;
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: wide ? 3 : 1,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: wide ? 3 : 3.6,
                            children: [
                              AnalyticsCard(
                                title: 'Total Customers',
                                value: total.toStringAsFixed(0),
                                subtitle: 'In selected period',
                                icon: Icons.people_rounded,
                                color: teal,
                              ),
                              AnalyticsCard(
                                title: 'Returning',
                                value: returning.toStringAsFixed(0),
                                subtitle: 'Came more than once',
                                icon: Icons.favorite_rounded,
                                color: success,
                              ),
                              AnalyticsCard(
                                title: 'Retention',
                                value: '${rate.toStringAsFixed(1)}%',
                                subtitle: 'Returning / total',
                                icon: Icons.repeat_rounded,
                                color: rate >= 50 ? success : danger,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            AnalyticsSection(
              title: 'Customers Needing Follow-up',
              subtitle: 'From the return predictor. Includes last visit and days away.',
              child: predictorState.when(
                loading: () => const LinearProgressIndicator(color: teal),
                error: (e, _) => Text('$e'),
                data: (rows) {
                  final risky = rows.where((e) => e.isAtRisk).toList();

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
                          child: const Icon(Icons.warning_rounded, color: danger),
                        ),
                        title: Text(c.customerName, style: _titleStyle),
                        subtitle: Text(
                          '${c.phone} • ${c.status} • Last: ${c.lastVisit.isEmpty ? 'N/A' : c.lastVisit} • ${c.daysSinceLastVisit} days away',
                          style: _subStyle,
                        ),
                        trailing: Text(
                          '${c.returnProbability.toStringAsFixed(0)}%',
                          style: const TextStyle(color: danger, fontWeight: FontWeight.w900),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reload(WidgetRef ref) async {
    await ref.read(genericAnalyticsProvider('retention').notifier).load();
    await ref.read(customerPredictorProvider.notifier).load();
  }

  static final _titleStyle = const TextStyle(color: dark, fontWeight: FontWeight.w900);
  static final _subStyle = const TextStyle(color: muted, fontWeight: FontWeight.w700);

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
