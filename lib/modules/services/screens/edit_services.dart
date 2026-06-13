import 'package:venastudio/common.dart';

class EditServicesPage extends ConsumerStatefulWidget {
  const EditServicesPage({super.key});

  @override
  ConsumerState<EditServicesPage> createState() => _EditServicesPageState();
}

class _EditServicesPageState extends ConsumerState<EditServicesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  bool _showHidden = false;

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessServices = ref.watch(businessServicesProvider);
    final allItems = businessServices.services;

    final scopedItems = _showHidden
        ? allItems
        : allItems.where((item) => item.isVisible).toList();

    final searchedItems = _filterBySearch(scopedItems);

    final services = searchedItems
        .where((item) => item.type.toLowerCase().trim() == 'main')
        .toList();

    final addons = searchedItems
        .where((item) => item.type.toLowerCase().trim() == 'addon')
        .toList();

    return Scaffold(
      backgroundColor: venaBg,
      appBar: AppBar(
        backgroundColor: venaBg,
        foregroundColor: venaDark,
        elevation: 0,
        centerTitle: true,
        leading: context.backIcon(ref, _goBack),
        title: const Text(
          'Edit Services',
          style: TextStyle(
            color: venaDark,
            fontWeight: FontWeight.w900,
            fontSize: 21,
          ),
        ),
      ),
      body: Column(
        children: [
          _topControls(),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xffF8FDFF),
                    Color(0xffEEF9FB),
                    Color(0xffE4F7FA),
                  ],
                ),
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _items(services, emptyText: _emptyText('services')),
                  _items(addons, emptyText: _emptyText('addons')),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: venaTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Service',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        onPressed: _addService,
      ),
    );
  }

  Widget _topControls() {
    return Container(
      color: venaBg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tabBar(),
          const SizedBox(height: 10),
          _searchBar(),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        border: Border.all(color: venaLine),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: const BoxDecoration(color: venaTeal),
        labelColor: Colors.white,
        unselectedLabelColor: venaMuted,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        tabs: const [
          Tab(text: 'Services'),
          Tab(text: 'Addons'),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              enabled: true,
              readOnly: false,
              autofocus: false,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              onTap: () => _searchFocusNode.requestFocus(),
              onChanged: (value) {
                if (!mounted) return;
                setState(() => _searchQuery = value);
              },
              style: const TextStyle(
                color: venaDark,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search services, addons, price or commission...',
                hintStyle: const TextStyle(
                  color: venaMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: venaMuted),
                suffixIcon: _searchQuery.trim().isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _searchFocusNode.requestFocus();
                        },
                        icon: const Icon(Icons.close_rounded, color: venaMuted),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: venaLine),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: venaLine),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: venaTeal, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: _showHidden ? 'Hide inactive services' : 'Show hidden services',
          child: InkWell(
            onTap: () => setState(() => _showHidden = !_showHidden),
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: _showHidden ? venaTeal : Colors.white,
                border: Border.all(color: _showHidden ? venaTeal : venaLine),
              ),
              child: Icon(
                _showHidden
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: _showHidden ? Colors.white : venaMuted,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Savis> _filterBySearch(List<Savis> items) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return items;

    return items.where((item) {
      final name = item.name.toLowerCase();
      final type = item.type.toLowerCase();
      final amount = item.amount.toString().toLowerCase();
      final commission = item.commission.toString().toLowerCase();

      return name.contains(query) ||
          type.contains(query) ||
          amount.contains(query) ||
          commission.contains(query);
    }).toList();
  }

  String _emptyText(String tabName) {
    if (_searchQuery.trim().isNotEmpty) {
      return 'No $tabName match "$_searchQuery"';
    }
    if (!_showHidden) return 'No visible $tabName available';
    return 'No $tabName available';
  }

  Widget _items(List<Savis> items, {required String emptyText}) {
    if (items.isEmpty) return emptyState(ref, text: emptyText);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1200
            ? 5
            : width > 900
                ? 4
                : width > 600
                    ? 3
                    : 2;
        final aspectRatio = width < 420 ? 0.72 : 0.78;

        return GridView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final savis = items[index];
            return Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: savis.isVisible ? 1 : 0.48,
                    child: SavisCard(
                      savis: savis,
                      width: double.infinity,
                      showAddButton: false,
                      onEdit: () => _editService(savis),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => _editService(savis),
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
                        border: Border.all(color: venaLine),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 17,
                        color: venaDark,
                      ),
                    ),
                  ),
                ),
                if (!savis.isVisible)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffD94B4B).withOpacity(0.95),
                        border: Border.all(color: Colors.white.withOpacity(0.5)),
                      ),
                      child: const Text(
                        'Hidden',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _addService() {
    final theme = ref.read(themeServicesProvider);
    EditSavisPage.show(context).then((value) {
      if (value == '200') {
        context.showToast('Service added', textColor: theme.textIconPrimaryColor);
        ref.invalidate(businessServicesProvider);
      }
    });
  }

  void _editService(Savis savis) {
    final theme = ref.read(themeServicesProvider);
    EditSavisPage.show(context, savis).then((value) {
      if (value == '200') {
        context.showToast('Updated successfully', textColor: theme.textIconPrimaryColor);
        ref.invalidate(businessServicesProvider);
      }
    });
  }
}
