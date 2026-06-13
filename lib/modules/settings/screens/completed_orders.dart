import 'dart:async';
import 'package:intl/intl.dart';
import 'package:venastudio/common.dart';

class CompletedOrdersPage extends ConsumerStatefulWidget {
  const CompletedOrdersPage({super.key});

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);
  static const Color venaSuccess = Color(0xff13A76B);

  static int _safeInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static String _safeString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  static List<dynamic> _safeList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  static Future<void> showOrderDetails({
    required BuildContext context,
    required WidgetRef ref,
    required List<dynamic> details,
    required String bill,
    required int orderid,
    DateTime? end,
    required AsyncValue<List<Agent>> agentsService,
  }) {
    return showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        final size = context.sz;
        final maxWidth = getMaxWidth(size.width);
        final theme = ref.watch(themeServicesProvider);
        final settingsService = ref.watch(settingsServicesProvider);

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: SizedBox(
              width: maxWidth,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.98),
                    border: Border.all(color: venaLine),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(context, bill),
                      _buildOrderList(
                        context,
                        details,
                        size,
                        agentsService,
                        ref,
                        bill,
                        end != null ? (DateTime(0), end) : null,
                        theme,
                        settingsService,
                      ),
                      if (!settingsService.trackStock)
                        _buildReassignButton(
                          ref,
                          context,
                          bill,
                          orderid,
                          agentsService,
                          theme,
                          settingsService,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildHeader(BuildContext context, String bill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xffF8FDFF),
        border: Border(bottom: BorderSide(color: venaLine)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, color: venaTeal, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              bill,
              style: const TextStyle(
                color: venaDark,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.close_rounded, color: venaDark),
          ),
        ],
      ),
    );
  }

  static Widget _buildOrderList(
    BuildContext context,
    List<dynamic> details,
    Size size,
    AsyncValue<List<Agent>> agentsService,
    WidgetRef ref,
    String bill,
    (DateTime start, DateTime end)? range,
    ThemeConfig theme,
    SettingsConfig settingsService,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size.height / 2, minHeight: 120),
      child: ListView.builder(
        itemCount: details.length,
        padding: const EdgeInsets.all(14),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final item = details[index] as Map<String, dynamic>;
          final addons = item['addons'] as List<dynamic>? ?? [];
          final orderId = _safeInt(item['orderid']);

          return addons.isNotEmpty
              ? _buildAddonExpansionTile(item, addons)
              : _buildOrderCard(
                  agentsService,
                  context,
                  ref,
                  bill,
                  orderId,
                  item,
                  range,
                  theme,
                  settingsService,
                );
        },
      ),
    );
  }

  static Widget _buildAddonExpansionTile(
    Map<String, dynamic> item,
    List<dynamic> addons,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: venaLine),
      ),
      child: ExpansionTile(
        iconColor: venaTeal,
        collapsedIconColor: venaMuted,
        title: Text(
          item['agent'] ?? '',
          style: const TextStyle(color: venaDark, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${item['name']} x ${item['items']} • ${(num.tryParse(item['price'].toString()) ?? 0).toDouble().money}',
          style: const TextStyle(color: venaMuted, fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        children: addons.map((addon) {
          return _buildAddonCard(Map<String, dynamic>.from(addon));
        }).toList(),
      ),
    );
  }

  static Widget _buildAddonCard(Map<String, dynamic> addon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: venaBg.withOpacity(0.70),
        border: Border.all(color: venaLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            addon['agent']?.toString() ?? '',
            style: const TextStyle(
              color: venaDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            addon['name']?.toString() ?? '',
            style: const TextStyle(
              color: venaMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            (num.tryParse(addon['price'].toString()) ?? 0).toDouble().money,
            style: const TextStyle(
              color: venaTeal,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildOrderCard(
    AsyncValue<List<Agent>> agentsService,
    BuildContext context,
    WidgetRef ref,
    String bill,
    int orderid,
    Map<String, dynamic> item,
    (DateTime start, DateTime end)? range,
    ThemeConfig theme,
    SettingsConfig settingsService,
  ) {
    final price = (num.tryParse(item['price'].toString()) ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: venaLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['agent'] ?? '',
            style: const TextStyle(
              color: venaDark,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  item['name'] ?? '',
                  style: const TextStyle(
                    color: venaMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                price.money,
                style: const TextStyle(
                  color: venaTeal,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _miniTag('Qty ${item['items']}'),
              const SizedBox(width: 8),
              _miniTag('Addons ${item['addons'].length}'),
              const Spacer(),
              TextButton(
                onPressed: () {
                  onReassignSingle(
                    agentsService,
                    context,
                    ref,
                    bill,
                    orderid,
                    item,
                    range,
                    theme,
                    settingsService,
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: venaTeal,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Re-Assign',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _miniTag(String text) {
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

  static Widget _buildReassignButton(
    WidgetRef ref,
    BuildContext context,
    String bill,
    int orderid,
    AsyncValue<List<Agent>> agentsService,
    ThemeConfig theme,
    SettingsConfig settingsService,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: venaLine)),
      ),
      child: SizedBox(
        height: 44,
        width: double.infinity,
        child: TextButton(
          onPressed: () {
            onReassign(agentsService, context, ref, bill, orderid, theme, settingsService);
          },
          style: TextButton.styleFrom(
            backgroundColor: venaTeal,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          child: const Text(
            'RE-ASSIGN ORDER',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  static void onReassign(
    AsyncValue<List<Agent>> agentsService,
    BuildContext context,
    WidgetRef ref,
    String bill,
    int orderid,
    ThemeConfig theme,
    SettingsConfig settingsService,
  ) {
    if (agentsService is AsyncData) {
      final agents = agentsService.value ?? [];
      SmartAssignmentBridge.pickAgent(
        context,
        settings: settingsService,
        agents: agents,
        serviceLike: const {'id': 0, 'name': 'Completed Order'},
        orderNo: bill,
        existingOrderMode: true,
      ).then((value) {
        if (value != null) {
          context.loading;
          ref
              .read(completedOrderServicesProvider.notifier)
              .assignAgent(agent: value, billno: bill, orderid: orderid)
              .then((_) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                context.showToast(
                  '${value.name} assigned to order',
                  textColor: theme.textIconPrimaryColor,
                );
              })
              .onError((error, stackTrace) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
        }
      });
    }
  }

  static void onReassignSingle(
    AsyncValue<List<Agent>> agentsService,
    BuildContext context,
    WidgetRef ref,
    String bill,
    int orderid,
    Map<String, dynamic> item,
    (DateTime start, DateTime end)? range,
    ThemeConfig theme,
    SettingsConfig settingsService,
  ) {
    if (agentsService is AsyncData) {
      final agents = agentsService.value ?? [];
      final useagents = agents.where((element) => !element.archived).toList();

      SmartAssignmentBridge.pickAgent(
        context,
        settings: settingsService,
        agents: useagents,
        serviceLike: item,
        orderNo: bill,
        cartId: '${item['cartid'] ?? ''}',
        existingOrderMode: true,
      ).then((value) {
        if (value != null) {
          context.loading;
          ref
              .read(completedOrderServicesProvider.notifier)
              .assignAgentSingle(
                agent: value,
                billno: bill,
                orderid: orderid,
                cartid: '${item['cartid']}',
                range: range,
              )
              .then((_) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                context.showToast(
                  '${value.name} assigned to order',
                  textColor: theme.textIconPrimaryColor,
                );
              })
              .onError((error, stackTrace) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
        }
      });
    }
  }

  @override
  ConsumerState<CompletedOrdersPage> createState() =>
      _CompletedOrdersPageState();
}

class _CompletedOrdersPageState extends ConsumerState<CompletedOrdersPage> {
  TextEditingController searchController = TextEditingController();

  String dateBtn = 'Today';
  (DateTime, DateTime)? range;

  bool showDate = true;
  String sortBy = "date";
  bool ascending = true;
  DateTime? fromDate, toDate;

  static const Color venaBg = CompletedOrdersPage.venaBg;
  static const Color venaTeal = CompletedOrdersPage.venaTeal;
  static const Color venaDark = CompletedOrdersPage.venaDark;
  static const Color venaMuted = CompletedOrdersPage.venaMuted;
  static const Color venaLine = CompletedOrdersPage.venaLine;
  static const Color venaDanger = CompletedOrdersPage.venaDanger;
  static const Color venaSuccess = CompletedOrdersPage.venaSuccess;

  @override
  void initState() {
    super.initState();
    ascending = false;
    fetchOrders();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void fetchOrders() {
    ref.read(completedOrderServicesProvider.notifier).init();
  }

  List<Map<String, dynamic>> get filteredOrders {
    final orders = ref.watch(completedOrderServicesProvider).value ?? [];

    final sortedList = List<Map<String, dynamic>>.from(
      orders.where((order) {
        final agent = order["agentname"]?.toString().toLowerCase() ?? '';
        final matchesSearch = agent.contains(
          searchController.text.toLowerCase(),
        );

        bool matchesDate = true;
        if (fromDate != null && toDate != null) {
          final orderDate = DateTime.parse(order["date"]);
          matchesDate =
              orderDate.isAfter(fromDate!.subtract(const Duration(days: 1))) &&
              orderDate.isBefore(toDate!.add(const Duration(days: 1)));
        }

        return matchesSearch && matchesDate;
      }),
    );

    sortedList.sort((a, b) {
      dynamic aValue = a[sortBy];
      dynamic bValue = b[sortBy];

      if (sortBy == "date" && aValue is String && bValue is String) {
        aValue = DateTime.parse(aValue);
        bValue = DateTime.parse(bValue);
      }

      return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
    });

    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 600;

    final theme = ref.watch(themeServicesProvider);
    final completedOrdersService = ref.watch(completedOrderServicesProvider);
    final agentsService = ref.watch(agentsServicesProvider);

    return Scaffold(
      backgroundColor: venaBg,
      appBar: AppBar(
        backgroundColor: venaBg,
        foregroundColor: venaDark,
        elevation: 0,
        centerTitle: true,
        leading: context.backIcon(ref, () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/settings');
          }
        }),
        title: const Text(
          'Completed Orders',
          style: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
        ),
        actions: [
          if (!isSmallScreen)
            IconButton(
              onPressed: () {
                ref
                    .read(completedOrderServicesProvider.notifier)
                    .init(range: range);
              },
              icon: const Icon(Icons.refresh_rounded, color: venaDark),
            ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: venaDark),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CompletedOrdersSearch(
                  orders: completedOrdersService.value ?? [],
                  onTap: (order) {
                    CompletedOrdersPage.showOrderDetails(
                      context: context,
                      ref: ref,
                      details: CompletedOrdersPage._safeList(order['orderItems']),
                      bill: CompletedOrdersPage._safeString(order['billno']),
                      orderid: CompletedOrdersPage._safeInt(order['id']),
                      end: DateTime.tryParse(order['endTime'] as String? ?? ''),
                      agentsService: agentsService,
                    );
                  },
                ),
              );
            },
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _dateButton(theme),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _sortBar(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                color: venaTeal,
                onRefresh: () async {
                  ref.invalidate(completedOrderServicesProvider);
                },
                child: completedOrdersService.when(
                  data: (orders) {
                    if (orders.isEmpty) {
                      return emptyState(ref, text: 'No completed orders');
                    }

                    final data = filteredOrders;

                    if (data.isEmpty) {
                      return emptyState(ref, text: 'No matching orders');
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final order = data[index];
                        return _orderCard(order, agentsService);
                      },
                    );
                  },
                  error: (err, stack) => Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(
                        color: venaDanger,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: venaTeal),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateButton(ThemeConfig theme) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white.withOpacity(0.94),
          foregroundColor: venaDark,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: venaLine),
          ),
        ),
        icon: const Icon(Icons.date_range_rounded, size: 18),
        onPressed: () {
          showDateRangePicker(
            useRootNavigator: false,
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
          ).then((value) {
            if (value != null) {
              final startStr = DateFormat.yMMMEd().format(value.start);
              final endStr = DateFormat.yMMMEd().format(value.end);

              setState(() {
                dateBtn = '$startStr   -   $endStr';
                range = (value.start, value.end);
              });

              ref
                  .read(completedOrderServicesProvider.notifier)
                  .init(range: (value.start, value.end));
            }
          });
        },
        label: Text(
          dateBtn,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: venaDark,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _sortBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: Row(
        children: [
          const Icon(Icons.sort_rounded, color: venaMuted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: sortBy,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: venaDark,
                ),
                style: const TextStyle(
                  color: venaDark,
                  fontWeight: FontWeight.w800,
                ),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      sortBy = newValue;
                    });
                  }
                },
                items: ["agentname", "date", "amount"].map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(
                      "Sort by ${value[0].toUpperCase()}${value.substring(1)}",
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                ascending = !ascending;
              });
            },
            child: Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: venaTeal.withOpacity(0.10),
                border: Border.all(color: venaTeal.withOpacity(0.24)),
              ),
              child: Icon(
                ascending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: venaTeal,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderCard(
    Map<String, dynamic> order,
    AsyncValue<List<Agent>> agentsService,
  ) {
    final amount = (num.tryParse(order['amount'].toString()) ?? 0).toDouble();

    return InkWell(
      onTap: () {
        CompletedOrdersPage.showOrderDetails(
          context: context,
          ref: ref,
          details: CompletedOrdersPage._safeList(order['orderItems']),
          bill: CompletedOrdersPage._safeString(order['billno']),
          orderid: CompletedOrdersPage._safeInt(order['id']),
          end: DateTime.tryParse(order['endTime'] as String? ?? ''),
          agentsService: agentsService,
        );
      },
      child: Container(
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
                    order['billno']?.toString() ?? '',
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
                  amount.money,
                  style: const TextStyle(
                    color: venaTeal,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.person_outline_rounded, order['agentname']),
            _infoRow(Icons.payment_rounded, 'Payment: ${order['type']}'),
            _infoRow(
              Icons.confirmation_number_outlined,
              'Ticket: ${order['receipt']}',
            ),
            _infoRow(
              Icons.verified_user_outlined,
              'Completed by: ${order['completed']}',
            ),
            if (showDate)
              _infoRow(Icons.calendar_today_outlined, order['date']),
            const SizedBox(height: 10),
            Row(
              children: [
                _smallTag('View Details'),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: venaMuted,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: venaMuted),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              value?.toString() ?? '',
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

class CompletedOrdersSearch extends SearchDelegate {
  CompletedOrdersSearch({required this.orders, required this.onTap});

  final List<Map<dynamic, dynamic>> orders;
  final ValueChanged<Map<dynamic, dynamic>> onTap;

  static const Color venaBg = CompletedOrdersPage.venaBg;
  static const Color venaTeal = CompletedOrdersPage.venaTeal;
  static const Color venaDark = CompletedOrdersPage.venaDark;
  static const Color venaMuted = CompletedOrdersPage.venaMuted;
  static const Color venaLine = CompletedOrdersPage.venaLine;
  static const Color venaSuccess = CompletedOrdersPage.venaSuccess;

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: venaBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: venaBg,
        elevation: 0,
        iconTheme: IconThemeData(color: venaDark),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: venaMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: venaLine),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear_rounded),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildOrderList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildOrderList(context);
  }

  Widget _buildOrderList(BuildContext context) {
    final searched = orders.where((element) {
      return element['agentname'].toString().toLowerCase().contains(
            query.toLowerCase(),
          ) ||
          element['billno'].toString().toLowerCase().contains(
            query.toLowerCase(),
          ) ||
          element['customer'].toString().toLowerCase().contains(
            query.toLowerCase(),
          );
    }).toList();

    if (searched.isEmpty) {
      return const Center(
        child: Text(
          'No completed order found',
          style: TextStyle(color: venaMuted, fontWeight: FontWeight.w800),
        ),
      );
    }

    return Container(
      color: venaBg,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: searched.length,
        itemBuilder: (context, index) {
          final order = searched[index];
          final amount = (num.tryParse(order['amount'].toString()) ?? 0)
              .toDouble();

          return InkWell(
            onTap: () => onTap(order),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                border: Border.all(color: venaLine),
              ),
              child: Row(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['billno']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: venaDark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order['agentname']} • ${order['type']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: venaMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    amount.money,
                    style: const TextStyle(
                      color: venaSuccess,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
