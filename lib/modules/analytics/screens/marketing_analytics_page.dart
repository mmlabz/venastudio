import 'package:venastudio/common.dart';

class MarketingAnalyticsPage extends ConsumerWidget {
  const MarketingAnalyticsPage({super.key});

  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color success = Color(0xff13A76B);
  static const Color danger = Color(0xffD94B4B);
  static const Color amber = Color(0xffF4A62A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = genericAnalyticsProvider('marketing');
    final state = ref.watch(provider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: dark,
        elevation: 0,
        title: const Text('Marketing Analytics', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () => ref.read(provider.notifier).load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator(color: teal)),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final raw = Map<String, dynamic>.from(data['data'] ?? data);
          final acquired = _i(raw['customers_acquired']);
          final revenue = _d(raw['campaign_revenue']);
          final discount = _d(raw['discount_cost']);
          final conversion = _d(raw['conversion_rate']);

          final campaigns = raw['campaigns'] is List
              ? (raw['campaigns'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
              : <Map<String, dynamic>>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final cross = constraints.maxWidth >= 900 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: cross,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.1,
                    children: [
                      AnalyticsCard(title: 'Acquired', value: '$acquired', icon: Icons.person_add_alt_rounded, color: teal),
                      AnalyticsCard(title: 'Revenue', value: revenue.money, icon: Icons.trending_up_rounded, color: success),
                      AnalyticsCard(title: 'Discount Cost', value: discount.money, icon: Icons.discount_rounded, color: danger),
                      AnalyticsCard(title: 'Conversion', value: '${conversion.toStringAsFixed(1)}%', icon: Icons.campaign_rounded, color: amber),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              AnalyticsSection(
                title: 'Campaign Performance',
                subtitle: 'Revenue and acquisition by campaign/source.',
                child: campaigns.isEmpty
                    ? const Text('No marketing analytics yet.', style: TextStyle(color: muted, fontWeight: FontWeight.w700))
                    : Column(
                        children: campaigns.map((r) {
                          return CampaignCard(
                            name: '${r['campaign_name'] ?? r['platform'] ?? r['source'] ?? 'Campaign'}',
                            revenue: _d(r['revenue']),
                            customers: _i(r['customers']),
                            discount: _d(r['discount']),
                            conversionRate: _d(r['conversion_rate']),
                          );
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  static double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  static int _i(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
}
