import 'package:venastudio/common.dart';

class StatementOfCashflowPage extends ConsumerStatefulWidget {
  const StatementOfCashflowPage({super.key});

  @override
  ConsumerState<StatementOfCashflowPage> createState() =>
      _StatementOfCashflowPageState();
}

class _StatementOfCashflowPageState
    extends ConsumerState<StatementOfCashflowPage> {
  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff00BFD8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff6B8794);
  static const Color line = Color(0xffCFEFF4);
  static const Color danger = Color(0xffD94B4B);
  static const Color success = Color(0xff13A76B);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statementOfCashflowProvider);
    final user = financeCurrentUserFromWidget(ref);

    if (!financeIsAdmin(user)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statement of Cashflow')),
        body: const Center(
          child: Text('Only admins can view statement of cashflow.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: dark,
        elevation: 0,
        leading: context.backIcon(ref, () => context.go('/settings')),
        title: const Text(
          'Statement of Cashflow',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range_rounded),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: teal),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final summary = Map<String, dynamic>.from(data['summary'] ?? {});
          final methods = data['payment_methods'] is List
              ? (data['payment_methods'] as List)
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : <Map<String, dynamic>>[];

          final categories = data['expense_categories'] is List
              ? (data['expense_categories'] as List)
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
              : <Map<String, dynamic>>[];

          final inflows =
              double.tryParse('${summary['total_inflows'] ?? 0}') ?? 0;
          final outflows =
              double.tryParse('${summary['total_outflows'] ?? 0}') ?? 0;
          final net = inflows - outflows;

          return RefreshIndicator(
            color: teal,
            onRefresh: () {
              return ref.read(statementOfCashflowProvider.notifier).load();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _stat('Cash Inflows', inflows, success),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _stat('Cash Outflows', outflows, danger),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _stat('Net Cashflow', net, net >= 0 ? teal : danger),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _section('By Payment Method', methods, 'payment_method'),
                const SizedBox(height: 18),
                _section('By Expense Category', categories, 'category'),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickRange() async {
    final notifier = ref.read(statementOfCashflowProvider.notifier);

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(
        start: notifier.startDate,
        end: notifier.endDate,
      ),
    );

    if (range != null) {
      await notifier.load(start: range.start, end: range.end);
    }
  }

  Widget _stat(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 5),
          Text(amount.money, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _section(String title, List<Map<String, dynamic>> rows, String labelKey) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: dark, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const Text('No records', style: TextStyle(color: muted))
          else
            ...rows.map((r) {
              final inflow = double.tryParse('${r['inflows'] ?? 0}') ?? 0;
              final outflow = double.tryParse('${r['outflows'] ?? 0}') ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${r[labelKey] ?? 'Unknown'}', style: const TextStyle(color: dark, fontWeight: FontWeight.w800)),
                    ),
                    Text(
                      'In ${inflow.money}  •  Out ${outflow.money}',
                      style: const TextStyle(color: muted, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
