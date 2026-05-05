import 'package:venastudio/common.dart';

class SelectShop extends StatelessWidget {
  const SelectShop({super.key, required this.shops});
  final List<Map<dynamic, dynamic>> shops;

  static Future<Map<dynamic, dynamic>?> show(
    BuildContext context,
    List<Map<dynamic, dynamic>> shops,
  ) {
    return showDialog<Map<dynamic, dynamic>>(
      context: context,
      builder: (_) {
        return SelectShop(shops: shops);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Material(
          borderRadius: BorderRadius.circular(10),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(shops.length, (index) {
                final shop = shops[index];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop(shop);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(shop['name']),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductDiscountEdit extends ConsumerStatefulWidget {
  const ProductDiscountEdit({super.key, this.onRemove, this.discount});
  final VoidCallback? onRemove;
  final num? discount;

  static Future<num?> show(
    BuildContext context, {
    VoidCallback? remove,
    num? discount,
  }) {
    return showDialog<num>(
      context: context,
      builder: (_) {
        return ProductDiscountEdit(onRemove: remove, discount: discount);
      },
    );
  }

  @override
  ConsumerState<ProductDiscountEdit> createState() =>
      _ProductDiscountEditState();
}

class _ProductDiscountEditState extends ConsumerState<ProductDiscountEdit> {
  late final TextEditingController _controller = TextEditingController(
    text: () {
      final dc = widget.discount;
      return (dc == null || dc <= 0) ? '' : '$dc';
    }(),
  );

  @override
  Widget build(BuildContext context) {
    final width = getMaxWidth(context.sz.width);
    final theme = ref.watch(themeServicesProvider);

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Center(
        child: SizedBox(
          width: width,
          child: Material(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Edit Service Discount',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextField(
                    autofocus: true,
                    readOnly: true,
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: widget.onRemove,
                          style: TextButton.styleFrom(
                            backgroundColor: theme.deleteColor,
                            foregroundColor: theme.activeTextIconColor,
                          ),
                          child: const Text('Remove'),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pop(num.tryParse(_controller.text));
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: theme.primaryBackGround,
                            foregroundColor: theme.activeTextIconColor,
                          ),
                          child: const Text('Grant'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
