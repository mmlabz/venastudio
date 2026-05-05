import 'package:venastudio/common.dart';

class OrderAddAddon extends ConsumerStatefulWidget {
  const OrderAddAddon({
    super.key,
    required this.orderId,
    required this.itemId,
    this.prevAddons,
  });

  final num orderId;
  final num itemId;
  final List<Map<String, dynamic>>? prevAddons;

  @override
  ConsumerState<OrderAddAddon> createState() => _OrderAddAddonState();

  static num quantityInCart(Savis savis, List<Savis> cartitems) {
    return cartitems.where((element) => element.id == savis.id).length;
  }
}

class _OrderAddAddonState extends ConsumerState<OrderAddAddon> {
  bool loaded = false;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    bool isSmallScreen = width < 600;

    final theme = ref.watch(themeServicesProvider);
    final businessServices = ref.watch(businessServicesProvider);
    final cartitems = ref.watch(addonToAdd);
    final agentsService = ref.watch(agentsServicesProvider);
    final addons = businessServices.services.where(
      (element) => element.type == 'Addon',
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.prevAddons != null &&
          !loaded &&
          widget.prevAddons!.isNotEmpty &&
          cartitems.isEmpty) {
        final added = <int, int>{};
        final servicesToFill = widget.prevAddons!.map((e) {
          final isInAddons = addons.where((ex) => ex.id == e['id']).firstOrNull;
          if (isInAddons != null) {
            final qq = added[isInAddons.id];
            added[isInAddons.id] = (qq ?? 0) + 1;
            return isInAddons.copyWith(quantity: (qq ?? 0) + 1);
          }
        }).whereType<Savis>();
        loaded = true;
        ref
            .read(addonToAdd.notifier)
            .update((state) => servicesToFill.toList());
      }
    });

    return Scaffold(
      backgroundColor: theme.secondaryBackGround,
      appBar: isSmallScreen
          ? AppBar(
              backgroundColor: theme.secondaryBackGround,
              foregroundColor: theme.textIconPrimaryColor,
              centerTitle: true,
              title: const Text('Add Add-ons'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.invalidate(servicesToAdd);
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    SearchAddons.show(context, addons.toList(), onAdd);
                  },
                  icon: Icon(
                    Icons.search_rounded,
                    color: theme.textIconPrimaryColor,
                  ),
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          Column(
            children: [
              if (!isSmallScreen)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Header(
                    title: 'Add Add-ons',
                    onBack: () {
                      ref.invalidate(servicesToAdd);
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    action: IconButton(
                      onPressed: () {
                        SearchAddons.show(context, addons.toList(), onAdd);
                      },
                      icon: Icon(
                        Icons.search_rounded,
                        color: theme.textIconPrimaryColor,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = width > 1200
                        ? 5
                        : width > 800
                        ? 4
                        : width > 600
                        ? 3
                        : 2;
                    double aspectRatio = (width < 400) ? 0.8 / 1.4 : 0.8 / 1.1;

                    return Center(
                      child: GridView.builder(
                        padding: const EdgeInsets.only(left: 16.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: addons.length,
                        itemBuilder: (context, index) {
                          final savis = addons.elementAt(index);
                          return SavisCard(
                            savis: savis,
                            width: double.maxFinite,
                            onAdd: () => onAdd(ref, savis),
                            onRemove: () {
                              final prev = List<Savis>.from(cartitems);
                              prev.removeWhere(
                                (element) => element.id == savis.id,
                              );
                              ref
                                  .read(addonToAdd.notifier)
                                  .update((state) => prev);
                            },
                            onEdit: null,
                            cartQuantity: OrderAddAddon.quantityInCart(
                              savis,
                              cartitems,
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
          if (cartitems.isNotEmpty)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: () {
                  final agents = (agentsService.value ?? [])
                      .where((element) => !element.archived)
                      .toList();
                  _ToAddAddon.show(
                    context: context,
                    addons: cartitems,
                    agents: agents,
                    onConfirm: (agnts) {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      if (widget.prevAddons == null) {
                        ref
                            .read(orderServicesProvider.notifier)
                            .updateAddon(
                              orderId: widget.orderId,
                              addons: cartitems,
                              mainServiceId: widget.itemId,
                              agents: agnts.$1,
                            )
                            .then((_) {
                              // ignore: use_build_context_synchronously
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                              ref.invalidate(orderServicesProvider);
                              // ignore: use_build_context_synchronously
                              context.showToast(
                                'Order updated',
                                textColor: theme.textIconPrimaryColor,
                              );
                            })
                            .onError((error, stackTrace) {
                              // ignore: use_build_context_synchronously
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            });
                      } else {
                        var addonItems = cartitems.map((e) {
                          final agent = agnts.$1['${e.id}-${e.quantity}'];
                          return {
                            'id': agent?.id ?? '-1',
                            'name': agent?.name,
                            'serviceName': e.name,
                            'serviceId': e.id,
                            'mainServiceId': widget.itemId,
                            'quantity': e.quantity,
                            'agent_id': agent?.id,
                            'discount': e.discount,
                            'serviceType': 'Addon',
                            'amount': e.amount,
                            'price': e.amount,
                            'agents': [],
                          };
                        }).toList();
                        context.pop(addonItems);
                      }
                    },
                  );
                },
                label: Text(
                  '${(widget.prevAddons?.isEmpty ?? true) ? 'Add' : 'Update'}${cartitems.length > 1 ? ' : ${cartitems.length}' : ''}',
                  style: TextStyle(color: theme.activeTextIconColor),
                ),
                backgroundColor: theme.primaryBackGround,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void onAdd(WidgetRef ref, Savis savis) {
    final prev = ref.read(addonToAdd);
    final exists = prev.where((element) => element.id == savis.id).length;
    final newSavis = savis.copyWith(quantity: exists + 1);
    ref.read(addonToAdd.notifier).update((state) => [...prev, newSavis]);
  }
}

class _ToAddAddon extends ConsumerStatefulWidget {
  const _ToAddAddon({
    required this.addons,
    required this.agents,
    this.onConfirm,
  });

  final List<Savis> addons;
  final List<Agent> agents;
  final ValueChanged<(Map<String, Agent> data, BuildContext ctx)>? onConfirm;

  static show({
    required BuildContext context,
    required List<Savis> addons,
    required List<Agent> agents,
    ValueChanged<(Map<String, Agent> data, BuildContext ctx)>? onConfirm,
  }) {
    return showDialog(
      context: context,
      useRootNavigator: SrceenType.type(context.sz).isMobile,
      builder: (_) {
        return _ToAddAddon(
          addons: addons,
          onConfirm: onConfirm,
          agents: agents,
        );
      },
    );
  }

  @override
  ConsumerState<_ToAddAddon> createState() => _ToAddAddonState();
}

class _ToAddAddonState extends ConsumerState<_ToAddAddon> {
  final agentsMap = <String, Agent>{};

  @override
  Widget build(BuildContext context) {
    final size = context.sz;
    final maxWidth = getMaxWidth(size.width);
    final theme = ref.watch(themeServicesProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: maxWidth,
          child: Material(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add the following',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close),
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
                    itemCount: widget.addons.length,
                    padding: const EdgeInsets.all(14),
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final savis = widget.addons[index];
                      return Card(
                        clipBehavior: Clip.hardEdge,
                        child: ListTile(
                          onTap: () {
                            PickAgent.show(context, widget.agents).then((
                              value,
                            ) {
                              if (value != null) {
                                setState(() {
                                  agentsMap['${savis.id}-${savis.quantity}'] =
                                      value;
                                });
                              }
                            });
                          },
                          title: Text(savis.name),
                          subtitle: Text(savis.amount.toDouble().money),
                          trailing:
                              agentsMap['${savis.id}-${savis.quantity}'] != null
                              ? Text(
                                  agentsMap['${savis.id}-${savis.quantity}']
                                          ?.name ??
                                      '',
                                )
                              : Icon(
                                  Icons.error_outline,
                                  color: theme.deleteColor.withOpacity(.8),
                                ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: TextButton(
                    onPressed: agentsMap.length == widget.addons.length
                        ? () {
                            widget.onConfirm?.call((agentsMap, context));
                          }
                        : null,
                    style: TextButton.styleFrom(
                      backgroundColor: theme.activeBackGround,
                      foregroundColor: theme.activeTextIconColor,
                      disabledBackgroundColor: theme.primaryBackGround,
                      disabledForegroundColor: theme.activeTextIconColor,
                      fixedSize: const Size(double.maxFinite, 20),
                    ),
                    child: const Text('Confirm'),
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
