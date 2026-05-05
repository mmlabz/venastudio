import 'dart:ui';

import 'package:venastudio/common.dart';

class ServiceCartPage extends ConsumerStatefulWidget {
  final List<Savis> cartItems;
  final bool isModal;

  const ServiceCartPage({
    super.key,
    required this.cartItems,
    this.isModal = false,
  });

  static double calculateTotalPrice(List<Savis> cartitems) {
    return cartitems.fold(0.0, (previousValue, element) {
      final discount = num.tryParse(element.discount) ?? 0;
      if (discount > 0) {
        return ((element.amount - discount) * element.quantity) + previousValue;
      }
      return (element.amount * element.quantity) + previousValue;
    });
  }

  static Future<bool> createOrder({
    required BuildContext context,
    required WidgetRef ref,
    bool isPayFirst = false,
    PayFirstPayload? payload,
  }) async {
    final ttp = ServiceCartPage.calculateTotalPrice(
      ref.read(cartServiceProvider).items,
    );

    try {
      await ref
          .read(cartServiceProvider.notifier)
          .createOrder(
            totalPrice: ttp,
            payFirst: isPayFirst,
            orderType: payload?.orderType,
            reference: payload?.reference,
            code: payload?.code,
            type: payload?.type,
            cashAdd: payload?.cashAdd,
          );

      ref.read(cartServiceProvider.notifier).clearState();

      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  ConsumerState<ServiceCartPage> createState() => _ServiceCartPageState();
}

class _ServiceCartPageState extends ConsumerState<ServiceCartPage> {
  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);

  late final stateData = ref.read(cartServiceProvider);

  late final TextEditingController _cAgentName = TextEditingController(
    text: stateData.mainAgent?.name,
  );

  late final TextEditingController _cShopName = TextEditingController(
    text: stateData.shop?['name'],
  );

  late final TextEditingController _cPhoneClient = TextEditingController(
    text: stateData.phone,
  );

  final GlobalKey<FormState> formKey = GlobalKey();

  bool isAbooking = false;
  bool _isCreatingOrder = false;
  bool? payFirst;

  @override
  void dispose() {
    _cAgentName.dispose();
    _cShopName.dispose();
    _cPhoneClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartService = ref.watch(cartServiceProvider);
    final agentsService = ref.watch(agentsServicesProvider);
    final branchesService = ref.watch(branchesServicesProvider);
    final settingsService = ref.watch(settingsServicesProvider);
    final cartitems = cartService.items;

    final agentsList = agentsService.valueOrNull ?? <Agent>[];
    final branchesList = branchesService.valueOrNull ?? [];

    payFirst ??= settingsService.payFirst;

    final bool currentPayFirst = payFirst ?? false;
    final double totalAmount = ServiceCartPage.calculateTotalPrice(cartitems);

    return Scaffold(
      backgroundColor: venaBg,
      appBar: AppBar(
        leading: context.backIcon(ref, () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }),
        title: const Text(
          'Create Order',
          style: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
        ),
        backgroundColor: venaBg,
        foregroundColor: venaDark,
        elevation: 0,
        actions: [
          if (cartitems.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(cartServiceProvider.notifier).clearState();
                context.go('/');
              },
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: venaDanger,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffF8FDFF), Color(0xffEEF9FB), Color(0xffE4F7FA)],
          ),
        ),
        child: cartitems.isEmpty
            ? emptyState(ref, text: 'No items in cart')
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 680;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _TotalCard(totalAmount: totalAmount),
                            const SizedBox(height: 20),
                            const _SectionTitle(title: 'Client Details'),
                            const SizedBox(height: 14),
                            Form(
                              key: formKey,
                              child: _CompactInput(
                                controller: _cPhoneClient,
                                label: 'Phone Number',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: phoneValidation,
                                onChanged: (value) {
                                  ref
                                          .read(cartServiceProvider.notifier)
                                          .clientPhone =
                                      value;
                                },
                              ),
                            ),
                            const SizedBox(height: 14),
                            _ResponsiveRow(
                              twoColumns: twoColumns,
                              children: [
                                _CompactPicker(
                                  label: 'Select Shop',
                                  value: _cShopName.text.isEmpty
                                      ? 'Select Shop'
                                      : _cShopName.text,
                                  icon: Icons.storefront_outlined,
                                  onTap: () {
                                    FocusScope.of(context).unfocus();

                                    SelectShop.show(
                                      context,
                                      branchesList,
                                    ).then((value) {
                                      if (value != null) {
                                        ref
                                                .read(
                                                  cartServiceProvider.notifier,
                                                )
                                                .mainShop =
                                            value;

                                        _cShopName.text =
                                            '${value['name'] ?? ''}';

                                        setState(() {});
                                      }
                                    });
                                  },
                                ),
                                _CompactPicker(
                                  label: 'Assign Agent',
                                  value: _cAgentName.text.isEmpty
                                      ? 'Select Agent'
                                      : _cAgentName.text,
                                  icon: Icons.person_outline,
                                  onTap: () {
                                    FocusScope.of(context).unfocus();

                                    PickAgent.show(context, agentsList).then((
                                      value,
                                    ) {
                                      if (value != null) {
                                        ref
                                                .read(
                                                  cartServiceProvider.notifier,
                                                )
                                                .mainAgent =
                                            value;

                                        _cAgentName.text = value.name;

                                        setState(() {});
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _ResponsiveRow(
                              twoColumns: twoColumns,
                              children: [
                                _ToggleTile(
                                  title: 'Booking',
                                  subtitle: cartService.bookingDate == null
                                      ? (isAbooking
                                            ? 'Select booking date'
                                            : 'Not a booking')
                                      : cartService.bookingDate!
                                            .toLocal()
                                            .toString()
                                            .split(' ')
                                            .first,
                                  icon: Icons.calendar_today_outlined,
                                  value: isAbooking,
                                  onChanged: (value) async {
                                    FocusScope.of(context).unfocus();

                                    if (!value) {
                                      ref
                                          .read(cartServiceProvider.notifier)
                                          .clearBookingDate();

                                      setState(() => isAbooking = false);
                                      return;
                                    }

                                    setState(() => isAbooking = true);

                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          cartService.bookingDate ??
                                          DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );

                                    if (picked != null) {
                                      ref
                                              .read(
                                                cartServiceProvider.notifier,
                                              )
                                              .bookingDate =
                                          picked;

                                      setState(() {});
                                    }
                                  },
                                ),
                                _ToggleTile(
                                  title: currentPayFirst
                                      ? 'Pay Now'
                                      : 'Pay Later',
                                  subtitle: currentPayFirst
                                      ? 'Capture payment now'
                                      : 'Create unpaid order',
                                  icon: currentPayFirst
                                      ? Icons.payment
                                      : Icons.receipt_long,
                                  value: currentPayFirst,
                                  onChanged: _isCreatingOrder
                                      ? null
                                      : (value) {
                                          FocusScope.of(context).unfocus();

                                          setState(() {
                                            payFirst = value;
                                          });
                                        },
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              height: 58,
                              child: ElevatedButton(
                                onPressed: _isCreatingOrder
                                    ? null
                                    : () => onCreateOrder(currentPayFirst),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: venaTeal,
                                  disabledBackgroundColor: venaTeal.withOpacity(
                                    0.28,
                                  ),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                                child: _isCreatingOrder && !currentPayFirst
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Creating...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            currentPayFirst
                                                ? Icons.payment
                                                : Icons.receipt_long,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            currentPayFirst
                                                ? 'PROCEED TO PAYMENT'
                                                : 'CREATE ORDER',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> onCreateOrder(bool payFirst) async {
    if (!formKey.currentState!.validate() || !validBooking) return;

    FocusScope.of(context).unfocus();

    setState(() => _isCreatingOrder = true);

    final bool orderCreated;

    if (payFirst) {
      orderCreated = await CartPayFirst.show(context: context) ?? false;
    } else {
      orderCreated = await ServiceCartPage.createOrder(
        context: context,
        ref: ref,
        isPayFirst: false,
      );
    }

    if (!mounted) return;

    setState(() => _isCreatingOrder = false);

    if (!orderCreated) return;

    await showSuccessPopup();

    if (!mounted) return;

    if (widget.isModal) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      context.go('/');
    }
  }

  Future<void> showSuccessPopup() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.20),
      builder: (dialogContext) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });

        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.transparent),
            ),
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 270,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.94),
                    border: Border.all(color: venaLine),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: venaTeal,
                        size: 74,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Order Created',
                        style: TextStyle(
                          color: venaDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Checkout completed successfully',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: venaMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  // void onCreateOrder(bool payFirst) async {
  //   if (formKey.currentState!.validate() && validBooking) {
  //     FocusScope.of(context).unfocus();

  //     if (!payFirst) {
  //       setState(() => _isCreatingOrder = true);
  //     }

  //     final bool orderCreated;

  //     if (payFirst) {
  //       orderCreated = await CartPayFirst.show(context: context) ?? false;
  //     } else {
  //       orderCreated = await ServiceCartPage.createOrder(
  //         context: context,
  //         ref: ref,
  //         isPayFirst: false,
  //       );
  //     }

  //     if (orderCreated && mounted) {
  //       showSuccessPopup(() {
  //         if (!mounted) return;

  //         if (widget.isModal) {
  //           if (Navigator.of(context).canPop()) {
  //             Navigator.of(context).pop();
  //           }
  //         } else {
  //           context.go('/');
  //         }
  //       });
  //     }

  //     if (!payFirst && mounted) {
  //       setState(() => _isCreatingOrder = false);
  //     }
  //   }
  // }

  // void showSuccessPopup(VoidCallback onDone) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     barrierColor: Colors.black.withOpacity(0.20),
  //     builder: (_) {
  //       Future.delayed(const Duration(milliseconds: 1200), () {
  //         if (!mounted) return;

  //         if (Navigator.of(context).canPop()) {
  //           Navigator.of(context).pop();
  //         }

  //         onDone();
  //       });

  //       return Stack(
  //         children: [
  //           BackdropFilter(
  //             filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
  //             child: Container(color: Colors.transparent),
  //           ),
  //           Center(
  //             child: Material(
  //               color: Colors.transparent,
  //               child: Container(
  //                 width: 270,
  //                 padding: const EdgeInsets.all(24),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white.withOpacity(0.94),
  //                   border: Border.all(color: venaLine),
  //                 ),
  //                 child: const Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Icon(
  //                       Icons.check_circle_rounded,
  //                       color: venaTeal,
  //                       size: 74,
  //                     ),
  //                     SizedBox(height: 14),
  //                     Text(
  //                       'Order Created',
  //                       style: TextStyle(
  //                         color: venaDark,
  //                         fontWeight: FontWeight.w900,
  //                         fontSize: 18,
  //                       ),
  //                     ),
  //                     SizedBox(height: 6),
  //                     Text(
  //                       'Checkout completed successfully',
  //                       textAlign: TextAlign.center,
  //                       style: TextStyle(
  //                         color: venaMuted,
  //                         fontWeight: FontWeight.w600,
  //                         fontSize: 12,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  bool get validBooking {
    if (isAbooking) {
      if (ref.read(cartServiceProvider).bookingDate == null) {
        context.showToast(
          'Please select booking date',
          error: true,
          textColor: venaDark,
        );
        return false;
      }
    }

    return true;
  }
}

class _ResponsiveRow extends StatelessWidget {
  final bool twoColumns;
  final List<Widget> children;

  const _ResponsiveRow({required this.twoColumns, required this.children});

  @override
  Widget build(BuildContext context) {
    if (!twoColumns) {
      return Column(
        children: [children[0], const SizedBox(height: 14), children[1]],
      );
    }

    return Row(
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 14),
        Expanded(child: children[1]),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double totalAmount;

  const _TotalCard({required this.totalAmount});

  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: Row(
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              color: venaMuted,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            totalAmount.money,
            style: const TextStyle(
              color: venaTeal,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  static const Color venaDark = Color(0xff07304A);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: venaDark,
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _CompactInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _CompactInput({
    required this.controller,
    required this.label,
    required this.icon,
    required this.keyboardType,
    this.validator,
    this.onChanged,
  });

  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        cursorColor: venaTeal,
        style: const TextStyle(
          color: venaDark,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: venaMuted,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Icon(icon),
          prefixIconColor: venaMuted,
          filled: true,
          fillColor: Colors.white.withOpacity(0.94),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: venaLine),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: venaTeal, width: 1.4),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xffD94B4B)),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xffD94B4B), width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _CompactPicker extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _CompactPicker({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              color: venaMuted,
              fontWeight: FontWeight.w700,
            ),
            prefixIcon: Icon(icon),
            prefixIconColor: venaMuted,
            suffixIcon: const Icon(Icons.keyboard_arrow_down),
            suffixIconColor: venaMuted,
            filled: true,
            fillColor: Colors.white.withOpacity(0.94),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: venaLine),
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: venaLine),
            ),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: venaDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? venaTeal : venaMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: venaDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: venaMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: venaTeal,
            inactiveThumbColor: venaMuted,
            inactiveTrackColor: venaBg,
          ),
        ],
      ),
    );
  }
}
