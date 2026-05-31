import 'package:venastudio/common.dart';

class InventoryAnalyticsPage extends ConsumerWidget {
  const InventoryAnalyticsPage({super.key});

  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color danger = Color(0xffD94B4B);
  static const Color amber = Color(0xffF4A62A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(genericAnalyticsProvider('inventory'));

    return Scaffold(
      backgroundColor: bg,
      appBar: _appBar(ref),
      body: RefreshIndicator(
        color: teal,
        onRefresh: () => ref.read(genericAnalyticsProvider('inventory').notifier).load(),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator(color: teal)),
          error: (e, _) => ListView(padding: const EdgeInsets.all(16), children: [Text('$e')]),
          data: (data) {
            final summary = Map<String, dynamic>.from(data['summary'] ?? {});
            final lowStock = analyticsList(data['low_stock']);
            final categoryStock = analyticsList(data['category_stock']);
            final movements = analyticsList(data['stock_movements']);

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
                          title: 'Total Items',
                          value: '${summary['total_items'] ?? 0}',
                          subtitle: 'Inventory items',
                          icon: Icons.inventory_2_rounded,
                          color: teal,
                        ),
                        AnalyticsCard(
                          title: 'Total Quantity',
                          value: '${summary['total_quantity'] ?? 0}',
                          subtitle: 'Units in stock',
                          icon: Icons.warehouse_rounded,
                          color: teal,
                        ),
                        AnalyticsCard(
                          title: 'Low Stock',
                          value: '${summary['low_stock_items'] ?? 0}',
                          subtitle: 'Needs restock',
                          icon: Icons.warning_rounded,
                          color: amber,
                        ),
                        AnalyticsCard(
                          title: 'Out of Stock',
                          value: '${summary['out_of_stock_items'] ?? 0}',
                          subtitle: 'Unavailable items',
                          icon: Icons.error_rounded,
                          color: danger,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                AnalyticsSection(
                  title: 'Low Stock Items',
                  subtitle: 'Products that need attention.',
                  child: lowStock.isEmpty
                      ? _empty('No low stock items found.')
                      : Column(
                          children: lowStock.map((row) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0x22F4A62A),
                                child: Icon(Icons.warning_rounded, color: amber),
                              ),
                              title: Text('${row['name'] ?? 'Item'}', style: _titleStyle),
                              subtitle: Text(
                                '${row['category_name'] ?? 'Uncategorized'} • Reorder: ${row['reorder_level'] ?? 0}',
                                style: _subStyle,
                              ),
                              trailing: Text('${row['quantity'] ?? 0}', style: const TextStyle(color: danger, fontWeight: FontWeight.w900)),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),
                AnalyticsSection(
                  title: 'Category Stock',
                  subtitle: 'Stock grouped by category.',
                  child: categoryStock.isEmpty
                      ? _empty('No category stock data found.')
                      : Column(
                          children: categoryStock.map((row) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.category_rounded, color: teal),
                              title: Text('${row['category_name'] ?? 'Uncategorized'}', style: _titleStyle),
                              subtitle: Text('${row['items_count'] ?? 0} items', style: _subStyle),
                              trailing: Text('${row['total_quantity'] ?? 0}', style: _titleStyle),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),
                AnalyticsSection(
                  title: 'Stock Movements',
                  subtitle: 'Movement activity in the selected period.',
                  child: movements.isEmpty
                      ? _empty('No stock movement found for this period.')
                      : Column(
                          children: movements.take(20).map((row) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.sync_alt_rounded, color: teal),
                              title: Text('${row['label'] ?? ''}', style: _titleStyle),
                              subtitle: Text('${row['reference'] ?? 'Movement'}', style: _subStyle),
                              trailing: Text('${row['quantity_moved'] ?? 0}', style: _titleStyle),
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
      title: const Text('Inventory Analytics', style: TextStyle(fontWeight: FontWeight.w900)),
      actions: [
        IconButton(
          onPressed: () => ref.read(genericAnalyticsProvider('inventory').notifier).load(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  static final _titleStyle = const TextStyle(color: dark, fontWeight: FontWeight.w900);
  static final _subStyle = const TextStyle(color: muted, fontWeight: FontWeight.w700);

  static Widget _empty(String text) => Text(text, style: _subStyle);
}
