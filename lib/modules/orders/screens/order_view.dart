import 'package:venastudio/common.dart';

void showOrderViewSnack(
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

  static show(
    BuildContext context,
    num id, {
    bool readonly = false,
    bool insearch = false,
  }) {
    return showDialog(
      context: context,
      useRootNavigator: SrceenType.type(context.sz).isMobile,
      builder: (_) {
        return OrderView(id: id, readonly: readonly, insearch: insearch);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeServicesProvider);
    final allorders = ref.watch(orderServicesProvider);
    final agentsService = ref.watch(agentsServicesProvider);
    final user = _currentUser(ref);

    final bool isFrontOffice = user?.type == FRONTOFFICE_TYPE_NAME;
    final bool canManageOrder = isFrontOffice && !readonly;

    final order = allorders.orders
        .where((element) => element['id'] == id)
        .firstOrNull;

    if (order == null) {
      return noorder(ref, theme);
    }

    final size = context.sz;
    final maxWidth = getMaxWidth(size.width);
    final items = List.from(order['orderItems'] ?? []);

    final bool showReassign = order['status'] == 'In-Service' && canManageOrder;

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
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: Icon(Icons.close, color: theme.defultColor),
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

                              return Card(
                                color: theme.inactiveTextIconColor,
                                clipBehavior: Clip.hardEdge,
                                child: ExpansionTile(
                                  title: _orderTitle(item, theme),
                                  children: [
                                    if ((item['addons'] as List).isNotEmpty)
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
                                          children: [
                                            ...(item['addons'] as List).map(
                                              (e) => ListTile(
                                                title: Text(
                                                  '${e['name']} ~> ${e['agent']}',
                                                ),
                                                subtitle: Text(
                                                  (num.tryParse(
                                                            e['price']
                                                                .toString(),
                                                          ) ??
                                                          0)
                                                      .toDouble()
                                                      .money,
                                                ),
                                                trailing: canManageOrder
                                                    ? IconButton(
                                                        onPressed: () {
                                                          ref
                                                              .read(
                                                                orderServicesProvider
                                                                    .notifier,
                                                              )
                                                              .removeAddon(
                                                                order:
                                                                    order['billno'],
                                                                cartid: item['cartid']
                                                                    .toString(),
                                                                addonid: e['id']
                                                                    .toString(),
                                                              )
                                                              .then((_) {
                                                                if (Navigator.of(
                                                                  context,
                                                                ).canPop()) {
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop();
                                                                }

                                                                if (Navigator.of(
                                                                  context,
                                                                ).canPop()) {
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop();
                                                                }

                                                                ref.invalidate(
                                                                  orderServicesProvider,
                                                                );

                                                                showOrderViewSnack(
                                                                  context,
                                                                  'Addon removed',
                                                                );
                                                              })
                                                              .onError((
                                                                error,
                                                                stackTrace,
                                                              ) {
                                                                showOrderViewSnack(
                                                                  context,
                                                                  'Failed to remove addon',
                                                                  error: true,
                                                                );
                                                              });
                                                        },
                                                        icon: const Icon(
                                                          Icons.close,
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    if (canManageOrder)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextButton(
                                                onPressed: () {
                                                  if (agentsService
                                                      is AsyncData) {
                                                    final agents =
                                                        agentsService.value ??
                                                        [];

                                                    PickAgent.show(
                                                      context,
                                                      agents,
                                                    ).then((value) {
                                                      if (value != null) {
                                                        ref
                                                            .read(
                                                              orderServicesProvider
                                                                  .notifier,
                                                            )
                                                            .assignSingleAgent(
                                                              agent: value,
                                                              order:
                                                                  order['billno'],
                                                              cartid:
                                                                  item['cartid']
                                                                      .toString(),
                                                            )
                                                            .then((_) {
                                                              if (insearch &&
                                                                  Navigator.of(
                                                                    context,
                                                                  ).canPop()) {
                                                                Navigator.of(
                                                                  context,
                                                                ).pop();
                                                              }

                                                              if (Navigator.of(
                                                                context,
                                                              ).canPop()) {
                                                                Navigator.of(
                                                                  context,
                                                                ).pop();
                                                              }

                                                              ref.invalidate(
                                                                orderServicesProvider,
                                                              );

                                                              showOrderViewSnack(
                                                                context,
                                                                '${value.name} assigned to order',
                                                              );
                                                            })
                                                            .onError((
                                                              error,
                                                              stackTrace,
                                                            ) {
                                                              showOrderViewSnack(
                                                                context,
                                                                'Failed to assign agent',
                                                                error: true,
                                                              );
                                                            });
                                                      }
                                                    });
                                                  }
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
                                                  if (insearch &&
                                                      Navigator.of(
                                                        context,
                                                      ).canPop()) {
                                                    Navigator.of(context).pop();
                                                  }

                                                  Navigator.of(context).pop();

                                                  context.push(
                                                    '/orders/add_addons/${order['id']}/${item['id']}',
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
                                context
                                  ..pop()
                                  ..push('/orders/update_order/${order['id']}');
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
                                onPressed: () {
                                  if (agentsService is AsyncData) {
                                    final agents = agentsService.value ?? [];

                                    PickAgent.show(context, agents).then((
                                      value,
                                    ) {
                                      if (value != null) {
                                        ref
                                            .read(
                                              orderServicesProvider.notifier,
                                            )
                                            .assignAgent(
                                              agent: value,
                                              billno: order['billno'],
                                              orderid: order['id'],
                                            )
                                            .then((_) {
                                              if (insearch &&
                                                  Navigator.of(
                                                    context,
                                                  ).canPop()) {
                                                Navigator.of(context).pop();
                                              }

                                              if (Navigator.of(
                                                context,
                                              ).canPop()) {
                                                Navigator.of(context).pop();
                                              }

                                              if (Navigator.of(
                                                context,
                                              ).canPop()) {
                                                Navigator.of(context).pop();
                                              }

                                              ref.invalidate(
                                                orderServicesProvider,
                                              );

                                              showOrderViewSnack(
                                                context,
                                                '${value.name} assigned to order',
                                              );
                                            })
                                            .onError((error, stackTrace) {
                                              showOrderViewSnack(
                                                context,
                                                'Failed to reassign order',
                                                error: true,
                                              );
                                            });
                                      }
                                    });
                                  }
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
                          showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            initialDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                            lastDate: DateTime(2030),
                          ).then((date) {
                            if (date != null) {
                              showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              ).then((time) {
                                if (time != null) {
                                  final newDate = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );

                                  ref
                                      .read(orderServicesProvider.notifier)
                                      .rescheduleOrder(
                                        date: newDate,
                                        order: order['billno'],
                                      )
                                      .then((_) {
                                        if (Navigator.of(context).canPop()) {
                                          Navigator.of(context).pop();
                                        }

                                        if (Navigator.of(context).canPop()) {
                                          Navigator.of(context).pop();
                                        }

                                        ref.invalidate(orderServicesProvider);

                                        showOrderViewSnack(
                                          context,
                                          'Order rescheduled to ${sDate3(newDate)}',
                                        );
                                      })
                                      .onError((error, stackTrace) {
                                        showOrderViewSnack(
                                          context,
                                          'Error rescheduling',
                                          error: true,
                                        );
                                      });
                                }
                              });
                            }
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: theme.primaryBackGround,
                          side: BorderSide(color: theme.primaryBackGround),
                          fixedSize: const Size(double.maxFinite, 20),
                        ),
                        child: const Text('Re - Schedule'),
                      ),
                    ),

                  if (order['status'] == 'In-Service' && canManageOrder)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      child: TextButton(
                        onPressed: () {
                          if (insearch && Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }

                          Navigator.of(context).pop();

                          context.push('/orders/add_service/${order['id']}');
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

  Column _orderTitle(dynamic item, ThemeConfig theme) {
    final agentName = item['agent'].toString().isNotEmpty
        ? item['agent']
        : '___ ___';

    final addons = item['addons'] as List;

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
                    item['name'],
                    maxLines: 3,
                    style: TextStyle(color: theme.defultColor),
                  ),
                  Text(
                    (num.tryParse(item['price'].toString()) ?? 0)
                        .toDouble()
                        .money,
                    style: TextStyle(color: theme.defultColor),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Quantity: ${item['items']}',
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

  Widget noorder(WidgetRef ref, ThemeConfig theme) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Material(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
