import 'package:venastudio/common.dart';

class ActionCenterPage extends ConsumerWidget {
  const ActionCenterPage({super.key});

  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = genericAnalyticsProvider('action_center');
    final state = ref.watch(provider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: dark,
        elevation: 0,
        title: const Text('AI Action Center', style: TextStyle(fontWeight: FontWeight.w900)),
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
          final actions = raw['actions'] is List
              ? (raw['actions'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
              : <Map<String, dynamic>>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AnalyticsSection(
                title: 'Today’s Priorities',
                subtitle: 'Recommended actions generated from sales, customers, stock, workforce and finance data.',
                child: actions.isEmpty
                    ? const Text('No urgent actions right now.', style: TextStyle(color: muted, fontWeight: FontWeight.w700))
                    : Column(
                        children: actions.map((r) {
                          return ActionCenterCard(
                            title: '${r['title'] ?? 'Action'}',
                            message: '${r['message'] ?? ''}',
                            priority: '${r['priority'] ?? 'Medium'}',
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
}
