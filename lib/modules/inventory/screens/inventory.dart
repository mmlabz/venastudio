import 'package:venastudio/common.dart';
import '../controllers/inventory_controller.dart';
import '../models/inventory_models.dart';

Future<void> showInventoryPopup(
  BuildContext context, {
  required bool success,
  required String title,
  required String message,
}) async {
  if (!context.mounted) return;

  final color = success ? const Color(0xff13A76B) : const Color(0xffD94B4B);

  await showDialog<void>(
    context: context,
    useRootNavigator: false,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xff07304A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xff6B8794),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: () {
              final nav = Navigator.of(dialogContext, rootNavigator: false);
              if (nav.canPop()) nav.pop();
            },
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      );
    },
  );
}

String cleanInventoryError(Object e) {
  final message = e.toString().trim();

  return message
      .replaceFirst('Exception: ', '')
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Error: ', '')
      .trim();
}

void safeCloseDialog(BuildContext context) {
  if (!context.mounted) return;

  final nav = Navigator.of(context, rootNavigator: false);

  if (nav.canPop()) {
    nav.pop();
  }
}

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String search = '';
  String trackingFilter = 'ALL';
  String stockFilter = 'ALL';

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);
  static const Color venaSuccess = Color(0xff13A76B);
  static const Color venaWarn = Color(0xffD9902F);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryServicesProvider);
    final notifier = ref.read(inventoryServicesProvider.notifier);

    final isEmployee = notifier.isEmployee;
    final canOperate = notifier.canOperate;

    final tabs = isEmployee
        ? ['Available', 'My Items']
        : ['Available', 'Requests', 'Issued', 'Returns'];

    if (_tabController.length != tabs.length) {
      _tabController.dispose();
      _tabController = TabController(length: tabs.length, vsync: this);
    }

    return Scaffold(
      backgroundColor: venaBg,
      floatingActionButton: canOperate
          ? FloatingActionButton.extended(
              backgroundColor: venaTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Request Stock',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              onPressed: () {
                final data = ref.read(inventoryServicesProvider).valueOrNull;
                if (data != null) _showRequestSheet(data.products);
              },
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xffF8FDFF),
              Color(0xffEEF9FB),
              Color(0xffE4F7FA),
            ],
          ),
        ),
        child: SafeArea(
          child: inventory.when(
            loading: () => _loadingState(),
            error: (error, stackTrace) => _errorState(error.toString()),
            data: (data) => Column(
              children: [
                _header(notifier),
                _summaryStrip(
                  data,
                  isEmployee,
                  notifier.employeeId,
                  notifier.userType,
                  notifier.selectedPeriodLabel,
                ),
                _filters(notifier),
                _tabBar(tabs),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: isEmployee
                        ? [
                            _availableProducts(data.products, canOperate),
                            _myItems(data.issues, data.employees),
                          ]
                        : [
                            _availableProducts(data.products, canOperate),
                            _requests(data.requests, data.employees),
                            _issued(data.issues, canOperate, data.employees),
                            _returns(data.returns, data.employees),
                          ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(InventoryNotifier notifier) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBox(Icons.inventory_2_outlined, venaTeal, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inventory Control',
                  style: TextStyle(
                    color: venaDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Showing ${notifier.selectedPeriodLabel.toLowerCase()} records',
                  style: const TextStyle(
                    color: venaMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(inventoryServicesProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, color: venaDark),
          ),
        ],
      ),
    );
  }

  Widget _summaryStrip(
    InventoryStateData data,
    bool isEmployee,
    int employeeId,
    String userType,
    String periodLabel,
  ) {
    final outstanding = isEmployee
        ? data.issues
            .where((i) => i.issuedTo == employeeId && i.qtyOutstanding > 0)
            .length
        : data.outstandingCount;

    final cards = [
      _metric('Products', '${data.products.length}', periodLabel,
          Icons.inventory_2_outlined, venaTeal),
      _metric('Low Stock', '${data.lowStockCount}', periodLabel,
          Icons.warning_amber_rounded, venaWarn),
      if (!isEmployee)
        _metric('Requests', '${data.requests.length}', periodLabel,
            Icons.pending_actions_rounded, venaDark),
      _metric(isEmployee ? 'My Items' : 'Outstanding', '$outstanding',
          periodLabel, Icons.assignment_return_outlined, venaSuccess),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width < 380
              ? 1
              : width < 760
                  ? 2
                  : cards.length;
          const spacing = 8.0;
          final cardWidth = (width - (spacing * (columns - 1))) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: cards
                .map((card) => SizedBox(width: cardWidth, child: card))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _metric(
    String title,
    String value,
    String period,
    IconData icon,
    Color color,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBox(icon, color, size: 38),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: venaMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: venaDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  period,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: venaMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters(InventoryNotifier notifier) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final small = constraints.maxWidth < 720;

          if (small) {
            return Column(
              children: [
                _search(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _periodButton(notifier)),
                    const SizedBox(width: 8),
                    SizedBox(width: 92, child: _todayButton(notifier)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        'Tracking',
                        trackingFilter,
                        const [
                          'ALL',
                          'consumable',
                          'returnable',
                          'semi_consumable',
                        ],
                        (v) => setState(() => trackingFilter = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _dropdown(
                        'Stock',
                        stockFilter,
                        const ['ALL', 'LOW', 'AVAILABLE', 'OUT'],
                        (v) => setState(() => stockFilter = v!),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 2, child: _search()),
              const SizedBox(width: 8),
              Expanded(child: _periodButton(notifier)),
              const SizedBox(width: 8),
              SizedBox(width: 92, child: _todayButton(notifier)),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown(
                  'Tracking',
                  trackingFilter,
                  const [
                    'ALL',
                    'consumable',
                    'returnable',
                    'semi_consumable',
                  ],
                  (v) => setState(() => trackingFilter = v!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown(
                  'Stock',
                  stockFilter,
                  const ['ALL', 'LOW', 'AVAILABLE', 'OUT'],
                  (v) => setState(() => stockFilter = v!),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _periodButton(InventoryNotifier notifier) {
    return SizedBox(
      height: 44,
      child: TextButton.icon(
        onPressed: _pickDateRange,
        icon: const Icon(Icons.calendar_month_rounded, size: 18),
        label: Text(
          notifier.selectedPeriodLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: TextButton.styleFrom(
          backgroundColor: venaDark,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _todayButton(InventoryNotifier notifier) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: () async {
          await notifier.resetToToday();
          if (mounted) setState(() {});
        },
        style: TextButton.styleFrom(
          backgroundColor: venaTeal.withOpacity(0.10),
          foregroundColor: venaDark,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          side: BorderSide(color: venaTeal.withOpacity(0.35)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        child: const Text('Today'),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final notifier = ref.read(inventoryServicesProvider.notifier);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: notifier.selectedStart,
        end: notifier.selectedEnd,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
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

    if (picked != null) {
      await notifier.changePeriod(start: picked.start, end: picked.end);
      if (mounted) setState(() {});
    }
  }

  Widget _search() {
    return SizedBox(
      height: 44,
      child: TextField(
        onChanged: (value) => setState(() => search = value.toLowerCase()),
        style: const TextStyle(
          color: venaDark,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search_rounded, color: venaMuted, size: 20),
          hintText: 'Search products, SKU, people, reference...',
          hintStyle: TextStyle(
            color: venaMuted,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: venaLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: venaTeal, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return SizedBox(
      height: 44,
      child: InputDecorator(
        decoration: const InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: venaLine),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: venaLine),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: Colors.white,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: venaDark,
              size: 18,
            ),
            style: const TextStyle(
              color: venaDark,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e == 'ALL' ? '$label: ALL' : e,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _tabBar(List<String> tabs) {
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: const BoxDecoration(color: venaTeal),
        labelColor: Colors.white,
        unselectedLabelColor: venaMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        dividerColor: Colors.transparent,
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  List<InventoryProduct> _filteredProducts(List<InventoryProduct> products) {
    return products.where((p) {
      final text = '${p.name} ${p.sku} ${p.variantLabel} ${p.categoryName}'
          .toLowerCase();

      if (search.isNotEmpty && !text.contains(search)) return false;
      if (trackingFilter != 'ALL' && p.trackingType != trackingFilter) {
        return false;
      }
      if (stockFilter == 'LOW' && !p.isLowStock) return false;
      if (stockFilter == 'AVAILABLE' && p.availableQty <= 0) return false;
      if (stockFilter == 'OUT' && p.availableQty > 0) return false;

      return true;
    }).toList();
  }

  Widget _availableProducts(List<InventoryProduct> products, bool canOperate) {
    final filtered = _filteredProducts(products);

    if (filtered.isEmpty) {
      return _empty('No products found', Icons.inventory_2_outlined);
    }

    return RefreshIndicator(
      color: venaTeal,
      onRefresh: () => ref.read(inventoryServicesProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: filtered.length,
        itemBuilder: (context, index) =>
            _productRow(filtered[index], canOperate),
      ),
    );
  }

  Widget _productRow(InventoryProduct product, bool canOperate) {
    final out = product.availableQty <= 0;

    return InkWell(
      onTap: canOperate ? () => _showProductActions(product) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: _cardDecoration(
          borderColor:
              product.isLowStock ? venaWarn.withOpacity(0.5) : venaLine,
        ),
        child: Row(
          children: [
            _iconBox(Icons.inventory_2_outlined, venaTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: venaDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      _statusPill(
                        out
                            ? 'OUT'
                            : product.isLowStock
                                ? 'LOW'
                                : 'OK',
                        out
                            ? venaDanger
                            : product.isLowStock
                                ? venaWarn
                                : venaSuccess,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    children: [
                      _miniTag(product.categoryName),
                      if (product.variantLabel.isNotEmpty)
                        _miniTag(product.variantLabel),
                      _miniTag(product.trackingType),
                      if (product.sku.isNotEmpty)
                        _miniTag('SKU ${product.sku}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmt(product.availableQty),
                  style: TextStyle(
                    color: out ? venaDanger : venaDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  product.unit,
                  style: const TextStyle(
                    color: venaMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (canOperate) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: venaMuted),
            ],
          ],
        ),
      ),
    );
  }

  Widget _requests(
    List<InventoryRequest> requests,
    List<InventoryEmployee> employees,
  ) {
    final list = requests.where((r) {
      final person = _personName(employees, r.requestedBy);
      final text = '${r.requestNo} $person ${r.status}'.toLowerCase();
      return search.isEmpty || text.contains(search);
    }).toList();

    if (list.isEmpty) {
      return _empty(
        'No stock requests for this period',
        Icons.pending_actions_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final r = list[index];

        return _recordCard(
          icon: Icons.receipt_long_outlined,
          iconColor: venaTeal,
          title: r.requestNo,
          lines: [
            _infoLine(
              Icons.person_outline_rounded,
              'Requested by ${_personName(employees, r.requestedBy)}',
            ),
            _infoLine(
              Icons.schedule_rounded,
              'Requested on ${_dateTimeLabel(r.createdAt)}',
            ),
            _infoLine(
              Icons.inventory_2_outlined,
              '${r.itemCount} items • requested ${_fmt(r.totalRequested)} • fulfilled ${_fmt(r.totalFulfilled)}',
            ),
          ],
          trailing: _statusPill(
            r.status.replaceAll('_', ' ').toUpperCase(),
            _statusColor(r.status),
          ),
        );
      },
    );
  }

  Widget _issued(
    List<InventoryIssue> issues,
    bool canOperate,
    List<InventoryEmployee> employees,
  ) {
    final list = issues.where((i) {
      final people =
          '${_personName(employees, i.issuedBy)} ${_personName(employees, i.issuedTo)}';
      final text = '${i.name} ${i.issueNo} $people'.toLowerCase();
      return search.isEmpty || text.contains(search);
    }).toList();

    if (list.isEmpty) {
      return _empty(
        'No issued products for this period',
        Icons.assignment_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: list.length,
      itemBuilder: (context, index) =>
          _issueRow(list[index], canOperate, employees),
    );
  }

  Widget _myItems(
    List<InventoryIssue> issues,
    List<InventoryEmployee> employees,
  ) {
    if (issues.isEmpty) {
      return _empty(
        'You have no outstanding inventory items for this period',
        Icons.assignment_return_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: issues.length,
      itemBuilder: (context, index) =>
          _issueRow(issues[index], false, employees),
    );
  }

  Widget _issueRow(
    InventoryIssue issue,
    bool canReturn,
    List<InventoryEmployee> employees,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(
        borderColor:
            issue.qtyOutstanding > 0 ? venaLine : venaSuccess.withOpacity(0.35),
      ),
      child: Row(
        children: [
          _iconBox(Icons.outbox_rounded, venaTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: venaDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                _infoLine(
                  Icons.people_alt_outlined,
                  'Issued by ${_personName(employees, issue.issuedBy)} • To ${_personName(employees, issue.issuedTo)}',
                ),
                _infoLine(
                  Icons.schedule_rounded,
                  'Issued on ${_dateTimeLabel(issue.createdAt)}',
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    _miniTag(issue.issueNo),
                    _miniTag('Issued ${_fmt(issue.qtyIssued)}'),
                    _miniTag('Returned ${_fmt(issue.qtyReturned)}'),
                    _miniTag(issue.trackingType),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmt(issue.qtyOutstanding),
                style: TextStyle(
                  color: issue.qtyOutstanding > 0 ? venaDanger : venaSuccess,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const Text(
                'outstanding',
                style: TextStyle(
                  color: venaMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
              if (canReturn && issue.qtyOutstanding > 0) ...[
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: venaTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 34),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: () => _showReturnSheet(issue),
                  child: const Text(
                    'RETURN',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _returns(
    List<InventoryReturnRecord> returns,
    List<InventoryEmployee> employees,
  ) {
    final list = returns.where((r) {
      final people =
          '${_personName(employees, r.returnedBy)} ${_personName(employees, r.receivedBy)}';
      final text = '${r.name} ${r.returnNo} $people'.toLowerCase();
      return search.isEmpty || text.contains(search);
    }).toList();

    if (list.isEmpty) {
      return _empty(
        'No returned products for this period',
        Icons.assignment_return_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final r = list[index];

        return _recordCard(
          icon: Icons.assignment_return_rounded,
          iconColor: venaSuccess,
          title: r.name,
          lines: [
            _infoLine(
              Icons.people_alt_outlined,
              'Returned by ${_personName(employees, r.returnedBy)} • Received by ${_personName(employees, r.receivedBy)}',
            ),
            _infoLine(
              Icons.schedule_rounded,
              'Returned on ${_dateTimeLabel(r.createdAt)}',
            ),
            _infoLine(
              Icons.inventory_2_outlined,
              '${r.returnNo} • ${_fmt(r.qtyReturned)} ${r.unit}',
            ),
          ],
          trailing: _statusPill(
            r.conditionStatus.toUpperCase(),
            r.conditionStatus == 'good' ? venaSuccess : venaWarn,
          ),
        );
      },
    );
  }

  Widget _recordCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> lines,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBox(icon, iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: venaDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                ...lines,
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: venaTeal.withOpacity(0.95)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: venaDark,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color, {double size = 42}) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Icon(icon, color: color, size: size > 42 ? 24 : 20),
    );
  }

  BoxDecoration _cardDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.97),
      border: Border.all(color: borderColor ?? venaLine),
      boxShadow: [
        BoxShadow(
          color: venaDark.withOpacity(0.03),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  String _personName(List<InventoryEmployee> employees, int id) {
    if (id <= 0) return 'Unknown';

    try {
      final person = employees.firstWhere((e) => e.id == id);
      return person.name.trim().isNotEmpty ? person.name.trim() : 'User #$id';
    } catch (_) {
      return 'User #$id';
    }
  }

  DateTime? _dateFromInt(int value) {
    if (value <= 0) return null;

    final raw = value.toString();
    if (raw.length >= 13) return DateTime.fromMillisecondsSinceEpoch(value);

    return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  }

  String _dateTimeLabel(int createdAt) {
    final date = _dateFromInt(createdAt);
    if (date == null) return 'Date unavailable';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  void _showProductActions(InventoryProduct product) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActionSheet(
        title: product.name,
        subtitle: '${_fmt(product.availableQty)} ${product.unit} available',
        children: [
          _sheetAction(
            Icons.add_shopping_cart_rounded,
            'Request Stock',
            'Create a branch stock request',
            () {
              Navigator.pop(context);
              _showRequestSheet([product]);
            },
          ),
          _sheetAction(
            Icons.outbox_rounded,
            'Issue Item',
            'Issue to a front-office user or employee',
            () {
              Navigator.pop(context);
              _showIssueSheet(product);
            },
          ),
        ],
      ),
    );
  }

  Widget _sheetAction(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: venaLine)),
        ),
        child: Row(
          children: [
            Icon(icon, color: venaTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: venaDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: venaMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: venaMuted),
          ],
        ),
      ),
    );
  }

  void _showRequestSheet(List<InventoryProduct> products) {
    _RequestStockSheet.show(context, ref, products);
  }

  void _showIssueSheet(InventoryProduct product) {
    final data = ref.read(inventoryServicesProvider).valueOrNull;
    _IssueStockSheet.show(context, ref, product, data?.employees ?? []);
  }

  void _showReturnSheet(InventoryIssue issue) {
    _ReturnStockSheet.show(context, ref, issue);
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _miniTag(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: venaTeal.withOpacity(0.07),
        border: Border.all(color: venaTeal.withOpacity(0.18)),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: venaDark,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _empty(String text, IconData icon) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: venaTeal.withOpacity(0.75), size: 42),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: venaDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          border: Border.all(color: venaLine),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: venaTeal),
            SizedBox(height: 14),
            Text(
              'Loading today’s inventory records...',
              style: TextStyle(
                color: venaDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: venaDanger.withOpacity(0.35)),
        ),
        child: Text(
          error,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: venaDanger,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    if (status.contains('approved') || status == 'received') {
      return venaSuccess;
    }
    if (status.contains('rejected')) return venaDanger;
    if (status.contains('ordered')) return venaTeal;
    return venaWarn;
  }

  String _fmt(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final sheetWidth = width > 760 ? 460.0 : width;

    return Align(
      alignment: width > 760 ? Alignment.centerRight : Alignment.bottomCenter,
      child: SizedBox(
        width: sheetWidth,
        child: Material(
          color: Colors.white,
          child: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: venaLine),
                  top: BorderSide(color: venaLine),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: venaTeal.withOpacity(0.08),
                      border: const Border(bottom: BorderSide(color: venaLine)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, color: venaTeal),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: venaDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: venaMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: venaDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestStockSheet extends StatefulWidget {
  const _RequestStockSheet({required this.ref, required this.products});

  final WidgetRef ref;
  final List<InventoryProduct> products;

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    List<InventoryProduct> products,
  ) {
    return showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) => _RequestStockSheet(ref: ref, products: products),
    );
  }

  @override
  State<_RequestStockSheet> createState() => _RequestStockSheetState();
}

class _RequestStockSheetState extends State<_RequestStockSheet> {
  InventoryProduct? product;
  final qty = TextEditingController();
  final notes = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.products.length == 1) product = widget.products.first;
  }

  @override
  void dispose() {
    qty.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormDialog(
      title: 'Request Stock',
      loading: loading,
      submitText: 'CREATE REQUEST',
      onSubmit: _submit,
      children: [
        _productPicker(
          widget.products,
          product,
          (v) => setState(() => product = v),
        ),
        _field(qty, 'Quantity', number: true),
        _field(notes, 'Notes', maxLines: 3),
      ],
    );
  }

  Future<void> _submit() async {
    if (loading) return;

    if (product == null) {
      await showInventoryPopup(
        context,
        success: false,
        title: 'Missing product',
        message: 'Please select a product before creating the request.',
      );
      return;
    }

    final amount = double.tryParse(qty.text.trim()) ?? 0;

    if (amount <= 0) {
      await showInventoryPopup(
        context,
        success: false,
        title: 'Invalid quantity',
        message: 'Please enter a valid quantity greater than zero.',
      );
      return;
    }

    setState(() => loading = true);

    try {
      await widget.ref.read(inventoryServicesProvider.notifier).createRequest(
            product: product!,
            qty: amount,
            notes: notes.text.trim(),
          );

      if (!mounted) return;

      setState(() => loading = false);

      await showInventoryPopup(
        context,
        success: true,
        title: 'Request created',
        message: 'Stock request has been created successfully.',
      );

      if (!mounted) return;
      safeCloseDialog(context);
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      await showInventoryPopup(
        context,
        success: false,
        title: 'Request failed',
        message: cleanInventoryError(e),
      );
    }
  }
}

class _IssueStockSheet extends StatefulWidget {
  const _IssueStockSheet({
    required this.ref,
    required this.product,
    required this.employees,
  });

  final WidgetRef ref;
  final InventoryProduct product;
  final List<InventoryEmployee> employees;

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    InventoryProduct product,
    List<InventoryEmployee> employees,
  ) {
    return showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) =>
          _IssueStockSheet(ref: ref, product: product, employees: employees),
    );
  }

  @override
  State<_IssueStockSheet> createState() => _IssueStockSheetState();
}

class _IssueStockSheetState extends State<_IssueStockSheet> {
  InventoryEmployee? employee;
  final qty = TextEditingController();
  final notes = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    qty.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormDialog(
      title: 'Issue ${widget.product.name}',
      loading: loading,
      submitText: 'ISSUE STOCK',
      onSubmit: _submit,
      children: [
        _employeePicker(
          widget.employees,
          employee,
          (v) => setState(() => employee = v),
        ),
        _field(qty, 'Quantity', number: true),
        _field(notes, 'Notes', maxLines: 3),
      ],
    );
  }

  Future<void> _submit() async {
    if (loading) return;

    if (employee == null) {
      await showInventoryPopup(
        context,
        success: false,
        title: 'Missing employee',
        message: 'Please select who the stock is being issued to.',
      );
      return;
    }

    final amount = double.tryParse(qty.text.trim()) ?? 0;

    if (amount <= 0) {
      await showInventoryPopup(
        context,
        success: false,
        title: 'Invalid quantity',
        message: 'Please enter a valid quantity greater than zero.',
      );
      return;
    }

    setState(() => loading = true);

    try {
      await widget.ref.read(inventoryServicesProvider.notifier).issueProduct(
            product: widget.product,
            issuedTo: employee!.id,
            qty: amount,
            notes: notes.text.trim(),
          );

      if (!mounted) return;

      setState(() => loading = false);

      await showInventoryPopup(
        context,
        success: true,
        title: 'Stock issued',
        message: '${widget.product.name} has been issued to ${employee!.name}.',
      );

      if (!mounted) return;
      safeCloseDialog(context);
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      await showInventoryPopup(
        context,
        success: false,
        title: 'Issue failed',
        message: cleanInventoryError(e),
      );
    }
  }
}

class _ReturnStockSheet extends StatefulWidget {
  const _ReturnStockSheet({required this.ref, required this.issue});

  final WidgetRef ref;
  final InventoryIssue issue;

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    InventoryIssue issue,
  ) {
    return showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) => _ReturnStockSheet(ref: ref, issue: issue),
    );
  }

  @override
  State<_ReturnStockSheet> createState() => _ReturnStockSheetState();
}

class _ReturnStockSheetState extends State<_ReturnStockSheet> {
  final qty = TextEditingController();
  final notes = TextEditingController();

  String condition = 'good';
  bool loading = false;

  @override
  void dispose() {
    qty.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormDialog(
      title: 'Return ${widget.issue.name}',
      loading: loading,
      submitText: 'PROCESS RETURN',
      onSubmit: _submit,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _FormDialog.venaTeal.withOpacity(0.07),
            border: Border.all(color: _FormDialog.venaLine),
          ),
          child: Text(
            'Outstanding: ${widget.issue.qtyOutstanding}',
            style: const TextStyle(
              color: _FormDialog.venaDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _field(qty, 'Quantity returned', number: true),
        _conditionPicker(condition, (v) => setState(() => condition = v!)),
        _field(notes, 'Notes', maxLines: 3),
      ],
    );
  }

  Future<void> _submit() async {
    if (loading) return;

    final amount = double.tryParse(qty.text.trim()) ?? 0;

    if (amount <= 0) {
      await showInventoryPopup(
        context,
        success: false,
        title: 'Invalid quantity',
        message: 'Please enter a valid return quantity.',
      );
      return;
    }

    if (amount > widget.issue.qtyOutstanding) {
      await showInventoryPopup(
        context,
        success: false,
        title: 'Quantity too high',
        message:
            'You cannot return more than the outstanding quantity of ${widget.issue.qtyOutstanding}.',
      );
      return;
    }

    setState(() => loading = true);

    try {
      await widget.ref.read(inventoryServicesProvider.notifier).returnIssue(
            issue: widget.issue,
            qty: amount,
            conditionStatus: condition,
            notes: notes.text.trim(),
          );

      if (!mounted) return;

      setState(() => loading = false);

      await showInventoryPopup(
        context,
        success: true,
        title: 'Return processed',
        message: '${widget.issue.name} return has been processed successfully.',
      );

      if (!mounted) return;
      safeCloseDialog(context);
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      await showInventoryPopup(
        context,
        success: false,
        title: 'Return failed',
        message: cleanInventoryError(e),
      );
    }
  }
}

class _FormDialog extends StatelessWidget {
  const _FormDialog({
    required this.title,
    required this.children,
    required this.onSubmit,
    required this.submitText,
    required this.loading,
  });

  final String title;
  final List<Widget> children;
  final Future<void> Function() onSubmit;
  final String submitText;
  final bool loading;

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Center(
      child: SizedBox(
        width: w > 480 ? 460 : w - 24,
        child: Material(
          color: Colors.white,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: venaLine)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: venaTeal.withOpacity(0.08),
                    border: const Border(bottom: BorderSide(color: venaLine)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: venaDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            loading ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: venaDark),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: children),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: venaLine)),
                  ),
                  child: SizedBox(
                    height: 46,
                    width: double.infinity,
                    child: TextButton(
                      onPressed: loading ? null : onSubmit,
                      style: TextButton.styleFrom(
                        backgroundColor: venaTeal,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              submitText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _field(
  TextEditingController controller,
  String label, {
  bool number = false,
  int maxLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: number
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      style: const TextStyle(
        color: _FormDialog.venaDark,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _FormDialog.venaMuted,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: _FormDialog.venaBg.withOpacity(0.65),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _FormDialog.venaLine),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _FormDialog.venaTeal, width: 1.4),
        ),
      ),
    ),
  );
}

Widget _productPicker(
  List<InventoryProduct> products,
  InventoryProduct? value,
  ValueChanged<InventoryProduct?> onChanged,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<InventoryProduct>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Product',
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _FormDialog.venaLine),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _FormDialog.venaLine),
        ),
      ),
      items: products
          .map(
            (p) => DropdownMenuItem(
              value: p,
              child: Text(
                '${p.name} • ${p.availableQty} ${p.unit}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    ),
  );
}

Widget _employeePicker(
  List<InventoryEmployee> employees,
  InventoryEmployee? value,
  ValueChanged<InventoryEmployee?> onChanged,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<InventoryEmployee>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Issue to',
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _FormDialog.venaLine),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _FormDialog.venaLine),
        ),
      ),
      items: employees
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    ),
  );
}

Widget _conditionPicker(String value, ValueChanged<String?> onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Condition',
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _FormDialog.venaLine),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _FormDialog.venaLine),
        ),
      ),
      items: const ['good', 'damaged', 'lost', 'partial', 'depleted']
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    ),
  );
}
