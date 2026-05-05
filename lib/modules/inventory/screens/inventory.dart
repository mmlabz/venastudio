import 'package:intl/intl.dart';
import 'package:venastudio/common.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTimeRange? dateRange;
  String productSearch = "";
  String distributedSearch = "";
  String availableSearch = "";

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);
  static const Color venaSuccess = Color(0xff13A76B);

  final List<Map<String, dynamic>> allProducts = [
    {
      "name": "Shampoo",
      "variants": ["500ml", "1L"],
      "branches": {
        "Branch 1": {"500ml": 10, "1L": 15},
        "Branch 2": {"500ml": 8, "1L": 5},
      },
      "warehouse": {"500ml": 30, "1L": 20},
    },
    {
      "name": "Conditioner",
      "variants": ["250ml", "500ml"],
      "branches": {
        "Branch 1": {"250ml": 5, "500ml": 10},
        "Branch 2": {"250ml": 3, "500ml": 7},
      },
      "warehouse": {"250ml": 15, "500ml": 10},
    },
  ];

  final List<Map<String, dynamic>> branches = [
    {
      "name": "Branch 1",
      "products": [
        {
          "name": "Shampoo",
          "variants": {"500ml": 10, "1L": 15},
        },
        {
          "name": "Conditioner",
          "variants": {"250ml": 5, "500ml": 10},
        },
      ],
    },
    {
      "name": "Branch 2",
      "products": [
        {
          "name": "Face Cream",
          "variants": {"100ml": 20, "200ml": 12},
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 700;

    return Scaffold(
      backgroundColor: venaBg,
      appBar: isSmallScreen
          ? AppBar(
              backgroundColor: venaBg,
              foregroundColor: venaDark,
              elevation: 0,
              title: const Text(
                'Inventory',
                style: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: _buildTabBar(),
              ),
            )
          : null,
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
        child: Column(
          children: [
            if (!isSmallScreen) _desktopHeader(),
            _dateRangePicker(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAvailableProducts(),
                  _buildAllProducts(),
                  _buildDistributedProducts(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          border: Border.all(color: venaLine),
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: venaTeal.withOpacity(0.12),
                border: Border.all(color: venaTeal.withOpacity(0.25)),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: venaTeal,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INVENTORY',
                    style: TextStyle(
                      color: venaDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Track available stock, branches and warehouse balance',
                    style: TextStyle(
                      color: venaMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 520, child: _buildTabBar()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        border: Border.all(color: venaLine),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: const BoxDecoration(color: venaTeal),
        labelColor: Colors.white,
        unselectedLabelColor: venaMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Available'),
          Tab(text: 'All Products'),
          Tab(text: 'Distributed'),
        ],
      ),
    );
  }

  Widget _dateRangePicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.white.withOpacity(0.94),
                  foregroundColor: venaDark,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: venaLine),
                  ),
                ),
                icon: const Icon(Icons.date_range_rounded, size: 18),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    useRootNavigator: false,
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2090),
                    builder: (context, child) {
                      final baseTheme = ThemeData.light();

                      return Theme(
                        data: baseTheme.copyWith(
                          primaryColor: venaTeal,
                          scaffoldBackgroundColor: venaBg,
                          dialogBackgroundColor: Colors.white,
                          colorScheme: baseTheme.colorScheme.copyWith(
                            primary: venaTeal,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: venaDark,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    setState(() {
                      dateRange = picked;
                    });
                  }
                },
                label: Text(
                  dateRange == null
                      ? 'Today'
                      : '${DateFormat.yMMMd().format(dateRange!.start)} - ${DateFormat.yMMMd().format(dateRange!.end)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: venaDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField({
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 46,
      margin: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(
          color: venaDark,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          icon: const Icon(Icons.search_rounded, color: venaMuted, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(
            color: venaMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildAvailableProducts() {
    final availableProducts = allProducts.where((product) {
      final name = product["name"].toString().toLowerCase();

      final warehouse = product["warehouse"] as Map<String, int>;
      final branchesMap = product["branches"] as Map<String, Map<String, int>>;

      final hasStock =
          warehouse.values.any((qty) => qty > 0) ||
          branchesMap.values.any((variantMap) {
            return variantMap.values.any((qty) => qty > 0);
          });

      final matchesSearch =
          availableSearch.isEmpty || name.contains(availableSearch);

      return hasStock && matchesSearch;
    }).toList();

    return Column(
      children: [
        _searchField(
          hint: 'Search available products...',
          onChanged: (query) {
            setState(() {
              availableSearch = query.toLowerCase();
            });
          },
        ),
        Expanded(
          child: availableProducts.isEmpty
              ? _emptyInventory('No available products')
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: availableProducts.length,
                  itemBuilder: (context, index) {
                    final product = availableProducts[index];
                    final warehouse = product["warehouse"] as Map<String, int>;
                    final branchesMap =
                        product["branches"] as Map<String, Map<String, int>>;

                    final totalWarehouse = warehouse.values.fold<int>(
                      0,
                      (a, b) => a + b,
                    );

                    final totalBranches = branchesMap.values.fold<int>(
                      0,
                      (sum, variants) =>
                          sum + variants.values.fold<int>(0, (a, b) => a + b),
                    );

                    final totalStock = totalWarehouse + totalBranches;

                    return _productSummaryCard(
                      name: product["name"].toString(),
                      totalStock: totalStock,
                      warehouseStock: totalWarehouse,
                      branchStock: totalBranches,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _productSummaryCard({
    required String name,
    required int totalStock,
    required int warehouseStock,
    required int branchStock,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: venaTeal.withOpacity(0.12),
              border: Border.all(color: venaTeal.withOpacity(0.25)),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: venaTeal,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: venaDark,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          _stockMiniBlock('Warehouse', warehouseStock),
          const SizedBox(width: 18),
          _stockMiniBlock('Branches', branchStock),
          const SizedBox(width: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: venaTeal.withOpacity(0.10),
              border: Border.all(color: venaTeal.withOpacity(0.25)),
            ),
            child: Text(
              '$totalStock units',
              style: const TextStyle(
                color: venaTeal,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockMiniBlock(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: venaMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$value',
          style: const TextStyle(
            color: venaDark,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildAllProducts() {
    final filteredProducts = allProducts.where((product) {
      final productName = product["name"].toString().toLowerCase();

      if (productName.contains(productSearch)) return true;

      final variants = List<String>.from(product["variants"]);
      if (variants.any((v) => v.toLowerCase().contains(productSearch))) {
        return true;
      }

      final branchesMap = product["branches"] as Map<String, Map<String, int>>;
      return branchesMap.entries.any((branchEntry) {
        if (branchEntry.key.toLowerCase().contains(productSearch)) return true;

        return branchEntry.value.entries.any((variantEntry) {
          return variantEntry.key.toLowerCase().contains(productSearch) ||
              variantEntry.value.toString().contains(productSearch);
        });
      });
    }).toList();

    return Column(
      children: [
        _searchField(
          hint: 'Search all products...',
          onChanged: (query) {
            setState(() {
              productSearch = query.toLowerCase();
            });
          },
        ),
        Expanded(
          child: filteredProducts.isEmpty
              ? _emptyInventory('No products found')
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _productExpansion(product);
                  },
                ),
        ),
      ],
    );
  }

  Widget _productExpansion(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: ExpansionTile(
        iconColor: venaTeal,
        collapsedIconColor: venaMuted,
        leading: const Icon(Icons.inventory_2_outlined, color: venaTeal),
        title: Text(
          product["name"],
          style: const TextStyle(color: venaDark, fontWeight: FontWeight.w900),
        ),
        children: [
          ...product["branches"].entries.map((branchEntry) {
            return _branchStockSection(
              branchEntry.key,
              branchEntry.value as Map<String, int>,
            );
          }).toList(),
          _warehouseSection(product["warehouse"] as Map<String, int>),
        ],
      ),
    );
  }

  Widget _branchStockSection(String branchName, Map<String, int> variants) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: venaBg.withOpacity(0.75),
          border: Border.all(color: venaLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              branchName,
              style: const TextStyle(
                color: venaDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...variants.entries.map((entry) {
              return _variantRow(entry.key, entry.value, Icons.storefront);
            }),
          ],
        ),
      ),
    );
  }

  Widget _warehouseSection(Map<String, int> warehouse) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: venaTeal.withOpacity(0.08),
          border: Border.all(color: venaTeal.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Warehouse Stock',
              style: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...warehouse.entries.map((entry) {
              return _variantRow(entry.key, entry.value, Icons.warehouse);
            }),
          ],
        ),
      ),
    );
  }

  Widget _variantRow(String variant, int qty, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: venaMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              variant,
              style: const TextStyle(
                color: venaMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$qty units',
            style: TextStyle(
              color: qty > 0 ? venaSuccess : venaDanger,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributedProducts() {
    return Column(
      children: [
        _searchField(
          hint: 'Search distributed products...',
          onChanged: (query) {
            setState(() {
              distributedSearch = query.toLowerCase();
            });
          },
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: branches.length,
            itemBuilder: (context, index) {
              final branch = branches[index];

              final filteredProducts = branch["products"].where((product) {
                final productName = product["name"].toString().toLowerCase();

                final productMatches = productName.contains(distributedSearch);

                final variantsMatch = (product["variants"] as Map<String, int>)
                    .entries
                    .any((variantEntry) {
                      return variantEntry.key.toLowerCase().contains(
                            distributedSearch,
                          ) ||
                          variantEntry.value.toString().contains(
                            distributedSearch,
                          );
                    });

                return productMatches || variantsMatch;
              }).toList();

              return _branchExpansion(
                branch["name"].toString(),
                filteredProducts,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _branchExpansion(String branchName, List<dynamic> products) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: ExpansionTile(
        iconColor: venaTeal,
        collapsedIconColor: venaMuted,
        leading: const Icon(Icons.storefront_outlined, color: venaTeal),
        title: Text(
          branchName,
          style: const TextStyle(color: venaDark, fontWeight: FontWeight.w900),
        ),
        children: [
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No products found',
                style: TextStyle(color: venaMuted, fontWeight: FontWeight.w700),
              ),
            ),
          ...products.map((product) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: venaBg.withOpacity(0.75),
                  border: Border.all(color: venaLine),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product["name"],
                      style: const TextStyle(
                        color: venaDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(product["variants"] as Map<String, int>).entries.map((
                      entry,
                    ) {
                      return _variantRow(
                        entry.key,
                        entry.value,
                        Icons.label_outline,
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _emptyInventory(String text) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          border: Border.all(color: venaLine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: venaTeal.withOpacity(0.8),
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                color: venaDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
