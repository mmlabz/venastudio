import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;
import 'package:venastudio/common.dart';

class AllOrdersPage extends ConsumerStatefulWidget {
  const AllOrdersPage({super.key});

  @override
  ConsumerState<AllOrdersPage> createState() => _AllOrdersPageState();
}

class _AllOrdersPageState extends ConsumerState<AllOrdersPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);
  static const Color venaSuccess = Color(0xff13A76B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(orderServicesProvider);
    final isLoading = ordersState is OrdersLoading;
    final hasError = ordersState is OrdersError;

    return Scaffold(
      backgroundColor: venaBg,
      appBar: AppBar(
        backgroundColor: venaBg,
        foregroundColor: venaDark,
        elevation: 0,
        centerTitle: true,
        leading: context.backIcon(ref, _goBack),
        title: const Text(
          'Orders By Branch',
          style: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(orderServicesProvider),
            icon: const Icon(Icons.refresh_rounded, color: venaDark),
          ),
        ],
      ),
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: venaTeal))
            : hasError
            ? const Center(
                child: Text(
                  'Failed to load orders',
                  style: TextStyle(
                    color: venaDanger,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            : _buildOrdersContent(ordersState),
      ),
    );
  }

  Widget _buildOrdersContent(dynamic ordersState) {
    final orders = ordersState.orders.cast<Map<String, dynamic>>();

    if (orders.isEmpty) {
      return emptyState(ref, text: 'No orders available');
    }

    final Map<String, List<Map<String, dynamic>>> ordersByBranch = {};

    for (final order in orders) {
      final branch = order['store'] as String? ?? 'Unknown Branch';
      ordersByBranch[branch] = [...(ordersByBranch[branch] ?? []), order];
    }

    final allOrders = ordersByBranch.values.expand((x) => x).toList();
    final branches = ordersByBranch.keys.toList();

    if (_tabController.length != branches.length + 1) {
      _tabController.dispose();
      _tabController = TabController(length: branches.length + 1, vsync: this);
    }

    return Column(
      children: [
        _topSummary(allOrders.length, branches.length),
        _branchTabs(allOrders, branches, ordersByBranch),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
                color: venaTeal,
                onRefresh: () async {
                  ref.invalidate(orderServicesProvider);
                },
                child: OrderListView(orders: allOrders),
              ),
              ...branches.map((branch) {
                final branchOrders = ordersByBranch[branch] ?? [];

                return branchOrders.isNotEmpty
                    ? RefreshIndicator(
                        color: venaTeal,
                        onRefresh: () async {
                          ref.invalidate(orderServicesProvider);
                        },
                        child: OrderListView(orders: branchOrders),
                      )
                    : emptyState(ref, text: 'No orders for this branch');
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topSummary(int totalOrders, int branches) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: venaTeal.withOpacity(0.10),
              border: Border.all(color: venaTeal.withOpacity(0.25)),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: venaTeal,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BRANCH ORDERS',
                  style: TextStyle(
                    color: venaDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'View completed orders grouped by shop',
                  style: TextStyle(
                    color: venaMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _miniStat('Orders', totalOrders.toString()),
          const SizedBox(width: 10),
          _miniStat('Branches', branches.toString()),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: venaTeal.withOpacity(0.08),
        border: Border.all(color: venaTeal.withOpacity(0.22)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: venaTeal,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: venaMuted,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _branchTabs(
    List<Map<String, dynamic>> allOrders,
    List<String> branches,
    Map<String, List<Map<String, dynamic>>> ordersByBranch,
  ) {
    return Container(
      height: 58,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicator: const BoxDecoration(color: venaTeal),
        labelColor: Colors.white,
        unselectedLabelColor: venaDark,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        tabs: [
          _tabBadge('All Orders', allOrders.length, activeText: true),
          ...branches.map((branch) {
            final branchOrders = ordersByBranch[branch] ?? [];
            return _tabBadge(branch, branchOrders.length);
          }),
        ],
      ),
    );
  }

  Widget _tabBadge(String title, int count, {bool activeText = false}) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: badges.Badge(
          badgeContent: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          badgeStyle: const badges.BadgeStyle(
            badgeColor: venaSuccess,
            padding: EdgeInsets.all(6),
          ),
          position: badges.BadgePosition.topEnd(top: -16, end: -22),
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

class OrderListView extends StatelessWidget {
  const OrderListView({super.key, required this.orders});

  final List<Map<String, dynamic>> orders;

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'No Orders',
          style: TextStyle(color: venaMuted, fontWeight: FontWeight.w800),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderItemCard(order: order);
      },
    );
  }
}

class OrderItemCard extends StatelessWidget {
  const OrderItemCard({super.key, required this.order});

  final Map<String, dynamic> order;

  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaSuccess = Color(0xff13A76B);

  @override
  Widget build(BuildContext context) {
    final amount = (order['amount'] as num?)?.toDouble();
    final endTime = DateTime.tryParse(order['endTime']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        border: Border.all(color: venaLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: venaTeal.withOpacity(0.10),
                  border: Border.all(color: venaTeal.withOpacity(0.25)),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: venaTeal,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  order['billno']?.toString() ?? 'Unknown Bill No',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: venaDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                amount?.money ?? 'N/A',
                style: const TextStyle(
                  color: venaTeal,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.payment_rounded,
            'Payment: ${order['type'] ?? 'Unknown Payment Type'}',
          ),
          _infoRow(
            Icons.confirmation_number_outlined,
            'Ticket: ${order['receipt'] ?? 'Unknown Receipt'}',
          ),
          _infoRow(
            Icons.person_outline_rounded,
            'Completed By: ${order['agentname'] ?? 'Unknown Agent'}',
          ),
          _infoRow(
            Icons.calendar_today_outlined,
            'Completed On: ${DateFormat.yMMMd().format(endTime ?? DateTime.now())}',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _smallTag(order['store']?.toString() ?? 'Unknown Branch'),
              const Spacer(),
              const Icon(
                Icons.check_circle_rounded,
                color: venaSuccess,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: venaMuted),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: venaMuted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: venaTeal.withOpacity(0.08),
        border: Border.all(color: venaTeal.withOpacity(0.22)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: venaDark,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
