import 'package:venastudio/common.dart';

typedef ServiceCallback = void Function(WidgetRef ref, Savis addon);
typedef ServiceCartCallback = num Function(Savis savis, List<Savis> cartitems);

class SearchAddServices extends ConsumerStatefulWidget {
  const SearchAddServices({
    super.key,
    required this.savises,
    required this.onAdd,
    required this.quantityInCart,
  });

  final List<Savis> savises;
  final ServiceCallback onAdd;
  final ServiceCartCallback quantityInCart;

  static show(
    BuildContext context,
    List<Savis> savises,
    ServiceCallback onAdd,
    ServiceCartCallback quantityInCart,
  ) {
    final mobileSize = SrceenType.type(context.sz).isMobile;
    if (mobileSize) {
      return showSearch(
        context: context,
        useRootNavigator: true,
        delegate: MobileAddServicesSearch(
          savises: savises,
          onAdd: onAdd,
          quantityInCart: quantityInCart,
        ),
      );
    }
    return showDialog(
      useRootNavigator: false,
      context: context,
      builder: (_) {
        return SearchAddServices(
          savises: savises,
          onAdd: onAdd,
          quantityInCart: quantityInCart,
        );
      },
    );
  }

  @override
  ConsumerState<SearchAddServices> createState() => _SearchAddServicesState();
}

class _SearchAddServicesState extends ConsumerState<SearchAddServices> {
  final TextEditingController _controller = TextEditingController();
  late List<Savis> savises = List.from(widget.savises);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final cartitems = ref.watch(servicesToAdd);
    final theme = ref.watch(themeServicesProvider);

    return Container(
      color: theme.secondaryBackGround,
      child: Padding(
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
                      cursorColor: theme.textIconPrimaryColor,
                      onChanged: (value) {
                        final searched = widget.savises.where(
                          (element) => element.name.toLowerCase().contains(
                            value.toLowerCase(),
                          ),
                        );
                        setState(() {
                          savises = List.from(searched);
                        });
                      },
                      decoration: InputDecoration.collapsed(
                        hintText: 'Search services ...',
                        hintStyle: TextStyle(color: theme.textIconPrimaryColor),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        savises = List.from(widget.savises);
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
              child: SizedBox(
                child: savises.isNotEmpty
                    ? GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: width > 1200
                              ? 5
                              : width > 800
                              ? 4
                              : width > 600
                              ? 3
                              : 2,
                          childAspectRatio: (width < 400)
                              ? 0.8 / 1.4
                              : 0.8 / 1.1,
                        ),
                        itemCount: savises.length,
                        itemBuilder: (context, index) {
                          final savis = savises[index];
                          return SavisCard(
                            savis: savis,
                            width: width,
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
                            cartQuantity: widget.quantityInCart(
                              savis,
                              cartitems,
                            ),
                            onAdd: () => widget.onAdd(ref, savis),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          'No services found',
                          style: TextStyle(color: theme.activeTextIconColor),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileAddServicesSearch extends SearchDelegate {
  MobileAddServicesSearch({
    required this.savises,
    required this.onAdd,
    required this.quantityInCart,
  });

  final List<Savis> savises;
  final ServiceCallback onAdd;
  final ServiceCartCallback quantityInCart;

  @override
  ThemeData appBarTheme(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    final theme = container.read(themeServicesProvider);
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: theme.secondaryBackGround,
      appBarTheme: AppBarTheme(
        backgroundColor: theme.secondaryBackGround,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textIconPrimaryColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: theme.secondaryBackGround,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: theme.textIconSecondaryColor),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: theme.textIconPrimaryColor),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => null;

  @override
  Widget? buildLeading(BuildContext context) => null;

  @override
  Widget buildResults(BuildContext context) => _buildOutput();

  @override
  Widget buildSuggestions(BuildContext context) => _buildOutput();

  Widget _buildOutput() {
    final results = savises.where(
      (element) => element.name.toLowerCase().contains(query.toLowerCase()),
    );
    return Consumer(
      builder: (context, ref, _) {
        final theme = ref.watch(themeServicesProvider);
        final cartitems = ref.watch(servicesToAdd);
        return Container(
          color: theme.secondaryBackGround,
          child: GridView.builder(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8 / 1.1,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final savis = results.elementAt(index);
              return SavisCard(
                savis: savis,
                width: 100,
                onAdd: () => onAdd(ref, savis),
                onRemove: () {
                  final prev = List<Savis>.from(cartitems);
                  prev.removeWhere((element) => element.id == savis.id);
                  ref.read(servicesToAdd.notifier).update((state) => prev);
                },
                onEdit: null,
                cartQuantity: quantityInCart(savis, cartitems),
              );
            },
          ),
        );
      },
    );
  }
}
