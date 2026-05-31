import 'package:venastudio/common.dart';

class BusinessHealthPage extends ConsumerWidget {
  const BusinessHealthPage({super.key});

  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = genericAnalyticsProvider('business_health');
    final state = ref.watch(provider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: dark,
        elevation: 0,
        title: const Text('Business Health Score', style: TextStyle(fontWeight: FontWeight.w900)),
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
          final score = _d(raw['score']);
          final status = '${raw['status'] ?? _status(score)}';
          final factors = raw['factors'] is Map ? Map<String, dynamic>.from(raw['factors']) : <String, dynamic>{};

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              BusinessHealthCard(score: score, status: status, factors: factors),
              const SizedBox(height: 14),
              AnalyticsSection(
                title: 'How the score is calculated',
                subtitle: 'A practical weighted operating health score.',
                child: const Text(
                  'Sales growth, retention, cash position, inventory health, workforce health and profitability are combined to show whether the business is strong, stable, warning or critical.',
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  static String _status(double score) {
    if (score >= 80) return 'Strong';
    if (score >= 65) return 'Stable';
    if (score >= 50) return 'Warning';
    return 'Critical';
  }
}
