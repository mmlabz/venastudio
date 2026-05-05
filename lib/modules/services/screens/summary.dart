import 'package:intl/intl.dart';
import 'package:venastudio/common.dart';

class SummaryPage extends ConsumerStatefulWidget {
  const SummaryPage({super.key});

  @override
  ConsumerState<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends ConsumerState<SummaryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  String dateBtn = 'Today';
  (DateTime, DateTime)? rangeSales;

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);

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
    final summaryService = ref.watch(summaryServicesProvider);
    final isSmallScreen = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: venaBg,
      appBar: isSmallScreen
          ? AppBar(
              backgroundColor: venaBg,
              foregroundColor: venaDark,
              elevation: 0,
              leading: context.backIcon(ref, _goBack),
              centerTitle: true,
              title: const Text(
                'Summary',
                style: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(54),
                child: _tabBar(),
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

            Padding(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 14 : 24,
                isSmallScreen ? 10 : 14,
                isSmallScreen ? 14 : 24,
                0,
              ),
              child: _dateSelector(),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  summaryService.storesales.when(
                    data: (data) =>
                        _storeSalesWg(data.cast<Map<String, dynamic>>()),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: venaTeal),
                    ),
                    error: (err, _) => _errorState(err.toString()),
                  ),
                  summaryService.storesummary.when(
                    data: (data) =>
                        _storeSummary(data.cast<Map<String, dynamic>>()),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: venaTeal),
                    ),
                    error: (err, _) => _errorState(err.toString()),
                  ),
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
            InkWell(
              onTap: _goBack,
              child: Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  border: Border.all(color: venaLine),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: venaDark),
              ),
            ),

            const SizedBox(width: 12),

            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: venaTeal.withOpacity(0.12),
                border: Border.all(color: venaTeal.withOpacity(0.25)),
              ),
              child: const Icon(
                Icons.analytics_outlined,
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
                    'SUMMARY',
                    style: TextStyle(
                      color: venaDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'View store sales, order status and booking performance',
                    style: TextStyle(
                      color: venaMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 380, child: _tabBar()),
          ],
        ),
      ),
    );
  }

  Widget _tabBar() {
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
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        tabs: const [
          Tab(text: 'Store Sales'),
          Tab(text: 'Store Summary'),
        ],
      ),
    );
  }

  Widget _dateSelector() {
    return SizedBox(
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
        onPressed: () {
          showDateRangePicker(
            useRootNavigator: SrceenType.type(context.sz).isMobile,
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
                  datePickerTheme: baseTheme.datePickerTheme.copyWith(
                    rangeSelectionBackgroundColor: venaTeal.withOpacity(0.18),
                    rangeSelectionOverlayColor: MaterialStateProperty.all(
                      venaTeal.withOpacity(0.14),
                    ),
                  ),
                ),
                child: child!,
              );
            },
          ).then((value) {
            if (value != null) {
              final startStr = DateFormat.yMMMEd().format(value.start);
              final endStr = DateFormat.yMMMEd().format(value.end);

              setState(() {
                dateBtn = '$startStr - $endStr';
                rangeSales = (value.start, value.end);
              });

              ref
                  .read(summaryServicesProvider.notifier)
                  .getStoreSales(range: rangeSales);

              ref
                  .read(summaryServicesProvider.notifier)
                  .getStoreSummary(range: rangeSales);
            }
          });
        },
        label: Text(
          dateBtn,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: venaDark,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _storeSalesWg(List<Map<String, dynamic>> data) {
    return RefreshIndicator(
      color: venaTeal,
      onRefresh: () async {
        ref.invalidate(summaryServicesProvider);
      },
      child: data.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 100),
                emptyState(
                  ref,
                  text: 'No store sales available',
                  onRefresh: () => ref.invalidate(summaryServicesProvider),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return _summaryCard(item['store'] ?? 'Store', item);
              },
            ),
    );
  }

  Widget _storeSummary(List<Map<String, dynamic>> data) {
    return RefreshIndicator(
      color: venaTeal,
      onRefresh: () async {
        ref.invalidate(summaryServicesProvider);
      },
      child: data.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 100),
                emptyState(
                  ref,
                  text: 'No store summary available',
                  onRefresh: () => ref.invalidate(summaryServicesProvider),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return _storeSummaryCard(item);
              },
            ),
    );
  }

  Widget _summaryCard(String title, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(icon: Icons.storefront_outlined, title: title),
          const SizedBox(height: 14),
          _divider(),
          const SizedBox(height: 12),
          _summaryRow('Cash', item['cash']?.toString() ?? '0'),
          _summaryRow('Mpesa', item['mpesa']?.toString() ?? '0'),
          _summaryRow('Bank', item['bank']?.toString() ?? '0'),
          const SizedBox(height: 12),
          _divider(),
          const SizedBox(height: 12),
          _summaryRow(
            'Total',
            item['total']?.toString() ?? '0',
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _storeSummaryCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            icon: Icons.receipt_long_outlined,
            title: item['name']?.toString() ?? 'Store',
          ),
          const SizedBox(height: 14),
          _divider(),
          const SizedBox(height: 12),
          _summaryRow('Completed', item['completed']?.toString() ?? '0'),
          _summaryRow('In-Service', item['service']?.toString() ?? '0'),
          _summaryRow('Waiting', item['waiting']?.toString() ?? '0'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: venaTeal.withOpacity(0.08),
              border: Border.all(color: venaTeal.withOpacity(0.25)),
            ),
            child: const Text(
              'Bookings',
              style: TextStyle(
                color: venaTeal,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow('Completed', item['completed_booked']?.toString() ?? '0'),
          _summaryRow('In-Service', item['service_booked']?.toString() ?? '0'),
          _summaryRow('Waiting', item['waiting_booked']?.toString() ?? '0'),
        ],
      ),
    );
  }

  Widget _cardTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: venaTeal.withOpacity(0.12),
            border: Border.all(color: venaTeal.withOpacity(0.25)),
          ),
          child: Icon(icon, color: venaTeal, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: venaDark,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(height: 1, color: venaLine);
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: venaMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? venaTeal : venaDark,
              fontSize: highlight ? 16 : 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          border: Border.all(color: venaLine),
        ),
        child: Text(
          'Error: $message',
          style: const TextStyle(
            color: venaDanger,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
