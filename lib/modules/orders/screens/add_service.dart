import 'package:venastudio/common.dart';

class OrderAddService extends ConsumerWidget {
  const OrderAddService({super.key, required this.orderId});
  final num orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeServicesProvider);
    final businessServices = ref.watch(businessServicesProvider);
    final cartitems = ref.watch(servicesToAdd);
    final width = context.sz.width;
    bool isSmallScreen = width < 600;

    return Scaffold(
      backgroundColor: theme.secondaryBackGround,
      appBar: isSmallScreen
          ? AppBar(
              backgroundColor: theme.secondaryBackGround,
              foregroundColor: theme.textIconPrimaryColor,
              centerTitle: true,
              title: const Text('Add Service'),
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
                    SearchAddServices.show(
                      context,
                      businessServices.services,
                      onAdd,
                      quantityInCart,
                    );
                  },
                  icon: const Icon(Icons.search_rounded),
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
                    title: 'Add Service',
                    onBack: () {
                      ref.invalidate(servicesToAdd);
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    action: IconButton(
                      onPressed: () {
                        SearchAddServices.show(
                          context,
                          businessServices.services,
                          onAdd,
                          quantityInCart,
                        );
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
                        itemCount: businessServices.services.length,
                        itemBuilder: (context, index) {
                          final savis = businessServices.services[index];
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
                                  .read(servicesToAdd.notifier)
                                  .update((state) => prev);
                            },
                            onEdit: null,
                            cartQuantity: () {
                              return quantityInCart(savis, cartitems);
                            }(),
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
                  _ToAddService.show(
                    context: context,
                    savises: cartitems,
                    onConfirm: (ctx) {
                      Navigator.of(context).pop();
                      context.loading;
                      ref
                          .read(orderServicesProvider.notifier)
                          .addService(orderId: orderId, savises: cartitems)
                          .then((_) {
                            ref.invalidate(servicesToAdd);
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                            ref.invalidate(orderServicesProvider);
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                            context.showToast(
                              'Order updated',
                              textColor: theme.textIconPrimaryColor,
                            );
                          })
                          .onError((error, stackTrace) {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          });
                    },
                  );
                },
                label: Text(
                  'Add${cartitems.length > 1 ? ' : ${cartitems.length}' : ''}',
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
    final prev = ref.read(servicesToAdd);
    final exists = prev.indexWhere((element) => element.id == savis.id);
    if (exists == -1) {
      final newSavis = savis.copyWith(quantity: 1);
      ref.read(servicesToAdd.notifier).update((state) => [...prev, newSavis]);
    } else {
      prev[exists] = savis.copyWith(quantity: prev[exists].quantity + 1);
      // prev[exists] = updatedSavis;
      ref.read(servicesToAdd.notifier).update((state) => [...prev]);
    }
  }

  static num quantityInCart(Savis savis, List<Savis> cartitems) {
    final cartIndex = cartitems.indexWhere((element) => element.id == savis.id);
    if (cartIndex == -1) return 0;
    return cartitems[cartIndex].quantity;
  }
}

class _ToAddService extends ConsumerWidget {
  const _ToAddService({required this.savises, this.onConfirm});
  final List<Savis> savises;
  final ValueChanged<BuildContext>? onConfirm;

  static show({
    required BuildContext context,
    required List<Savis> savises,
    ValueChanged<BuildContext>? onConfirm,
  }) {
    return showDialog(
      context: context,
      useRootNavigator: SrceenType.type(context.sz).isMobile,
      builder: (_) {
        return _ToAddService(savises: savises, onConfirm: onConfirm);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    itemCount: savises.length,
                    padding: const EdgeInsets.all(14),
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final savis = savises[index];
                      return Card(
                        child: ListTile(
                          title: Text(savis.name),
                          subtitle: Text(
                            '${savis.amount.toDouble().money}  X  ${savis.quantity}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: TextButton(
                    onPressed: () => onConfirm?.call(context),
                    style: TextButton.styleFrom(
                      backgroundColor: theme.primaryBackGround,
                      foregroundColor: theme.activeTextIconColor,
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
