import 'package:venastudio/common.dart';

class CartItemsSection extends StatelessWidget {
  const CartItemsSection({
    super.key,
    required this.maxWidth,
    required this.theme,
    required this.cartService,
    required this.settingsService,
    required this.agentsService,
    required this.onRemoveItem,
    required this.onTapAssign,
    required this.onTapAdd,
    required this.onTapRemove,
    required this.onRemoveDiscount,
    required this.onSetDiscount,
    required this.onSetAddons,
  });

  final double maxWidth;
  final ThemeConfig theme;
  final Cart cartService;
  final SettingsConfig settingsService;
  final AsyncValue<List<Agent>> agentsService;
  final ValueChanged<Savis> onRemoveItem;
  final ValueChanged<dynamic> onTapAssign;
  final ValueChanged<Savis> onTapAdd;
  final ValueChanged<Savis> onTapRemove;
  final ValueChanged<Savis> onRemoveDiscount;
  final ValueChanged<({Savis savis, num discount})> onSetDiscount;
  final ValueChanged<({int savis, List<Map<String, dynamic>> addons})>
  onSetAddons;

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);
  static const Color venaSuccess = Color(0xff13A76B);

  @override
  Widget build(BuildContext context) {
    final cartitems = cartService.items;

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: maxWidth,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: cartitems.length,
          itemBuilder: (context, index) {
            final item = cartitems[index];
            final assigned = cartService.assigned?['${item.id}'];
            final discount = num.tryParse(item.discount);
            final hasdiscount = discount != null && discount >= 1;
            final addonCount = cartService.addons
                .where((e) => e['mainServiceId'] == item.id)
                .length;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
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
                          Icons.spa_outlined,
                          color: venaTeal,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: venaDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onRemoveItem(item),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: venaDanger,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(child: _assignButton(context, item, assigned)),
                      const SizedBox(width: 8),
                      if (settingsService.showDiscount)
                        Expanded(
                          child: _discountButton(
                            context,
                            item,
                            discount,
                            hasdiscount,
                          ),
                        ),
                      if (settingsService.showDiscount)
                        const SizedBox(width: 8),
                      Expanded(child: _addonButton(context, item, addonCount)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(height: 1, color: venaLine),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _qtyButton(
                        icon: Icons.remove_rounded,
                        onTap: () => onTapRemove(item),
                      ),
                      Container(
                        height: 32,
                        width: 44,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: venaLine),
                            bottom: BorderSide(color: venaLine),
                          ),
                        ),
                        child: Text(
                          item.quantity.toString(),
                          style: const TextStyle(
                            color: venaDark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _qtyButton(
                        icon: Icons.add_rounded,
                        onTap: () => onTapAdd(item),
                        active: true,
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            getSinglePrice(
                              amt: item.amount,
                              qty: item.quantity,
                            ),
                            style: TextStyle(
                              color: hasdiscount ? venaMuted : venaDark,
                              fontWeight: hasdiscount
                                  ? FontWeight.w600
                                  : FontWeight.w900,
                              decoration: hasdiscount
                                  ? TextDecoration.lineThrough
                                  : null,
                              fontSize: hasdiscount ? 12 : 15,
                            ),
                          ),
                          if (hasdiscount)
                            Text(
                              getSinglePrice(
                                amt: item.amount - discount,
                                qty: item.quantity,
                              ),
                              style: const TextStyle(
                                color: venaSuccess,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _assignButton(BuildContext context, Savis item, dynamic assigned) {
    return agentsService.when(
      loading: () => const SizedBox(
        height: 34,
        child: Center(
          child: SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: venaTeal),
          ),
        ),
      ),
      error: (_, __) => const SizedBox(
        height: 34,
        child: Center(
          child: Text(
            'No agents',
            style: TextStyle(
              color: venaDanger,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
      data: (data) {
        return SizedBox(
          height: 34,
          child: TextButton.icon(
            onPressed: () async {
              if (SmartAssignmentBridge.enabled(settingsService)) {
                final value = await SmartAssignmentBridge.pickResult(
                  context,
                  settings: settingsService,
                  agents: data,
                  serviceLike: item,
                );
                if (value != null) onTapAssign(value);
                return;
              }

              final value = await PickAgent.show(context, data);
              if (value != null) {
                onTapAssign((agent: value, savis: item));
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: assigned != null
                  ? venaSuccess.withOpacity(0.10)
                  : venaBg,
              foregroundColor: assigned != null ? venaSuccess : venaDark,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: venaLine),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: Icon(
              assigned != null
                  ? Icons.check_circle_outline_rounded
                  : Icons.person_add_alt_1_rounded,
              size: 15,
            ),
            label: Text(
              assigned?['agentName'] ?? 'Assign',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
        );
      },
    );
  }

  Widget _discountButton(
    BuildContext context,
    Savis item,
    num? discount,
    bool hasdiscount,
  ) {
    return SizedBox(
      height: 34,
      child: TextButton.icon(
        onPressed: () {
          ProductDiscountEdit.show(
            context,
            discount: discount,
            remove: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              onRemoveDiscount(item);
            },
          ).then((value) {
            if (value != null && value <= item.amount) {
              onSetDiscount((savis: item, discount: value));
            }
          });
        },
        style: TextButton.styleFrom(
          backgroundColor: hasdiscount ? venaSuccess.withOpacity(0.10) : venaBg,
          foregroundColor: hasdiscount ? venaSuccess : venaDark,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: venaLine),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        icon: const Icon(Icons.local_offer_outlined, size: 15),
        label: Text(
          hasdiscount ? discount!.toDouble().money : 'Discount',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
        ),
      ),
    );
  }

  Widget _addonButton(BuildContext context, Savis item, int addonCount) {
    return SizedBox(
      height: 34,
      child: TextButton.icon(
        onPressed: () {
          final myaddons = cartService.addons
              .where((element) => element['mainServiceId'] == item.id)
              .toList();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Material(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top,
                  ),
                  child: OrderAddAddon(
                    orderId: 0,
                    itemId: item.id,
                    prevAddons: myaddons,
                  ),
                ),
              ),
            ),
          ).then((value) {
            if (value.toString() != 'null') {
              final addons = value as List<Map<String, dynamic>>;
              onSetAddons((savis: item.id, addons: addons));
            }
          });
        },
        style: TextButton.styleFrom(
          backgroundColor: addonCount > 0 ? venaTeal.withOpacity(0.10) : venaBg,
          foregroundColor: addonCount > 0 ? venaTeal : venaDark,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: venaLine),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        icon: const Icon(Icons.add_box_outlined, size: 15),
        label: Text(
          'Addons $addonCount',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
        ),
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 32,
        width: 34,
        decoration: BoxDecoration(
          color: active ? venaTeal : venaBg,
          border: Border.all(color: active ? venaTeal : venaLine),
        ),
        child: Icon(icon, color: active ? Colors.white : venaDark, size: 18),
      ),
    );
  }

  String getSinglePrice({required num amt, required num qty}) {
    return (amt * qty).toDouble().money;
  }
}
