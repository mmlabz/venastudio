import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:venastudio/common.dart';

ServiceUser? getCurrentSUser(WidgetRef ref) {
  final activeAgent = LocalStorage.nosql.activeAgent;

  if (activeAgent != null) {
    return ServiceUser.fromMap(activeAgent);
  }

  return ref.watch(authenticationServiceProvider).valueOrNull?.user ??
      LocalStorage.nosql.user;
}
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController searchController = TextEditingController();

  final bool _isCartVisible = false;
  bool showSearch = false;
  String selectedCategory = 'All';

  List<String> allCategories = [
    'Decoration',
    'Tips Gel',
    'Acrylic',
    'Plain Gel',
  ];

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaSurface = Color(0xffFFFFFF);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeServicesProvider);
    final businessServices = ref.watch(businessServicesProvider);
    final servicesState = ref.watch(businessServicesProvider);
    final user = getCurrentSUser(ref);
    final cartItems = ref.watch(cartServiceProvider).items;

    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    final bool isSmallScreen = width < 900;

    return Scaffold(
      backgroundColor: venaBg,
      appBar: isSmallScreen
          ? AppBar(
              elevation: 0,
              backgroundColor: venaBg,
              foregroundColor: venaDark,
              titleSpacing: 16,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.storeName ?? 'venastudio',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: venaDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: venaMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: venaDark),
                  onPressed: () {
                    setState(() {
                      showSearch = !showSearch;
                    });
                  },
                ),
                if (cartItems.isNotEmpty)
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.shopping_bag_outlined,
                          color: venaDark,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CartPage(),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: venaTeal,
                          child: Text(
                            cartItems.length.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffF8FDFF), Color(0xffEEF9FB), Color(0xffE4F7FA)],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 14,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 12 : 24,
                  isSmallScreen ? 8 : 22,
                  isSmallScreen ? 12 : 14,
                  0,
                ),
                child: Column(
                  children: [
                    if (!isSmallScreen)
                      _topMenu(
                        title: user?.storeName ?? 'venastudio',
                        subTitle: DateFormat(
                          'dd MMMM yyyy',
                        ).format(DateTime.now()),
                        action: _search(theme, businessServices),
                        theme: theme,
                      ),

                    if (showSearch && isSmallScreen)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _mobileSearch(theme, businessServices),
                      ),

                    const SizedBox(height: 18),

                    _categoryTabs(theme),

                    const SizedBox(height: 18),

                    _productGrid(servicesState, theme),
                  ],
                ),
              ),
            ),

            if (!isSmallScreen && width > 900)
              SizedBox(width: 390, child: CartSummaryWidget(height: height)),

            if (isSmallScreen && _isCartVisible)
              CartSummaryWidget(height: height),
          ],
        ),
      ),
    );
  }

  Widget _topMenu({
    required String title,
    required String subTitle,
    required Widget action,
    required ThemeConfig theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: venaLine.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: venaTeal.withOpacity(0.08),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: Row(
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: venaTeal.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: venaTeal.withOpacity(0.18)),
                  ),
                  child: const Icon(
                    Icons.spa_outlined,
                    color: venaTeal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: venaDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: venaMuted,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            subTitle,
                            style: const TextStyle(
                              color: venaMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: action),
        ],
      ),
    );
  }

  Widget _search(ThemeConfig theme, ServicesState businessServices) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: venaLine),
          boxShadow: [
            BoxShadow(
              color: venaTeal.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: venaMuted, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  color: venaDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search services...',
                  hintStyle: TextStyle(
                    color: venaMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                FocusScope.of(context).unfocus();

                if (businessServices is ServicesLoaded) {
                  SearchServices.show(
                    context,
                    List.from(businessServices.services)..removeWhere(
                      (element) => element.type.toLowerCase() != 'main',
                    ),
                  );
                }
              },
              child: Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: venaTeal.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: venaTeal,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileSearch(ThemeConfig theme, ServicesState businessServices) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: venaLine),
        boxShadow: [
          BoxShadow(
            color: venaTeal.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: venaMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              autofocus: true,
              controller: searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                color: venaDark,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'Search services...',
                hintStyle: TextStyle(color: venaMuted),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              FocusScope.of(context).unfocus();

              if (businessServices is ServicesLoaded) {
                SearchServices.show(
                  context,
                  List.from(businessServices.services)..removeWhere(
                    (element) => element.type.toLowerCase() != 'main',
                  ),
                );
              }
            },
            icon: const Icon(Icons.tune_rounded, color: venaTeal),
          ),
        ],
      ),
    );
  }

  Widget _categoryTabs(ThemeConfig theme) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _categoryPill(
            icon: Icons.grid_view_rounded,
            title: 'All',
            isActive: selectedCategory == 'All',
            theme: theme,
            onTap: () {
              setState(() {
                selectedCategory = 'All';
              });
            },
          ),
          ...allCategories.map((category) {
            final isActive = selectedCategory == category;

            return _categoryPill(
              icon: _categoryIcon(category),
              title: category,
              isActive: isActive,
              theme: theme,
              onTap: () {
                setState(() {
                  selectedCategory = category;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'decoration':
        return Icons.auto_awesome_rounded;
      case 'tips gel':
        return Icons.water_drop_outlined;
      case 'acrylic':
        return Icons.link_rounded;
      case 'plain gel':
        return Icons.brush_outlined;
      default:
        return Icons.spa_outlined;
    }
  }

  Widget _categoryPill({
    required IconData icon,
    required String title,
    required bool isActive,
    required ThemeConfig theme,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isActive ? venaTeal : Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isActive ? venaTeal : venaLine, width: 1),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: venaTeal.withOpacity(0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: isActive ? Colors.white : venaMuted, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : venaDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productGrid(ServicesState servicesState, ThemeConfig theme) {
    if (servicesState is ServicesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(
          color: venaTeal,
          backgroundColor: Color(0xffD8F4F8),
        ),
      );
    }

    if (servicesState is ServicesError) {
      return Expanded(
        child: Center(
          child: Text(
            "Error: ${servicesState.error}",
            style: const TextStyle(
              color: Color(0xffD94B4B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (servicesState is ServicesLoaded) {
      final List<Savis> services = servicesState.services.where((service) {
        final isCategoryMatch =
            selectedCategory == 'All' ||
            service.type.toLowerCase().contains(selectedCategory.toLowerCase());

        final isSearchMatch = service.name.toLowerCase().contains(
          searchController.text.toLowerCase(),
        );

        return isCategoryMatch && isSearchMatch;
      }).toList();

      if (services.isEmpty) {
        return Expanded(child: emptyState(ref, text: 'No services available'));
      }

      return Expanded(
        child: RefreshIndicator(
          color: venaTeal,
          onRefresh: () async {
            ref.invalidate(businessServicesProvider);
            ref.invalidate(cartServiceProvider);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;

              int crossAxisCount;
              if (width >= 1180) {
                crossAxisCount = 5;
              } else if (width >= 900) {
                crossAxisCount = 4;
              } else if (width >= 620) {
                crossAxisCount = 3;
              } else {
                crossAxisCount = 2;
              }

              return GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: width >= 620 ? 220 : 230,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];

                  return SavisCard(
                    savis: service,
                    width: width,
                    onAdd: () => onAdd(ref, service),
                  );
                },
              );
            },
          ),
        ),
      );
    }

    return Expanded(child: emptyState(ref, text: 'No data available'));
  }

  void onAdd(WidgetRef ref, Savis savis) {
    final prev = ref.read(cartServiceProvider).items;
    final existsIndex = prev.indexWhere((element) => element.id == savis.id);

    if (existsIndex == -1) {
      final newSavis = savis.copyWith(quantity: 1);
      ref.read(cartServiceProvider.notifier).add(newSavis);
    } else {
      ref
          .read(cartServiceProvider.notifier)
          .changeQnty(prev[existsIndex], prev[existsIndex].quantity + 1);
    }
  }
}

class CartSummaryWidget extends ConsumerWidget {
  final double height;

  const CartSummaryWidget({super.key, required this.height});

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaSurface = Color(0xffFFFFFF);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.watch(cartServiceProvider);
    final cartItems = cartNotifier.items;
    final cartPhone = cartNotifier.phone;

    return Container(
      height: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 22, 22, 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: venaLine.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            color: venaTeal.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cartHeader(cartItems, cartPhone, context, ref),
          const SizedBox(height: 16),
          Expanded(
            child: cartItems.isEmpty
                ? _emptyCart()
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      return CartItemWidget(
                        item: cartItems[index],
                        ref: ref,
                        theme: ref.watch(themeServicesProvider),
                        cartService: ref.watch(cartServiceProvider),
                        settingsService: ref.watch(settingsServicesProvider),
                        agentsService: ref.watch(agentsServicesProvider),
                        onRemoveItem: (item) {
                          ref.read(cartServiceProvider.notifier).remove(item);
                        },
                        onTapAdd: (value) {
                          ref
                              .read(cartServiceProvider.notifier)
                              .changeQnty(value, value.quantity + 1);
                        },
                        onTapRemove: (value) {
                          ref
                              .read(cartServiceProvider.notifier)
                              .changeQnty(value, value.quantity - 1);
                        },
                        onRemoveDiscount: (value) {
                          ref
                              .read(cartServiceProvider.notifier)
                              .setDiscount(value, 0);
                        },
                        onSetDiscount: (value) {
                          ref
                              .read(cartServiceProvider.notifier)
                              .setDiscount(value.savis, value.discount);
                        },
                        onTapAssign: (value) {
                          ref.read(cartServiceProvider.notifier).agent =
                              SmartAssignmentBridge.entry(value);
                        },
                        onSetAddons: (value) {
                          ref
                              .read(cartServiceProvider.notifier)
                              .addAddon(
                                savisId: value.savis,
                                addons: value.addons,
                              );
                        },
                      );
                    },
                  ),
          ),
          _orderTotalSection(context, cartItems),
        ],
      ),
    );
  }

  Widget _cartHeader(
    List<Savis> cartItems,
    String? cartPhone,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: venaTeal.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: venaTeal.withOpacity(0.18)),
          ),
          child: const Icon(
            Icons.shopping_bag_outlined,
            color: venaTeal,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Order',
                style: TextStyle(
                  color: venaDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Service checkout',
                style: TextStyle(
                  color: venaMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: venaTeal.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: venaTeal.withOpacity(0.18)),
          ),
          child: Text(
            '${cartItems.length}',
            style: const TextStyle(
              color: venaTeal,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
        if (cartPhone != null && cartPhone.isNotEmpty)
          PopupMenuButton<_MenuActions>(
            icon: const Icon(Icons.more_vert_rounded, color: venaDark),
            color: Colors.white,
            itemBuilder: (BuildContext context) => _MenuActions.values
                .map(
                  (e) => PopupMenuItem<_MenuActions>(
                    value: e,
                    child: Row(
                      children: [
                        Icon(e.logo(), color: venaDark),
                        const SizedBox(width: 16),
                        Text(
                          e.name(),
                          style: const TextStyle(
                            color: venaDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onSelected: (_MenuActions item) {
              if (item == _MenuActions.customer) {
                context.go('/customer_screen?isAgent=false');
              } else if (item == _MenuActions.exitmode) {
                ref.read(cartServiceProvider.notifier).clearState();
              }
            },
          ),
      ],
    );
  }

  Widget _emptyCart() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: venaBg.withOpacity(0.65),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: venaLine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              color: venaTeal.withOpacity(0.75),
              size: 46,
            ),
            const SizedBox(height: 12),
            const Text(
              'Cart is empty',
              style: TextStyle(
                color: venaDark,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select services to start checkout',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: venaMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTotalSection(BuildContext context, List<Savis> cartItems) {
    final subtotal = cartItems.fold(
      0.0,
      (sum, item) =>
          sum +
          ((double.tryParse(item.amount.toString()) ?? 0.0) * item.quantity),
    );

    final totalDiscount = cartItems.fold(
      0.0,
      (sum, item) =>
          sum +
          ((double.tryParse(item.discount.toString()) ?? 0.0) * item.quantity),
    );

    final total = subtotal - totalDiscount;
    final bool isEmpty = cartItems.isEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: venaLine.withOpacity(0.95))),
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', subtotal.toDouble().money),
          if (totalDiscount > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow(
              'Discount',
              '-${totalDiscount.toDouble().money}',
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 12),
          _buildTotalRow('Total', total.toDouble().money, isTotal: true),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isEmpty
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) {
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.all(24),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 860,
                                maxHeight: 720,
                              ),
                              child: ServiceCartPage(
                                cartItems: cartItems,
                                isModal: true,
                              ),
                            ),
                          );
                        },
                      );
                    },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: venaTeal,
                disabledBackgroundColor: venaTeal.withOpacity(0.25),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white.withOpacity(0.72),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_checkout_rounded, size: 21),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Proceed to Checkout',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.lock_outline_rounded, color: venaMuted, size: 14),
              SizedBox(width: 6),
              Text(
                'Secure checkout',
                style: TextStyle(
                  color: venaMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              fontSize: isTotal ? 18 : 13,
              color: isDiscount
                  ? const Color(0xff13A76B)
                  : isTotal
                  ? venaDark
                  : venaMuted,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: isTotal ? 22 : 13,
            color: isDiscount
                ? const Color(0xff13A76B)
                : isTotal
                ? venaTeal
                : venaDark,
          ),
        ),
      ],
    );
  }
}

class CartItemWidget extends StatefulWidget {
  final Savis item;
  final WidgetRef ref;
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

  const CartItemWidget({
    super.key,
    required this.item,
    required this.ref,
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

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  bool showButtons = false;

  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);

  Map<String, String>? get _serviceAssignment {
    return widget.cartService.assigned?['${widget.item.id}'];
  }

  String get _assignedBeauticianName {
    return _serviceAssignment?['agentName'] ?? '';
  }

  int get _assignedProductCount {
    final raw = _serviceAssignment?['smartAssignment'];
    if (raw == null || raw.trim().isEmpty) return 0;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final products = decoded['products'];
        if (products is List) return products.length;

        final productsJson = decoded['products_json'];
        if (productsJson is String && productsJson.trim().isNotEmpty) {
          final inner = jsonDecode(productsJson);
          if (inner is List) return inner.length;
        }
      }
    } catch (_) {}

    return 0;
  }

  bool get _hasServiceAssignment {
    return _assignedBeauticianName.trim().isNotEmpty;
  }

  Widget _assignmentSummary() {
    if (!_hasServiceAssignment) return const SizedBox.shrink();

    final count = _assignedProductCount;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffECFFF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xff19B37A).withOpacity(.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.assignment_turned_in_rounded,
            size: 17,
            color: Color(0xff19B37A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Assigned to $_assignedBeauticianName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xff087A50),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xff19B37A).withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count item${count == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Color(0xff087A50),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(widget.item.amount.toString()) ?? 0.0;
    final discount = double.tryParse(widget.item.discount.toString()) ?? 0.0;
    final hasDiscount = discount > 0;
    final payable = amount - discount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: venaLine.withOpacity(0.95)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: venaTeal.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  color: venaTeal,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: venaDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hasDiscount ? payable.money : amount.money,
                    style: const TextStyle(
                      color: venaTeal,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (hasDiscount)
                    Text(
                      amount.money,
                      style: const TextStyle(
                        color: venaMuted,
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _removeItem,
                child: Container(
                  height: 26,
                  width: 26,
                  decoration: BoxDecoration(
                    color: venaDanger.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: venaDanger,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          _assignmentSummary(),
          const SizedBox(height: 12),
          Row(
            children: [
              _qtyButton(
                icon: Icons.remove_rounded,
                color: venaMuted,
                onTap: () =>
                    _changeQuantity((widget.item.quantity - 1).toInt()),
              ),
              const SizedBox(width: 10),
              Text(
                widget.item.quantity.toString(),
                style: const TextStyle(
                  color: venaDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              _qtyButton(
                icon: Icons.add_rounded,
                color: venaTeal,
                onTap: () =>
                    _changeQuantity((widget.item.quantity + 1).toInt()),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() => showButtons = !showButtons);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffEEF9FB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: venaLine),
                  ),
                  child: Row(
                    children: [
                      Text(
                        showButtons ? 'Less' : 'Options',
                        style: const TextStyle(
                          color: venaDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        showButtons
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: venaDark,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (showButtons) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildAssignButton()),
                const SizedBox(width: 8),
                if (widget.settingsService.showDiscount) ...[
                  Expanded(child: _buildDiscountButton()),
                  const SizedBox(width: 8),
                ],
                Expanded(child: _buildAddonButton()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 31,
        width: 31,
        decoration: BoxDecoration(
          color: color.withOpacity(0.11),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildAssignButton() {
    return TextButton(
      onPressed: () async {
        final agents = widget.agentsService.value ?? [];
        final result = await SmartAssignmentBridge.pickResult(
          context,
          settings: widget.settingsService,
          agents: agents,
          serviceLike: widget.item,
          existingOrderMode: false,
        );
        if (result != null) {
          widget.onTapAssign(result);
        }
      },
      style: _buttonStyle(),
      child: Text(_hasServiceAssignment ? 'Reassign' : 'Assign'),
    );
  }

  Widget _buildDiscountButton() {
    return TextButton(
      onPressed: () {
        ProductDiscountEdit.show(
          context,
          discount: double.tryParse(widget.item.discount.toString()) ?? 0.0,
          remove: () {
            Navigator.pop(context);
            widget.onRemoveDiscount(widget.item);
          },
        ).then((value) {
          if (value != null &&
              value <=
                  (double.tryParse(widget.item.amount.toString()) ?? 0.0)) {
            widget.onSetDiscount((savis: widget.item, discount: value));
          }
        });
      },
      style: _buttonStyle(),
      child: const Text('Discount'),
    );
  }

  Widget _buildAddonButton() {
    return TextButton(
      onPressed: () async {
        final addons = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderAddAddon(
              orderId: 0,
              itemId: widget.item.id,
              prevAddons: widget.cartService.addons
                  .where((e) => e['mainServiceId'] == widget.item.id)
                  .toList(),
            ),
          ),
        );

        if (addons != null) {
          widget.onSetAddons((
            savis: widget.item.id,
            addons: addons as List<Map<String, dynamic>>,
          ));
        }
      },
      style: _buttonStyle(),
      child: const Text('Addon +'),
    );
  }

  ButtonStyle _buttonStyle() {
    return TextButton.styleFrom(
      backgroundColor: const Color(0xffEEF9FB),
      foregroundColor: venaDark,
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: venaLine),
      ),
    );
  }

  void _removeItem() {
    widget.ref.read(cartServiceProvider.notifier).remove(widget.item);
  }

  void _changeQuantity(int newQuantity) {
    if (newQuantity > 0) {
      widget.ref
          .read(cartServiceProvider.notifier)
          .changeQnty(widget.item, newQuantity);
    } else {
      _removeItem();
    }
  }
}

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaDark = Color(0xff07304A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 600;

    final cartNotifier = ref.watch(cartServiceProvider);
    final cartPhone = cartNotifier.phone;

    return Scaffold(
      backgroundColor: venaBg,
      appBar: isSmallScreen
          ? AppBar(
              elevation: 0,
              centerTitle: true,
              title: const Text(
                "Current Order",
                style: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
              ),
              backgroundColor: venaBg,
              foregroundColor: venaDark,
              actions: cartPhone != null && cartPhone.isNotEmpty
                  ? [
                      PopupMenuButton<_MenuActions>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: venaDark,
                        ),
                        color: Colors.white,
                        itemBuilder: (BuildContext context) =>
                            _MenuActions.values.map((e) {
                              return PopupMenuItem<_MenuActions>(
                                value: e,
                                child: Row(
                                  children: [
                                    Icon(e.logo(), color: venaDark),
                                    const SizedBox(width: 16),
                                    Text(
                                      e.name(),
                                      style: const TextStyle(
                                        color: venaDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        onSelected: (_MenuActions item) {
                          if (item == _MenuActions.customer) {
                            context.go('/customer_screen?isAgent=false');
                          } else if (item == _MenuActions.exitmode) {
                            ref.read(cartServiceProvider.notifier).clearState();
                          }
                        },
                      ),
                    ]
                  : null,
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: CartSummaryWidget(height: height),
        ),
      ),
    );
  }
}

enum _MenuActions {
  customer,
  exitmode;

  String name() => switch (this) {
    _MenuActions.customer => 'Customer Portal',
    _MenuActions.exitmode => 'Exit Mode',
  };

  IconData logo() => switch (this) {
    _MenuActions.customer => Icons.co_present_outlined,
    _MenuActions.exitmode => Icons.exit_to_app_rounded,
  };
}
