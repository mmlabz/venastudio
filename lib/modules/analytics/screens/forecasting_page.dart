import 'package:venastudio/common.dart';

class ForecastingPage extends ConsumerWidget {
  const ForecastingPage({super.key});

  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = genericAnalyticsProvider('forecasting');
    final state = ref.watch(provider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: dark,
        elevation: 0,
        title: const Text('Forecasting', style: TextStyle(fontWeight: FontWeight.w900)),
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
          final forecasts = raw['forecasts'] is List
              ? (raw['forecasts'] as List)
                  .whereType<Map>()
                  .map((e) => Forecast.fromMap(Map<String, dynamic>.from(e)))
                  .toList()
              : <Forecast>[];

          final risks = raw['risks'] is List
              ? (raw['risks'] as List)
                  .whereType<Map>()
                  .map((e) => RiskIndicator.fromMap(Map<String, dynamic>.from(e)))
                  .toList()
              : <RiskIndicator>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AnalyticsSection(
                title: 'Forecasts',
                subtitle: 'Expected sales, returns, churn, cashflow and stockouts.',
                child: forecasts.isEmpty
                    ? const Text('No forecasts yet.', style: TextStyle(color: muted, fontWeight: FontWeight.w700))
                    : Column(
                        children: forecasts.map((f) {
                          final money = f.title.toLowerCase().contains('sales') ||
                              f.title.toLowerCase().contains('cash') ||
                              f.title.toLowerCase().contains('revenue');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ForecastCard(forecast: f, money: money),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 14),
              AnalyticsSection(
                title: 'Risk Indicators',
                subtitle: 'Predicted operational risks.',
                child: risks.isEmpty
                    ? const Text('No risk indicators yet.', style: TextStyle(color: muted, fontWeight: FontWeight.w700))
                    : Column(children: risks.map((r) => RiskIndicatorCard(risk: r)).toList()),
              ),
            ],
          );
        },
      ),
    );
  }
}
