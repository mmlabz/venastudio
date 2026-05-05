import 'package:intl/intl.dart';
import 'package:venastudio/common.dart';

class BookedOrdersPage extends ConsumerStatefulWidget {
  const BookedOrdersPage({super.key});

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  static Widget orderDetails(
    Map<dynamic, dynamic> order, {
    VoidCallback? onTap,
    bool showDate = true,
    required ThemeConfig theme,
  }) {
    final amount = (num.tryParse(order['amount'].toString()) ?? 0).toDouble();
    final endTime = DateTime.tryParse(order['endTime']?.toString() ?? '');

    return InkWell(
      onTap: onTap,
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
                const Icon(Icons.event_available_rounded, color: venaTeal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order['billno']?.toString() ?? '',
                    style: const TextStyle(
                      color: venaDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  amount.money,
                  style: const TextStyle(
                    color: venaTeal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _staticRow('Payment', order['type']),
            _staticRow('Ticket', order['receipt']),
            _staticRow('Completed By', order['agentname']),
            if (showDate)
              _staticRow(
                'Completed On',
                DateFormat.yMMMd().format(endTime ?? DateTime.now()),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _staticRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: venaMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '',
              style: const TextStyle(
                color: venaDark,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  ConsumerState<BookedOrdersPage> createState() => _BookedOrdersPageState();
}

class _BookedOrdersPageState extends ConsumerState<BookedOrdersPage> {
  String dateBtn = 'Today';
  (DateTime, DateTime)? range;
  bool showDate = true;

  static const Color venaBg = BookedOrdersPage.venaBg;
  static const Color venaTeal = BookedOrdersPage.venaTeal;
  static const Color venaDark = BookedOrdersPage.venaDark;
  static const Color venaMuted = BookedOrdersPage.venaMuted;
  static const Color venaLine = BookedOrdersPage.venaLine;

  @override
  Widget build(BuildContext context) {
    final bookedOrdersService = ref.watch(bookedOrderServicesProvider);
    final agentsService = ref.watch(agentsServicesProvider);
    final theme = ref.watch(themeServicesProvider);

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
          'Booked Orders',
          style: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: venaDark),
            onPressed: () {
              showSearch(
                context: context,
                useRootNavigator: false,
                delegate: BookedOrdersSearch(
                  orders: bookedOrdersService.value ?? [],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffF8FDFF), Color(0xffEEF9FB), Color(0xffE4F7FA)],
          ),
        ),
        child: Column(
          children: [
            _filterButton(),
            Expanded(
              child: bookedOrdersService.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: venaTeal),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (data) {
                  if (data.isEmpty) {
                    return emptyState(
                      ref,
                      text: 'No Booked Orders',
                      onRefresh: () =>
                          ref.invalidate(bookedOrderServicesProvider),
                    );
                  }

                  return RefreshIndicator(
                    color: venaTeal,
                    onRefresh: () async {
                      ref.invalidate(bookedOrderServicesProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final order = data[index];

                        return BookedOrdersPage.orderDetails(
                          order,
                          showDate: true,
                          theme: theme,
                          onTap: () => showOrderDetails(
                            order['orderItems'] as List<dynamic>,
                            order['billno'].toString(),
                            order['id'] as int,
                            DateTime.tryParse(
                              order['endTime'] as String? ?? '',
                            ),
                            agentsService,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SizedBox(
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
                    .read(bookedOrderServicesProvider.notifier)
                    .init(range: (value.start, value.end));
              }
            });
          },
          label: Text(
            dateBtn,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: venaDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showOrderDetails(
    List<dynamic> details,
    String bill,
    int orderid,
    DateTime? end,
    AsyncValue<List<Agent>> agentsService,
  ) {
    return showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        final size = context.sz;
        final maxWidth = getMaxWidth(size.width);

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: maxWidth,
              child: Material(
                color: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: venaLine),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: venaLine)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                bill,
                                style: const TextStyle(
                                  color: venaDark,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: venaDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: size.height / 2,
                          minHeight: 100,
                        ),
                        child: ListView.builder(
                          itemCount: details.length,
                          padding: const EdgeInsets.all(14),
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final item = details[index] as Map<String, dynamic>;

                            final price =
                                (num.tryParse(item['price'].toString()) ?? 0)
                                    .toDouble();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: venaBg.withOpacity(0.65),
                                border: Border.all(color: venaLine),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['agent']?.toString() ?? '',
                                    style: const TextStyle(
                                      color: venaDark,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['name']?.toString() ?? '',
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
                                  const SizedBox(height: 4),
                                  Text(
                                    'Quantity: ${item['items']}',
                                    style: const TextStyle(
                                      color: venaMuted,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
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
}

class BookedOrdersSearch extends SearchDelegate {
  BookedOrdersSearch({required this.orders});

  final List<Map<dynamic, dynamic>> orders;

  static const Color venaBg = BookedOrdersPage.venaBg;
  static const Color venaTeal = BookedOrdersPage.venaTeal;
  static const Color venaDark = BookedOrdersPage.venaDark;
  static const Color venaMuted = BookedOrdersPage.venaMuted;
  static const Color venaLine = BookedOrdersPage.venaLine;

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
  Widget buildResults(BuildContext context) => _buildOutput(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildOutput(context);

  Widget _buildOutput(BuildContext context) {
    final searched = orders.where((element) {
      return element['agentname'].toString().toLowerCase().contains(
            query.toLowerCase(),
          ) ||
          element['billno'].toString().toLowerCase().contains(
            query.toLowerCase(),
          ) ||
          element['receipt'].toString().toLowerCase().contains(
            query.toLowerCase(),
          );
    }).toList();

    return Container(
      color: venaBg,
      child: searched.isEmpty
          ? const Center(
              child: Text(
                'No booked order found',
                style: TextStyle(color: venaMuted, fontWeight: FontWeight.w800),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: searched.length,
              itemBuilder: (context, index) {
                final order = searched[index];

                return BookedOrdersPage.orderDetails(
                  order,
                  showDate: true,
                  theme: ProviderScope.containerOf(
                    context,
                  ).read(themeServicesProvider),
                );
              },
            ),
    );
  }
}
