import 'package:intl/intl.dart';
import 'package:venastudio/common.dart';

class SummaryPage extends ConsumerStatefulWidget {
  const SummaryPage({super.key});

  @override
  ConsumerState<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends ConsumerState<SummaryPage> {
  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00AFC3);
  static const Color venaTealDark = Color(0xff007A8A);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffEF476F);
  static const Color venaGreen = Color(0xff13A86B);
  static const Color venaOrange = Color(0xffF5A623);

  String _quickPeriod = 'Today';
  (DateTime, DateTime)? _range;

  bool get _isSmallScreen => MediaQuery.of(context).size.width < 760;

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = ref.watch(summaryServicesProvider).finance;

    return Scaffold(
      backgroundColor: venaBg,
      appBar: _isSmallScreen
          ? AppBar(
              backgroundColor: venaBg,
              foregroundColor: venaDark,
              elevation: 0,
              leading: context.backIcon(ref, _goBack),
              title: const Text(
                'Admin Summary',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffF8FDFF), Color(0xffEEF9FB), Color(0xffE4F7FA)],
          ),
        ),
        child: finance.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: venaTeal),
          ),
          error: (err, _) => _errorState(err.toString()),
          data: (data) => RefreshIndicator(
            color: venaTeal,
            onRefresh: () async => ref
                .read(summaryServicesProvider.notifier)
                .getFinanceSummary(range: _range, isRefresh: true),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                _isSmallScreen ? 14 : 28,
                _isSmallScreen ? 14 : 24,
                _isSmallScreen ? 14 : 28,
                28,
              ),
              children: [
                if (!_isSmallScreen) _header(data),
                if (!_isSmallScreen) const SizedBox(height: 14),
                _periodSelector(data),
                const SizedBox(height: 18),
                _metricGrid(data),
                const SizedBox(height: 18),
                _financeStatement(data),
                const SizedBox(height: 18),
                _insightStrip(data),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(AdminFinanceSummary data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          InkWell(
            onTap: _goBack,
            child: _squareIcon(Icons.arrow_back_rounded, Colors.white, venaDark),
          ),
          const SizedBox(width: 14),
          _squareIcon(Icons.analytics_outlined, venaTeal.withOpacity(0.12), venaTeal),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMIN SUMMARY',
                  style: TextStyle(
                    color: venaDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cash inflows, cash outflows and gross profit overview',
                  style: TextStyle(
                    color: venaMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: data.isSuperAdmin ? venaTeal.withOpacity(0.1) : venaOrange.withOpacity(0.12),
              border: Border.all(color: data.isSuperAdmin ? venaTeal.withOpacity(0.28) : venaOrange.withOpacity(0.28)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              data.isSuperAdmin ? 'Super Admin View' : 'Today / Yesterday View',
              style: TextStyle(
                color: data.isSuperAdmin ? venaTealDark : venaOrange,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodSelector(AdminFinanceSummary data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _periodButton('Today', data.isSuperAdmin),
          _periodButton('Yesterday', data.isSuperAdmin),
          if (data.isSuperAdmin) ...[
            _periodButton('This Week', true),
            _periodButton('This Month', true),
            OutlinedButton.icon(
              style: _outlineButtonStyle(),
              onPressed: _pickCustomRange,
              icon: const Icon(Icons.date_range_rounded, size: 18),
              label: Text(_rangeLabel()),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Store managers and front office can only view today and yesterday.',
                style: TextStyle(
                  color: venaMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _periodButton(String label, bool isSuperAdmin) {
    final selected = _quickPeriod == label;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: selected ? venaTeal : Colors.white,
        foregroundColor: selected ? Colors.white : venaDark,
        side: BorderSide(color: selected ? venaTeal : venaLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      ),
      onPressed: () {
        final now = DateTime.now();
        DateTime start = now;
        DateTime end = now;

        if (label == 'Yesterday') {
          start = now.subtract(const Duration(days: 1));
          end = start;
        } else if (label == 'This Week' && isSuperAdmin) {
          start = now.subtract(Duration(days: now.weekday - 1));
        } else if (label == 'This Month' && isSuperAdmin) {
          start = DateTime(now.year, now.month, 1);
        }

        setState(() {
          _quickPeriod = label;
          _range = (start, end);
        });

        ref.read(summaryServicesProvider.notifier).getFinanceSummary(
              range: _range,
              isRefresh: true,
            );
      },
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _range == null
          ? DateTimeRange(start: DateTime(now.year, now.month, 1), end: now)
          : DateTimeRange(start: _range!.$1, end: _range!.$2),
      builder: (context, child) {
        final baseTheme = ThemeData.light();
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: venaTeal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: venaDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _quickPeriod = 'Custom';
      _range = (picked.start, picked.end);
    });

    ref.read(summaryServicesProvider.notifier).getFinanceSummary(
          range: _range,
          isRefresh: true,
        );
  }

  String _rangeLabel() {
    if (_quickPeriod != 'Custom' || _range == null) return 'Custom';
    final fmt = DateFormat('MMM d');
    return '${fmt.format(_range!.$1)} - ${fmt.format(_range!.$2)}';
  }

  Widget _metricGrid(AdminFinanceSummary data) {
    final cards = [
      _MetricData('Total Sales', data.totalSales, Icons.trending_up_rounded, venaGreen),
      _MetricData('Cash Outflows', data.totalCashOutflows, Icons.trending_down_rounded, venaDanger),
      _MetricData('Expenses', data.totalExpenses, Icons.receipt_long_rounded, venaOrange),
      _MetricData('Gross Profit', data.grossProfit, Icons.account_balance_wallet_rounded, data.grossProfit >= 0 ? venaGreen : venaDanger),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 950 ? 4 : constraints.maxWidth > 600 ? 2 : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((card) => SizedBox(width: width, child: _metricCard(card))).toList(),
        );
      },
    );
  }

  Widget _metricCard(_MetricData card) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        border: Border.all(color: card.color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: card.color.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: card.color.withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(card.icon, color: card.color, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.label.toUpperCase(),
                  style: TextStyle(
                    color: card.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _money(card.value),
                  style: const TextStyle(
                    color: venaDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _financeStatement(AdminFinanceSummary data) {
    return Container(
      decoration: _panelDecoration(radius: 18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xff007A8A), Color(0xff00AFC3)]),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'ADMIN FINANCE STATEMENT',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
                Text(
                  'AMOUNT (KES)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ],
            ),
          ),
          _sectionHeader('1. STORE SALES', Icons.storefront_rounded, venaGreen),
          ...data.stores.map(
            (e) => _statementRow(
              '${e.store}  •  ${e.orders} orders',
              e.total,
              trailing: 'Cash ${_compact(e.cash)}   Mpesa ${_compact(e.mpesa)}   Bank ${_compact(e.bank)}',
            ),
          ),
          _statementRow('Total Store Sales', data.totalSales, bold: true, color: venaGreen),
          _sectionHeader('2. CASH OUTFLOWS', Icons.trending_down_rounded, venaDanger),
          _statementRow(
            'Staff Commissions',
            data.totalCommissions,
            trailing: 'Total commission payout for the period',
          ),
          ...data.expensesByCategory.map(
            (e) => _statementRow('Expense: ${e.category}  •  ${e.count} entries', e.amount),
          ),
          _statementRow('Total Expenses', data.totalExpenses, bold: true, color: venaOrange),
          _statementRow('Total Cash Outflows', data.totalCashOutflows, bold: true, color: venaDanger),
          _statementRow('Gross Profit', data.grossProfit, bold: true, color: data.grossProfit >= 0 ? venaGreen : venaDanger),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xff007A8A), Color(0xff00AFC3)]),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'NET / GROSS PROFIT',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
                Text(
                  _money(data.grossProfit),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      color: color.withOpacity(0.07),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(color: color.withOpacity(0.13), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statementRow(String label, double value, {String? trailing, bool bold = false, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xffE7F3F6))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color ?? venaDark,
                    fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                    fontSize: bold ? 14 : 13,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    trailing,
                    style: const TextStyle(color: venaMuted, fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Text(
            _money(value),
            style: TextStyle(
              color: color ?? venaDark,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
              fontSize: bold ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightStrip(AdminFinanceSummary data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(radius: 16),
      child: Row(
        children: [
          _squareIcon(Icons.lightbulb_outline_rounded, venaTeal.withOpacity(0.12), venaTeal),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Gross profit is ${_money(data.grossProfit)} after total cash outflows for the selected period.',
              style: const TextStyle(color: venaMuted, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _squareIcon(IconData icon, Color bg, Color color) {
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: venaLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  BoxDecoration _panelDecoration({double radius = 14}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.96),
      border: Border.all(color: venaLine),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: venaTeal.withOpacity(0.06),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  ButtonStyle _outlineButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: venaDark,
      side: const BorderSide(color: venaLine),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.all(18),
        decoration: _panelDecoration(),
        child: Text(
          'Error: $message',
          style: const TextStyle(color: venaDanger, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  String _money(num value) {
    final fmt = NumberFormat('#,##0.##');
    return 'KES ${fmt.format(value)}';
  }

  String _compact(num value) {
    final fmt = NumberFormat.compact();
    return fmt.format(value);
  }
}

class _MetricData {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _MetricData(this.label, this.value, this.icon, this.color);
}
