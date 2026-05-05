import 'package:intl/intl.dart';
import 'package:venastudio/common.dart';

void showOrderSnack(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red : Colors.black87,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();

  String dateBtn = 'Today';
  bool isWaitingSelected = true;

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshOrders() async {
    if (!mounted) return;
    ref.invalidate(orderServicesProvider);
  }

  ServiceUser? _currentUser() {
    final activeAgent = LocalStorage.nosql.activeAgent;

    if (activeAgent != null) {
      return ServiceUser.fromMap(activeAgent);
    }

    return ref.watch(authenticationServiceProvider).valueOrNull?.user ??
        LocalStorage.nosql.user;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 600;

    final theme = ref.watch(themeServicesProvider);
    final user = _currentUser();

    final bool isEmployee = user?.type == EMPLOYEE_TYPE_NAME;
    final bool isFrontOffice = user?.type == FRONTOFFICE_TYPE_NAME;

    final ordersState = ref.watch(orderServicesProvider);
    final agentsService = ref.watch(agentsServicesProvider);

    final isloading = ordersState is OrdersLoading;
    final iserror = ordersState is OrdersError;

    final waitingOrders = ordersState.orders
        .where((o) => (o['status'] ?? '').toString() == 'Waiting')
        .map((e) => e as Map<String, dynamic>)
        .toList();

    final inServiceOrders = ordersState.orders
        .where((o) => (o['status'] ?? '').toString() == 'In-Service')
        .map((e) => e as Map<String, dynamic>)
        .toList();

    final completedOrders = ordersState.orders
        .where((o) => (o['status'] ?? '').toString() == 'Complete')
        .map((e) => e as Map<String, dynamic>)
        .toList();

    final employeeSearchOrders = [...inServiceOrders, ...completedOrders];

    return Scaffold(
      backgroundColor: venaBg,
      appBar: isSmallScreen
          ? AppBar(
              elevation: 0,
              backgroundColor: venaBg,
              foregroundColor: venaDark,
              titleSpacing: 14,
              title: _dateButton(theme),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: venaDark),
                  onPressed: () {
                    showSearch(
                      context: context,
                      useRootNavigator: false,
                      delegate: OrderSearch(
                        orders: isEmployee
                            ? employeeSearchOrders
                            : ordersState.orders,
                        user: user,
                        theme: theme,
                        ref: ref,
                      ),
                    );
                  },
                ),
              ],
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
        child: Column(
          children: [
            if (!isSmallScreen)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                child: _desktopHeader(
                  theme: theme,
                  user: user,
                  ordersState: ordersState,
                  isEmployee: isEmployee,
                  employeeSearchOrders: employeeSearchOrders,
                ),
              ),
            if (isloading)
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: LinearProgressIndicator(
                  color: venaTeal,
                  backgroundColor: Color(0xffD8F4F8),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 12 : 24,
                isSmallScreen ? 12 : 18,
                isSmallScreen ? 12 : 24,
                0,
              ),
              child: _statusSwitch(
                isloading: isloading,
                firstOrders: isEmployee ? inServiceOrders : waitingOrders,
                secondOrders: isEmployee ? completedOrders : inServiceOrders,
                isEmployee: isEmployee,
              ),
            ),
            if (isdesktop() && !iserror && !isloading)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: () async {
                    if (!mounted) return;
                    setState(() => dateBtn = 'Today');
                    await _refreshOrders();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: venaTeal,
                    backgroundColor: Colors.white.withOpacity(0.70),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(color: venaLine),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Refresh Orders',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 12 : 24,
                  12,
                  isSmallScreen ? 12 : 24,
                  18,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 1000
                        ? 3
                        : constraints.maxWidth > 650
                        ? 2
                        : 1;

                    final aspectRatio = constraints.maxWidth > 1000
                        ? 1.72
                        : constraints.maxWidth > 650
                        ? 1.50
                        : 1.35;

                    if (isloading) return const SizedBox();

                    final ordersToShow = isEmployee
                        ? (isWaitingSelected
                              ? inServiceOrders
                              : completedOrders)
                        : (isWaitingSelected ? waitingOrders : inServiceOrders);

                    final emptyStateText = isEmployee
                        ? (isWaitingSelected
                              ? 'No In-Service Orders'
                              : 'No Completed Orders')
                        : (isWaitingSelected
                              ? 'No Unassigned Orders'
                              : 'No Assigned Orders');

                    String? errorMessage;
                    if (ordersState is OrdersError) {
                      errorMessage = ordersState.error;
                    }

                    return RefreshIndicator(
                      color: venaTeal,
                      onRefresh: _refreshOrders,
                      child: ordersToShow.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 100),
                                emptyState(
                                  ref,
                                  text: errorMessage ?? emptyStateText,
                                  onRefresh: _refreshOrders,
                                ),
                              ],
                            )
                          : GridView.builder(
                              padding: EdgeInsets.zero,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: aspectRatio,
                                  ),
                              itemCount: ordersToShow.length,
                              itemBuilder: (context, index) {
                                final order = ordersToShow[index];

                                return _buildOrderCard(
                                  order,
                                  context,
                                  false,
                                  false,
                                  isWaitingSelected,
                                  agentsService,
                                  theme,
                                  isEmployee,
                                  isFrontOffice,
                                );
                              },
                            ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktopHeader({
    required ThemeConfig theme,
    required ServiceUser? user,
    required OrdersState ordersState,
    required bool isEmployee,
    required List<Map<String, dynamic>> employeeSearchOrders,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: venaLine),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: venaTeal.withOpacity(0.10),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: venaTeal.withOpacity(0.25)),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: venaTeal,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ORDER QUEUE',
                  style: TextStyle(
                    color: venaDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.storeName ?? 'Vena Studio',
                  style: const TextStyle(
                    color: venaMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 4, child: _dateButton(theme)),
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              showSearch(
                context: context,
                useRootNavigator: false,
                delegate: OrderSearch(
                  orders: isEmployee
                      ? employeeSearchOrders
                      : ordersState.orders,
                  user: user,
                  theme: theme,
                  ref: ref,
                ),
              );
            },
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: venaBg.withOpacity(0.75),
                borderRadius: BorderRadius.zero,
                border: Border.all(color: venaLine),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: venaDark,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateButton(ThemeConfig theme) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: Colors.white.withOpacity(0.85),
          foregroundColor: venaDark,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: venaLine),
          ),
        ),
        onPressed: () async {
          final value = await showDateRangePicker(
            useRootNavigator: SrceenType.type(context.sz).isMobile,
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2090),
            builder: (context, child) {
              final baseTheme = ThemeData.light();

              return Theme(
                data: baseTheme.copyWith(
                  primaryColor: venaTeal,
                  scaffoldBackgroundColor: venaBg,
                  dialogBackgroundColor: Colors.white,
                  colorScheme: baseTheme.colorScheme.copyWith(
                    primary: venaTeal,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: venaDark,
                  ),
                  datePickerTheme: baseTheme.datePickerTheme.copyWith(
                    rangeSelectionBackgroundColor: venaTeal.withOpacity(0.18),
                    rangeSelectionOverlayColor: MaterialStateProperty.all(
                      venaTeal.withOpacity(0.14),
                    ),
                  ),
                ),
                child: child!,
              );
            },
          );

          if (!mounted) return;

          if (value != null) {
            final startStr = DateFormat.yMMMEd().format(value.start);
            final endStr = DateFormat.yMMMEd().format(value.end);

            setState(() {
              dateBtn = '$startStr   -   $endStr';
            });

            final notifier = ref.read(orderServicesProvider.notifier);
            await notifier.init(range: (value.start, value.end));

            if (!mounted) return;
          }
        },
        icon: const Icon(Icons.date_range_rounded, size: 18),
        label: Text(
          dateBtn,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
      ),
    );
  }

  Widget _statusSwitch({
    required bool isloading,
    required List<Map<String, dynamic>> firstOrders,
    required List<Map<String, dynamic>> secondOrders,
    required bool isEmployee,
  }) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: venaLine),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statusTab(
              title: isEmployee ? 'In-Service' : 'Unassigned',
              count: firstOrders.length,
              isActive: isWaitingSelected,
              showCount: !isloading && firstOrders.isNotEmpty,
              onTap: () {
                if (!mounted) return;
                setState(() => isWaitingSelected = true);
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _statusTab(
              title: isEmployee ? 'Completed' : 'Assigned',
              count: secondOrders.length,
              isActive: !isWaitingSelected,
              showCount: !isloading && secondOrders.isNotEmpty,
              onTap: () {
                if (!mounted) return;
                setState(() => isWaitingSelected = false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTab({
    required String title,
    required int count,
    required bool isActive,
    required bool showCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: isActive ? venaTeal : Colors.transparent,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: isActive ? venaTeal : Colors.transparent),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : venaMuted,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (showCount)
              Positioned(
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : venaTeal.withOpacity(0.12),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: isActive
                          ? Colors.white
                          : venaTeal.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isActive ? venaTeal : venaDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    Map<String, dynamic> order,
    BuildContext context,
    bool readonly,
    bool insearch,
    bool isWaitingSelected,
    AsyncValue<List<Agent>> agentsService,
    ThemeConfig theme,
    bool isEmployee,
    bool isFrontOffice,
  ) {
    final billNo = (order['billno'] ?? 'Unknown').toString().split('(').first;
    final amount = (num.tryParse(order['amount'].toString()) ?? 0).toDouble();
    final agentName = order['agentname']?.toString() ?? '';
    final receipt = order['receipt']?.toString() ?? 'N/A';

    final dateText = order['date'] != null
        ? DateFormat.yMMMEd().format(
            DateTime.tryParse(order['date'].toString()) ?? DateTime.now(),
          )
        : 'No Date';

    final status = (order['status'] ?? '').toString();
    final canComplete = status == 'In-Service';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: venaLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: venaTeal.withOpacity(0.10),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: venaTeal.withOpacity(0.25)),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: venaTeal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bill No: $billNo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: venaDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _orderInfoRow(
              icon: Icons.payments_outlined,
              label: 'Amount',
              value: amount.money,
              highlight: true,
            ),
            const SizedBox(height: 7),
            if (agentName.isNotEmpty) ...[
              _orderInfoRow(
                icon: Icons.person_outline_rounded,
                label: 'Agent',
                value: agentName,
              ),
              const SizedBox(height: 7),
            ],
            _orderInfoRow(
              icon: Icons.confirmation_number_outlined,
              label: 'Receipt',
              value: receipt,
            ),
            const SizedBox(height: 7),
            _orderInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: dateText,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      OrderView.show(
                        context,
                        order['id'],
                        readonly: readonly || !isFrontOffice,
                        insearch: insearch,
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: venaBg,
                      foregroundColor: venaDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(color: venaLine),
                      ),
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!readonly && canComplete && isFrontOffice)
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if (insearch && Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }

                        if (!mounted) return;

                        context.go('/orders/complete/${order['id']}');
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: venaTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Complete',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 7),
                          Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!readonly && isFrontOffice && status == 'Waiting')
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        await _assignOrderAgent(
                          order: order,
                          agentsService: agentsService,
                          theme: theme,
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: venaTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Assign',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 7),
                          Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignOrderAgent({
    required Map<String, dynamic> order,
    required AsyncValue<List<Agent>> agentsService,
    required ThemeConfig theme,
  }) async {
    if (agentsService is! AsyncData<List<Agent>>) return;

    final agents = (agentsService.value ?? [])
        .where((element) => !element.archived)
        .toList();

    final value = await PickAgent.show(context, agents);

    if (!mounted) return;
    if (value == null) return;

    context.loading;

    try {
      final notifier = ref.read(orderServicesProvider.notifier);

      await notifier.assignAgent(
        agent: value,
        billno: order['billno'],
        orderid: order['id'],
      );

      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      showOrderSnack(context, '${value.name} assigned to order');
    } catch (_) {
      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      showOrderSnack(context, 'Failed to assign agent', error: true);
    }
  }

  Widget _orderInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: highlight ? venaTeal : venaMuted),
        const SizedBox(width: 7),
        Text(
          '$label:',
          style: const TextStyle(
            color: venaMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highlight ? venaTeal : venaDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
