import 'package:venastudio/common.dart';

void showOrderViewSnack(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);

  if (messenger == null) {
    debugPrint('ORDER VIEW SNACK MISSED: $message');
    return;
  }

  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red : Colors.black87,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

void closeOrderDialogSafely(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);

  if (navigator.canPop()) {
    navigator.pop();
  }
}

void logOrderViewError(
  String label,
  Object error,
  StackTrace stackTrace,
) {
  debugPrint('================ $label ================');
  debugPrint('ERROR TYPE: ${error.runtimeType}');
  debugPrint('ERROR: $error');
  debugPrintStack(stackTrace: stackTrace);
  debugPrint('====================================================');
}

class OrderView extends ConsumerWidget {
  const OrderView({
    super.key,
    required this.id,
    required this.readonly,
    required this.insearch,
  });

  final num id;
  final bool readonly;
  final bool insearch;

  static Future<T?> show<T>(
    BuildContext context,
    num id, {
    bool readonly = false,
    bool insearch = false,
  }) {
    return showDialog<T>(
      context: context,
      useRootNavigator: SrceenType.type(context.sz).isMobile,
      builder: (_) {
        return OrderView(
          id: id,
          readonly: readonly,
          insearch: insearch,
        );
      },
    );
  }

  ServiceUser? _currentUser(WidgetRef ref) {
    final activeAgent = LocalStorage.nosql.activeAgent;

    if (activeAgent != null) {
      return ServiceUser.fromMap(activeAgent);
    }

    return ref.watch(authenticationServiceProvider).valueOrNull?.user ??
        LocalStorage.nosql.user;
  }

  bool _isInService(dynamic order) {
    return order['status']?.toString() == 'In-Service';
  }

  List<dynamic> _addonsOf(dynamic item) {
    final addons = item['addons'];

    if (addons is List) {
      return addons;
    }

    return const [];
  }

  Future<void> _assignServiceAgent({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic order,
    required dynamic item,
    required dynamic value,
    required bool smartControlsEnabled,
  }) async {
    try {
      debugPrint(
        'ASSIGN SINGLE SMART PAYLOAD => '
        'order=${order['billno']}, '
        'cartid=${item['cartid']}, '
        'agentId=${value.agent.id}, '
        'agentName=${value.agent.name}',
      );

      if (smartControlsEnabled) {
        await ref.read(orderServicesProvider.notifier).assignSingleSmart(
              result: value,
              order: order['billno'],
              cartid: item['cartid'].toString(),
            );
      } else {
        await ref.read(orderServicesProvider.notifier).assignSingleAgent(
              agent: value.agent,
              order: order['billno'],
              cartid: item['cartid'].toString(),
            );
      }

      ref.invalidate(orderServicesProvider);

      if (!context.mounted) return;

      showOrderViewSnack(
        context,
        '${value.agent.name} assigned to service',
      );

      closeOrderDialogSafely(context);
    } catch (error, stackTrace) {
      logOrderViewError(
        'ASSIGN SERVICE AGENT ERROR',
        error,
        stackTrace,
      );

      if (!context.mounted) return;

      showOrderViewSnack(
        context,
        'Failed to assign agent. Check console logs.',
        error: true,
      );
    }
  }

  Future<void> _reassignWholeOrder({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic order,
    required dynamic value,
  }) async {
    try {
      debugPrint(
        'REASSIGN ORDER PAYLOAD => '
        'order=${order['billno']}, '
        'orderid=${order['id']}, '
        'agentId=${value.id}, '
        'agentName=${value.name}',
      );

      await ref.read(orderServicesProvider.notifier).assignAgent(
            agent: value,
            billno: order['billno'],
            orderid: order['id'],
          );

      ref.invalidate(orderServicesProvider);

      if (!context.mounted) return;

      showOrderViewSnack(
        context,
        '${value.name} assigned to order',
      );

      closeOrderDialogSafely(context);
    } catch (error, stackTrace) {
      logOrderViewError(
        'REASSIGN WHOLE ORDER ERROR',
        error,
        stackTrace,
      );

      if (!context.mounted) return;

      showOrderViewSnack(
        context,
        'Failed to reassign order. Check console logs.',
        error: true,
      );
    }
  }

  Future<void> _removeAddon({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic order,
    required dynamic item,
    required dynamic addon,
  }) async {
    try {
      await ref.read(orderServicesProvider.notifier).removeAddon(
            order: order['billno'],
            cartid: item['cartid'].toString(),
            addonid: addon['id'].toString(),
          );

      ref.invalidate(orderServicesProvider);

      if (!context.mounted) return;

      showOrderViewSnack(context, 'Addon removed');
      closeOrderDialogSafely(context);
    } catch (error, stackTrace) {
      logOrderViewError(
        'REMOVE ADDON ERROR',
        error,
        stackTrace,
      );

      if (!context.mounted) return;

      showOrderViewSnack(
        context,
        'Failed to remove addon',
        error: true,
      );
    }
  }

  Future<void> _rescheduleOrder({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic order,
  }) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      initialDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime(2030),
    );

    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null || !context.mounted) return;

    final newDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    try {
      await ref.read(orderServicesProvider.notifier).rescheduleOrder(
            date: newDate,
            order: order['billno'],
          );

      ref.invalidate(orderServicesProvider);

      if (!context.mounted) return;

      showOrderViewSnack(
        context,
        'Order rescheduled to ${sDate3(newDate)}',
      );

      closeOrderDialogSafely(context);
    } catch (error, stackTrace) {
      logOrderViewError(
        'RESCHEDULE ORDER ERROR',
        error,
        stackTrace,
      );

      if (!context.mounted) return;

      showOrderViewSnack(
        context,
        'Error rescheduling',
        error: true,
      );
    }
  }

  void _goToUpdateOrder(BuildContext context, dynamic order) {
    final orderId = order['id'];

    closeOrderDialogSafely(context);

    Future.microtask(() {
      if (context.mounted) {
        context.push('/orders/update_order/$orderId');
      }
    });
  }

  void _goToAddAddon(BuildContext context, dynamic order, dynamic item) {
    final orderId = order['id'];
    final itemId = item['id'];

    closeOrderDialogSafely(context);

    Future.microtask(() {
      if (context.mounted) {
        context.push('/orders/add_addons/$orderId/$itemId');
      }
    });
  }

  void _goToAddService(BuildContext context, dynamic order) {
    final orderId = order['id'];

    closeOrderDialogSafely(context);

    Future.microtask(() {
      if (context.mounted) {
        context.push('/orders/add_service/$orderId');
      }
    });
  }

  Future<void> _pickAndAssignServiceAgent({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic order,
    required dynamic item,
    required dynamic settingsService,
    required List<Agent> agents,
  }) async {
    final value = await SmartAssignmentBridge.pickResult(
      context,
      settings: settingsService,
      agents: agents,
      serviceLike: item,
      orderNo: '${order['billno'] ?? ''}',
      cartId: '${item['cartid'] ?? ''}',
      existingOrderMode: true,
    );

    if (value == null || !context.mounted) return;

    await _assignServiceAgent(
      context: context,
      ref: ref,
      order: order,
      item: item,
      value: value,
      smartControlsEnabled: SmartAssignmentBridge.enabled(settingsService),
    );
  }

  Future<void> _pickAndReassignWholeOrder({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic order,
    required dynamic settingsService,
    required List<Agent> agents,
  }) async {
    final value = await SmartAssignmentBridge.pickAgent(
      context,
      settings: settingsService,
      agents: agents,
      serviceLike: order,
      orderNo: '${order['billno'] ?? ''}',
      cartId: '${order['id'] ?? ''}',
      existingOrderMode: true,
    );

    if (value == null || !context.mounted) return;

    await _reassignWholeOrder(
      context: context,
      ref: ref,
      order: order,
      value: value,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeServicesProvider);
    final allorders = ref.watch(orderServicesProvider);
    final agentsService = ref.watch(agentsServicesProvider);
    final settingsService = ref.watch(settingsServicesProvider);
    final user = _currentUser(ref);

    final bool isFrontOffice = user?.type == FRONTOFFICE_TYPE_NAME;
    final bool canManageOrder = isFrontOffice && !readonly;

    final order = allorders.orders.where((element) {
      return element['id'] == id;
    }).firstOrNull;

    if (order == null) {
      return noorder(ref, theme);
    }

    final size = context.sz;
    final maxWidth = getMaxWidth(size.width);
    final items = List<dynamic>.from(order['orderItems'] ?? const []);

    final bool showReassign =
        _isInService(order) && canManageOrder && !settingsService.trackStock;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: maxWidth,
          child: Container(
            decoration: BoxDecoration(
              color: theme.activeTextIconColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            order['billno']?.toString() ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.defultColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        IconButton(
                          onPressed: () => closeOrderDialogSafely(context),
                          icon: Icon(
                            Icons.close,
                            color: theme.defultColor,
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
                    child: items.isNotEmpty
                        ? ListView.builder(
                            itemCount: items.length,
                            padding: const EdgeInsets.all(14),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final addons = _addonsOf(item);

                              return Card(
                                color: theme.inactiveTextIconColor,
                                clipBehavior: Clip.hardEdge,
                                child: ExpansionTile(
                                  title: _orderTitle(
                                    item,
                                    theme,
                                    addons,
                                  ),
                                  children: [
                                    if (addons.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.all(16),
                                        alignment: Alignment.centerLeft,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            left: BorderSide(
                                              width: 2,
                                              color:
                                                  theme.inactiveTextIconColor,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: addons.map((addon) {
                                            return ListTile(
                                              title: Text(
                                                '${addon['name']} ~> ${addon['agent']}',
                                              ),
                                              subtitle: Text(
                                                (num.tryParse(
                                                          addon['price']
                                                              .toString(),
                                                        ) ??
                                                        0)
                                                    .toDouble()
                                                    .money,
                                              ),
                                              trailing: canManageOrder
                                                  ? IconButton(
                                                      onPressed: () {
                                                        _removeAddon(
                                                          context: context,
                                                          ref: ref,
                                                          order: order,
                                                          item: item,
                                                          addon: addon,
                                                        );
                                                      },
                                                      icon: const Icon(
                                                        Icons.close,
                                                      ),
                                                    )
                                                  : null,
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    if (canManageOrder)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () async {
                                                  if (agentsService
                                                      is! AsyncData) {
                                                    showOrderViewSnack(
                                                      context,
                                                      'Agents are still loading',
                                                      error: true,
                                                    );
                                                    return;
                                                  }

                                                  final agents =
                                                      agentsService.value ?? [];

                                                  await _pickAndAssignServiceAgent(
                                                    context: context,
                                                    ref: ref,
                                                    order: order,
                                                    item: item,
                                                    settingsService:
                                                        settingsService,
                                                    agents: agents,
                                                  );
                                                },
                                                child: Text(
                                                  'Assign',
                                                  style: TextStyle(
                                                    color: theme.defultColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () {
                                                  _goToAddAddon(
                                                    context,
                                                    order,
                                                    item,
                                                  );
                                                },
                                                child: Text(
                                                  'Addon +',
                                                  style: TextStyle(
                                                    color: theme.defultColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              'No Items for this order',
                              style: TextStyle(color: theme.defultColor),
                            ),
                          ),
                  ),
                  if (canManageOrder)
                    Padding(
                      padding: EdgeInsets.only(
                        left: 14,
                        right: 14,
                        bottom: showReassign ? 0 : 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                _goToUpdateOrder(context, order);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: theme.primaryBackGround,
                                side: BorderSide(
                                  color: theme.primaryBackGround,
                                ),
                                fixedSize: const Size(double.maxFinite, 20),
                              ),
                              child: const Text('UPDATE'),
                            ),
                          ),
                          if (showReassign) const SizedBox(width: 10),
                          if (showReassign)
                            Expanded(
                              child: TextButton(
                                onPressed: () async {
                                  if (agentsService is! AsyncData) {
                                    showOrderViewSnack(
                                      context,
                                      'Agents are still loading',
                                      error: true,
                                    );
                                    return;
                                  }

                                  final agents =
                                      (agentsService.value ?? []).cast<Agent>();

                                  await _pickAndReassignWholeOrder(
                                    context: context,
                                    ref: ref,
                                    order: order,
                                    settingsService: settingsService,
                                    agents: agents,
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.primaryBackGround,
                                  side: BorderSide(
                                    color: theme.primaryBackGround,
                                  ),
                                  fixedSize: const Size(double.maxFinite, 20),
                                ),
                                child: const Text('RE-ASSIGN'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (canManageOrder)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: 16,
                      ),
                      child: TextButton(
                        onPressed: () {
                          _rescheduleOrder(
                            context: context,
                            ref: ref,
                            order: order,
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: theme.primaryBackGround,
                          side: BorderSide(color: theme.primaryBackGround),
                          fixedSize: const Size(double.maxFinite, 20),
                        ),
                        child: const Text('Re - Schedule'),
                      ),
                    ),
                  if (_isInService(order) && canManageOrder)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      child: TextButton(
                        onPressed: () {
                          _goToAddService(context, order);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: theme.primaryBackGround,
                          foregroundColor: theme.activeTextIconColor,
                          fixedSize: const Size(double.maxFinite, 20),
                        ),
                        child: const Text('Add Service'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Column _orderTitle(
    dynamic item,
    ThemeConfig theme,
    List<dynamic> addons,
  ) {
    final rawAgentName = item['agent']?.toString() ?? '';
    final agentName = rawAgentName.trim().isNotEmpty ? rawAgentName : '___ ___';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '👤 $agentName',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name']?.toString() ?? '',
                    maxLines: 3,
                    style: TextStyle(color: theme.defultColor),
                  ),
                  Text(
                    (num.tryParse(item['price'].toString()) ?? 0)
                        .toDouble()
                        .money,
                    style: TextStyle(color: theme.defultColor),
                  ),
                  if ((item['ticket']?.toString() ?? '').isNotEmpty)
                    Text(
                      "Ticket: ${item['ticket']}",
                      style: TextStyle(color: theme.defultColor),
                    ),
                  if ((item['actualDuration']?.toString() ?? '').isNotEmpty)
                    Text(
                      "Time taken: ${item['actualDuration']}",
                      style: TextStyle(color: theme.defultColor),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Quantity: ${item['items'] ?? 0}',
                  style: TextStyle(color: theme.defultColor),
                ),
                Text(
                  'Addons: ${addons.length}',
                  style: TextStyle(color: theme.defultColor),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget noorder(WidgetRef ref, ThemeConfig theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Material(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 200,
                  child: emptyState(ref, text: 'No orders found'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Order Unavailable',
                  style: TextStyle(color: theme.defultColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
