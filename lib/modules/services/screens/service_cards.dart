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

  static const Color venaTeal = Color(0xff46C3D7);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffBFEFF5);
  static const Color venaSoft = Color(0xffF6FDFF);

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

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: venaLine.withOpacity(0.95), width: 1),
          boxShadow: [
            BoxShadow(
              color: venaTeal.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 76,
              child: SizedBox(
                width: double.infinity,
                child: _ServiceImage(image: savis.image),
              ),
            ),
            Expanded(
              flex: 24,
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            savis.name.trim().isEmpty
                                ? 'Unnamed Service'
                                : savis.name.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: venaDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            savis.amount.toDouble().money,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: venaTeal,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showAddButton) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          onPressed: onAdd ?? () => onAddTap(savis, ref),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: quantity > 0
                                ? venaTeal.withOpacity(0.12)
                                : Colors.white,
                            foregroundColor: venaTeal,
                            elevation: 0,
                            minimumSize: const Size(64, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            side: BorderSide(
                              color: quantity > 0
                                  ? venaTeal
                                  : venaTeal.withOpacity(0.75),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceImage extends StatelessWidget {
  const _ServiceImage({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    final value = image.trim();

    if (value.isEmpty) {
      return Image.asset(
        'assets/icons/tips.png',
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      value,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/icons/tips.png',
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return Container(
          color: const Color(0xffEEF9FB),
          alignment: Alignment.center,
          child: const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}
