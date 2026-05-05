import 'package:venastudio/common.dart';

typedef AddonCallback = void Function(WidgetRef ref, Savis addon);

class SearchAddons extends ConsumerStatefulWidget {
  const SearchAddons({super.key, required this.addons, required this.onAdd});
  final List<Savis> addons;
  final AddonCallback onAdd;

  static show(BuildContext context, List<Savis> addons, AddonCallback onAdd) {
    final mobileSize = SrceenType.type(context.sz).isMobile;

    if (mobileSize) {
      final container = ProviderScope.containerOf(context, listen: false);
      final theme = container.read(themeServicesProvider);
      return showSearch(
        context: context,
        useRootNavigator: true,
        delegate: MobileAddonSearch(addons: addons, onAdd: onAdd, theme: theme),
      );
    }
    return showDialog(
      useRootNavigator: false,
      context: context,
      builder: (_) {
        return SearchAddons(addons: addons, onAdd: onAdd);
      },
    );
  }

  @override
  ConsumerState<SearchAddons> createState() => _SearchAddonsState();
}

class _SearchAddonsState extends ConsumerState<SearchAddons> {
  final TextEditingController _controller = TextEditingController();
  late List<Savis> addons = List.from(widget.addons);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final theme = ref.watch(themeServicesProvider);
    final cartitems = ref.watch(addonToAdd);

    return Scaffold(
      backgroundColor: theme.secondaryBackGround,
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Column(
          children: [
            SizedBox(
              width: width,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: theme.textIconPrimaryColor,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      readOnly: true,
                      controller: _controller,
                      style: TextStyle(color: theme.textIconPrimaryColor),
                      onChanged: (value) {
                        final searched = widget.addons.where(
                          (element) => element.name.toLowerCase().contains(
                            value.toLowerCase(),
                          ),
                        );
                        setState(() {
                          addons = List.from(searched);
                        });
                      },
                      decoration: InputDecoration.collapsed(
                        hintText: 'Search addons ...',
                        hintStyle: TextStyle(color: theme.textIconPrimaryColor),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        addons = List.from(widget.addons);
                      });
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.textIconPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: addons.isNotEmpty
                  ? GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: width > 1200
                            ? 5
                            : width > 800
                            ? 4
                            : width > 600
                            ? 3
                            : 2,
                        childAspectRatio: (width < 400) ? 0.8 / 1.3 : 0.8 / 1.1,
                      ),
                      itemCount: addons.length,
                      itemBuilder: (context, index) {
                        final addon = addons[index];
                        return SavisCard(
                          savis: addon,
                          width: width,
                          cartQuantity: OrderAddAddon.quantityInCart(
                            addon,
                            cartitems,
                          ),
                          onRemove: () {
                            final prev = List<Savis>.from(cartitems);
                            prev.removeWhere(
                              (element) => element.id == addon.id,
                            );
                            ref
                                .read(addonToAdd.notifier)
                                .update((state) => prev);
                          },
                          onAdd: () => widget.onAdd(ref, addon),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'No addons found',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileAddonSearch extends SearchDelegate {
  MobileAddonSearch({
    required this.addons,
    required this.onAdd,
    required this.theme,
  });
  final List<Savis> addons;
  final AddonCallback onAdd;
  final ThemeConfig theme;

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: theme.secondaryBackGround,
      appBarTheme: AppBarTheme(
        backgroundColor: theme.secondaryBackGround,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
      ),
    );
  }

  @override
  TextStyle get searchFieldStyle =>
      const TextStyle(color: Colors.white, fontSize: 16);

  @override
  List<Widget>? buildActions(BuildContext context) => null;

  @override
  Widget? buildLeading(BuildContext context) => null;

  @override
  Widget buildResults(BuildContext context) => _buildOutput();

  @override
  Widget buildSuggestions(BuildContext context) => _buildOutput();

  Widget _buildOutput() {
    final results = addons.where(
      (element) => element.name.toLowerCase().contains(query.toLowerCase()),
    );
    return Consumer(
      builder: (context, ref, _) {
        final cartitems = ref.watch(addonToAdd);
        return Container(
          color: const Color(0xff17181f),
          child: GridView.builder(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8 / 1.4,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final addon = results.elementAt(index);
              return SavisCard(
                savis: addon,
                width: 100,
                onEdit: null,
                cartQuantity: OrderAddAddon.quantityInCart(addon, cartitems),
                onRemove: () {
                  final prev = List<Savis>.from(cartitems);
                  prev.removeWhere((element) => element.id == addon.id);
                  ref.read(addonToAdd.notifier).update((state) => prev);
                },
                onAdd: () => onAdd(ref, addon),
              );
            },
          ),
        );
      },
    );
  }
}
