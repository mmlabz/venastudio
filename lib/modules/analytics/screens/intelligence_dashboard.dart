import 'package:venastudio/common.dart';

class IntelligenceDashboardPage extends ConsumerWidget {
  const IntelligenceDashboardPage({super.key});

  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessProvider = genericAnalyticsProvider('business_health');
    final actionProvider = genericAnalyticsProvider('action_center');
    final forecastProvider = genericAnalyticsProvider('forecasting');

    final businessState = ref.watch(businessProvider);
    final actionState = ref.watch(actionProvider);
    final forecastState = ref.watch(forecastProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: dark,
        elevation: 0,
        title: const Text('Vena Intelligence', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(businessProvider.notifier).load();
              ref.read(actionProvider.notifier).load();
              ref.read(forecastProvider.notifier).load();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          businessState.when(
            loading: () => const LinearProgressIndicator(color: teal),
            error: (e, _) => Text('$e'),
            data: (data) => BusinessHealthBanner(
              health: BusinessHealth.fromMap(Map<String, dynamic>.from(data['data'] ?? data)),
            ),
          ),
          const SizedBox(height: 14),
          AnalyticsSection(
            title: 'Today’s Priorities',
            subtitle: 'Actions Vena thinks management should take first.',
            child: actionState.when(
              loading: () => const LinearProgressIndicator(color: teal),
              error: (e, _) => Text('$e'),
              data: (data) {
                final raw = Map<String, dynamic>.from(data['data'] ?? data);
                final actions = raw['actions'] is List
                    ? (raw['actions'] as List)
                        .whereType<Map>()
                        .map((e) => AiAction.fromMap(Map<String, dynamic>.from(e)))
                        .toList()
                    : <AiAction>[];

                if (actions.isEmpty) {
                  return const Text('No urgent actions right now.', style: TextStyle(color: muted, fontWeight: FontWeight.w700));
                }

                return Column(children: actions.map((a) => AiPriorityTile(action: a)).toList());
              },
            ),
          ),
          const SizedBox(height: 14),
          AnalyticsSection(
            title: 'Forecast Snapshot',
            subtitle: 'Expected future movement from current business data.',
            child: forecastState.when(
              loading: () => const LinearProgressIndicator(color: teal),
              error: (e, _) => Text('$e'),
              data: (data) {
                final raw = Map<String, dynamic>.from(data['data'] ?? data);
                final forecasts = raw['forecasts'] is List
                    ? (raw['forecasts'] as List)
                        .whereType<Map>()
                        .map((e) => Forecast.fromMap(Map<String, dynamic>.from(e)))
                        .take(4)
                        .toList()
                    : <Forecast>[];

                if (forecasts.isEmpty) {
                  return const Text('No forecasts yet.', style: TextStyle(color: muted, fontWeight: FontWeight.w700));
                }

                return Column(
                  children: forecasts.map((f) {
                    final money = f.title.toLowerCase().contains('sales') ||
                        f.title.toLowerCase().contains('cash') ||
                        f.title.toLowerCase().contains('revenue');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ForecastCard(forecast: f, money: money),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
