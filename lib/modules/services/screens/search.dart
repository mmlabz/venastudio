import 'package:venastudio/common.dart';

class SearchServices extends ConsumerStatefulWidget {
  const SearchServices({super.key, required this.savises});
  final List<Savis> savises;

  static show(BuildContext context, List<Savis> savises) {
    final mobileSize = SrceenType.type(context.sz).isMobile;
    if (mobileSize) {
      final container = ProviderScope.containerOf(context, listen: false);
      final theme = container.read(themeServicesProvider);
      return showSearch(
        context: context,
        useRootNavigator: true,
        delegate: MobileServicesSearch(savises: savises, theme: theme),
      );
    }
    return showDialog(
      useRootNavigator: false,
      context: context,
      builder: (_) {
        return SearchServices(savises: savises);
      },
    );
  }

  @override
  ConsumerState<SearchServices> createState() => _SearchServicesState();
}

class _SearchServicesState extends ConsumerState<SearchServices> {
  final TextEditingController _controller = TextEditingController();
  late List<Savis> savises = List.from(widget.savises);
  @override
  Widget build(BuildContext context) {
    final allWidth = context.sz.width;
    final mWidth = allWidth / 2;
    final width = mWidth < 380.0 ? allWidth : mWidth;
    final cartitems = ref.watch(cartServiceProvider).items;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            width: width,
            child: Material(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        controller: _controller,
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
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Search ...',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          savises = List.from(widget.savises);
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            flex: 2,
            child: SizedBox(
              width: width - 30,
              child: Material(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: savises.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: savises.length,
                        itemBuilder: (context, index) {
                          final savis = savises[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SavisCard(
                              savis: savis,
                              width: width,
                              onEdit: null,
                              cartQuantity: () {
                                return SavisCard.quantityInCart(
                                  savis,
                                  cartitems,
                                );
                              }(),
                              onRemove: () => ref
                                  .read(cartServiceProvider.notifier)
                                  .remove(savis),
                              onAdd: () => SavisCard.onAddTap(savis, ref),
                            ),
                          );
                        },
                      )
                    : const Center(child: Text('')),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class MobileServicesSearch extends SearchDelegate {
  MobileServicesSearch({required this.savises, required this.theme});
  final List<Savis> savises;
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
  List<Widget>? buildActions(BuildContext context) {
    return null;
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return null;
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildOutput();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildOutput();
  }

  Widget _buildOutput() {
    final results = savises.where(
      (element) => element.name.toLowerCase().contains(query.toLowerCase()),
    );
    return Consumer(
      builder: (context, ref, _) {
        final cartitems = ref.watch(cartServiceProvider).items;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final savis = results.elementAt(index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SavisCard(
                savis: savis,
                width: 100,
                onEdit: null,
                cartQuantity: () {
                  return SavisCard.quantityInCart(savis, cartitems);
                }(),
                onRemove: () =>
                    ref.read(cartServiceProvider.notifier).remove(savis),
                onAdd: () => SavisCard.onAddTap(savis, ref),
              ),
            );
          },
        );
      },
    );
  }
}
