import 'package:venastudio/common.dart';

class EditServicesPage extends ConsumerStatefulWidget {
  const EditServicesPage({super.key});

  @override
  ConsumerState<EditServicesPage> createState() => _EditServicesPageState();
}

class _EditServicesPageState extends ConsumerState<EditServicesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  @override
  void dispose() {
    _tabController.dispose();
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
    final allitems = businessServices.services;

    final services = allitems
        .where((x) => x.type.toLowerCase() == 'main')
        .toList();

    final addons = allitems
        .where((x) => x.type.toLowerCase() == 'addon')
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
          style: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: _tabBar(),
        ),
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
        child: TabBarView(
          controller: _tabController,
          children: [_items(services), _items(addons)],
        ),
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

  Widget _tabBar() {
    return Container(
      height: 46,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
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

  Widget _items(List<Savis> items) {
    if (items.isEmpty) {
      return emptyState(ref, text: 'No items available');
    }

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
                  child: SavisCard(
                    savis: savis,
                    width: double.infinity,
                    showAddButton: false,
                    onEdit: () => _editService(savis),
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
        context.showToast(
          'Service added',
          textColor: theme.textIconPrimaryColor,
        );
        ref.invalidate(businessServicesProvider);
      }
    });
  }

  void _editService(Savis savis) {
    final theme = ref.read(themeServicesProvider);

    EditSavisPage.show(context, savis).then((value) {
      if (value == '200') {
        context.showToast(
          'Updated successfully',
          textColor: theme.textIconPrimaryColor,
        );
        ref.invalidate(businessServicesProvider);
      }
    });
  }
}
