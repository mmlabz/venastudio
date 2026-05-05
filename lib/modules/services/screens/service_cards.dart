import 'package:venastudio/common.dart';

class SavisCard extends ConsumerWidget {
  const SavisCard({
    super.key,
    required this.savis,
    required this.width,
    this.onAdd,
    this.onRemove,
    this.onEdit,
    this.cartQuantity,
    this.showAddButton = true,
  });

  final Savis savis;
  final double width;
  final VoidCallback? onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final num? cartQuantity;
  final bool showAddButton;

  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffBFEFF5);

  static void onAddTap(Savis savis, WidgetRef ref) {
    ref.read(cartServiceProvider.notifier).add(savis);
  }

  static num quantityInCart(Savis savis, List<Savis> cartItems) {
    final index = cartItems.indexWhere((item) => item.id == savis.id);
    return index == -1 ? 0 : cartItems[index].quantity;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartServiceProvider).items;
    final quantity =
        cartQuantity?.toInt() ?? quantityInCart(savis, cartItems).toInt();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: venaLine.withOpacity(0.9), width: 1),
        boxShadow: [
          BoxShadow(
            color: venaTeal.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 50,
            child: Image.asset(
              'assets/icons/tips.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Expanded(
            flex: 50,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    savis.name.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: venaDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    savis.type.isEmpty ? 'Service' : savis.type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: venaMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),

                  const Spacer(),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          savis.amount.toDouble().money,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: venaTeal,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      if (showAddButton)
                        SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            onPressed: onAdd ?? () => onAddTap(savis, ref),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: quantity > 0
                                  ? venaTeal
                                  : Colors.white,
                              foregroundColor: quantity > 0
                                  ? Colors.white
                                  : venaTeal,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                                side: BorderSide(
                                  color: quantity > 0
                                      ? venaTeal
                                      : venaTeal.withOpacity(0.45),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Text(
                              quantity > 0 ? '+ $quantity' : '+ Add',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
