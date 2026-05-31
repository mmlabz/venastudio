import 'package:venastudio/common.dart';

class UpdateOrderPage extends ConsumerStatefulWidget {
  const UpdateOrderPage({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<UpdateOrderPage> createState() => _UpdateOrderPageState();
}

class _UpdateOrderPageState extends ConsumerState<UpdateOrderPage> {
  bool dataLoaded = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeServicesProvider);
    final agentsService = ref.watch(agentsServicesProvider);
    final settingsService = ref.watch(settingsServicesProvider);
    final cartService = ref.watch(updateCartServiceProvider);

    if (!dataLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dataLoaded = true;
        ref
            .read(updateCartServiceProvider.notifier)
            .load(orderId: widget.orderId);
      });
    }

    return Scaffold(
      backgroundColor: theme.secondaryBackGround,
      appBar: AppBar(
        backgroundColor: theme.secondaryBackGround,
        foregroundColor: theme.textIconPrimaryColor,
        title: Text(
          'Update Order',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: theme.textIconPrimaryColor,
          ),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: LayoutBuilder(
        builder: (context, cs) {
          final maxWidth = getMaxWidth(cs.maxWidth);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        CartItemsSection(
                          maxWidth: maxWidth,
                          theme: theme,
                          cartService: cartService,
                          settingsService: settingsService,
                          agentsService: agentsService,
                          onRemoveItem: (value) {
                            ref
                                .read(updateCartServiceProvider.notifier)
                                .remove(value);
                          },
                          onTapAssign: (value) {
                            try {
                              ref.read(updateCartServiceProvider.notifier).agent =
                                  SmartAssignmentBridge.entry(value);
                            } catch (e) {
                              context.showToast(
                                '$e',
                                textColor: theme.textIconPrimaryColor,
                              );
                            }
                          },
                          onTapAdd: (value) {
                            ref
                                .read(updateCartServiceProvider.notifier)
                                .changeQnty(value, value.quantity + 1);
                          },
                          onTapRemove: (value) {
                            ref
                                .read(updateCartServiceProvider.notifier)
                                .changeQnty(value, value.quantity - 1);
                          },
                          onRemoveDiscount: (value) {
                            ref
                                .read(updateCartServiceProvider.notifier)
                                .setDiscount(value, 0);
                          },
                          onSetDiscount: (value) {
                            ref
                                .read(updateCartServiceProvider.notifier)
                                .setDiscount(value.savis, value.discount);
                          },
                          onSetAddons: (value) {
                            ref
                                .read(updateCartServiceProvider.notifier)
                                .addAddon(
                                  savisId: value.savis,
                                  addons: value.addons,
                                );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Total Section
                        Container(
                          width: maxWidth,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.primaryBackGround,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: theme.cardShadowColor.withOpacity(0.2),
                                spreadRadius: 3,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Total: ${ServiceCartPage.calculateTotalPrice(cartService.items).money}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: theme.activeTextIconColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 500),
                          child: Consumer(
                            builder: (context, ref, _) {
                              final isLoading = ref.watch(
                                isUpdatingOrderProvider,
                              );

                              return ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        ref
                                                .read(
                                                  isUpdatingOrderProvider
                                                      .notifier,
                                                )
                                                .state =
                                            true;

                                        try {
                                          await ref
                                              .read(
                                                updateCartServiceProvider
                                                    .notifier,
                                              )
                                              .updateIt(
                                                orderId: widget.orderId,
                                              );
                                          if (mounted &&
                                              Navigator.of(context).canPop()) {
                                            Navigator.of(context).pop();
                                          }
                                          ;
                                          context.showToast(
                                            'Order Updated',
                                            textColor:
                                                theme.textIconPrimaryColor,
                                          );
                                          ref.invalidate(orderServicesProvider);
                                        } catch (error) {
                                          if (mounted &&
                                              Navigator.of(context).canPop()) {
                                            Navigator.of(context).pop();
                                          }
                                          ;
                                          context.showToast(
                                            'Error Updating Order',
                                            textColor:
                                                theme.textIconPrimaryColor,
                                          );
                                        } finally {
                                          ref
                                                  .read(
                                                    isUpdatingOrderProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              false;
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryBackGround,
                                  foregroundColor: theme.activeTextIconColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  minimumSize: const Size(double.infinity, 50),
                                  elevation: 10,
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: theme.activeTextIconColor,
                                        ),
                                      )
                                    : Text(
                                        'UPDATE ORDER',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: theme.activeTextIconColor,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
