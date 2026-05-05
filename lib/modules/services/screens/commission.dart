import 'package:intl/intl.dart';
import 'package:venastudio/common.dart';

class CommissionPage extends ConsumerStatefulWidget {
  const CommissionPage({super.key});

  @override
  ConsumerState<CommissionPage> createState() => _CommissionPageState();
}

class _CommissionPageState extends ConsumerState<CommissionPage> {
  String dateBtn = 'Today';
  String selectedBranch = 'All Shops';

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  @override
  Widget build(BuildContext context) {
    final commissions = ref.watch(commissionServicesProvider);
    final branchesService = ref.watch(branchesServicesProvider);
    final activeAgent = LocalStorage.nosql.activeAgent;

    final user = activeAgent != null
        ? ServiceUser.fromMap(activeAgent)
        : (ref.watch(authenticationServiceProvider).valueOrNull?.user ??
              LocalStorage.nosql.user);

    final isSmallScreen = MediaQuery.of(context).size.width < 700;

    List<String> branchNames = ['All Shops'];
    if (branchesService is AsyncData) {
      branchNames.addAll(
        branchesService.value?.map((branch) => branch['name'].toString()) ?? [],
      );
    }

    return Scaffold(
      backgroundColor: venaBg,
      appBar: isSmallScreen
          ? AppBar(
              backgroundColor: venaBg,
              foregroundColor: venaDark,
              elevation: 0,
              title: const Text(
                'Commissions',
                style: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
              ),
              actions: [
                if (commissions is AsyncData)
                  IconButton(
                    icon: const Icon(Icons.search_rounded, color: venaDark),
                    onPressed: () => _openSearch(commissions),
                  ),
              ],
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
            if (!isSmallScreen)
              _desktopHeader(
                commissions: commissions,
                branchNames: branchNames,
                userType: user?.type,
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 14 : 24,
                isSmallScreen ? 10 : 14,
                isSmallScreen ? 14 : 24,
                0,
              ),
              child: Row(
                children: [
                  if (user?.type != EMPLOYEE_TYPE_NAME && isSmallScreen) ...[
                    Expanded(child: _branchDropdown(branchNames)),
                    const SizedBox(width: 10),
                  ],
                  Expanded(child: _dateSelector()),
                ],
              ),
            ),
            Expanded(
              child: commissions.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: venaTeal),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (data) {
                  if (data.isEmpty) {
                    return emptyState(
                      ref,
                      text: 'No commissions available',
                      onRefresh: () =>
                          ref.invalidate(commissionServicesProvider),
                    );
                  }

                  final sorted = data
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();

                  sorted.sort(
                    (a, b) => (double.tryParse(b['amount'].toString()) ?? 0.0)
                        .compareTo(
                          (double.tryParse(a['amount'].toString()) ?? 0.0),
                        ),
                  );

                  return _commissionGrid(sorted);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktopHeader({
    required AsyncValue commissions,
    required List<String> branchNames,
    required String? userType,
  }) {
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
                Icons.payments_outlined,
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
                    'COMMISSIONS',
                    style: TextStyle(
                      color: venaDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Track sales amounts and staff commission earnings',
                    style: TextStyle(
                      color: venaMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (userType != EMPLOYEE_TYPE_NAME) ...[
              SizedBox(width: 220, child: _branchDropdown(branchNames)),
              const SizedBox(width: 12),
            ],
            if (commissions is AsyncData)
              InkWell(
                onTap: () => _openSearch(commissions),
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    border: Border.all(color: venaLine),
                  ),
                  child: const Icon(Icons.search_rounded, color: venaDark),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openSearch(AsyncValue commissions) {
    final data = (commissions.value ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    showSearch(
      context: context,
      useRootNavigator: false,
      delegate: CommissionSearch(commissions: data, ref: ref),
    );
  }

  Widget _branchDropdown(List<String> items) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: DropdownButton<String>(
        value: selectedBranch,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: venaDark),
        dropdownColor: Colors.white,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: venaDark,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => selectedBranch = value);
            ref.read(commissionServicesProvider.notifier).filter(value);
          }
        },
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
                dateBtn = '$startStr   -   $endStr';
              });

              ref
                  .read(commissionServicesProvider.notifier)
                  .init(range: (value.start, value.end));
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

  Widget _commissionGrid(List<Map<String, dynamic>> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1000
            ? 4
            : constraints.maxWidth > 720
            ? 3
            : constraints.maxWidth > 460
            ? 2
            : 1;

        double aspectRatio = constraints.maxWidth > 1000
            ? 1.55
            : constraints.maxWidth > 720
            ? 1.38
            : constraints.maxWidth > 460
            ? 1.25
            : 1.75;

        return RefreshIndicator(
          color: venaTeal,
          onRefresh: () async {
            ref.invalidate(commissionServicesProvider);
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: data.length,
            itemBuilder: (context, index) {
              return CommissionCard(data: data[index]);
            },
          ),
        );
      },
    );
  }
}

class CommissionCard extends ConsumerWidget {
  final Map<String, dynamic> data;

  const CommissionCard({super.key, required this.data});

  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = (num.tryParse(data['amount'].toString()) ?? 0).toDouble();
    final commission = (num.tryParse(data['commission'].toString()) ?? 0)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: venaTeal.withOpacity(0.12),
                  border: Border.all(color: venaTeal.withOpacity(0.25)),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: venaTeal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  data['name'] ?? 'Unknown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: venaDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          Container(height: 1, color: venaLine),

          const SizedBox(height: 8),

          _infoRow('Sales Amount', amount.money),

          const SizedBox(height: 6),

          _infoRow('Commission', commission.money, highlight: true),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool highlight = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: venaMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? venaTeal : venaDark,
            fontSize: highlight ? 15 : 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class CommissionSearch extends SearchDelegate {
  final List<Map<String, dynamic>> commissions;
  final WidgetRef ref;

  CommissionSearch({required this.commissions, required this.ref});

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: venaBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: venaBg,
        elevation: 0,
        iconTheme: IconThemeData(color: venaDark),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: venaLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: venaTeal, width: 1.4),
        ),
        hintStyle: TextStyle(color: venaMuted),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear_rounded),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildOutput(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildOutput(context);

  Widget _buildOutput(BuildContext context) {
    final searched = commissions.where((e) {
      return e['name'].toString().toLowerCase().contains(query.toLowerCase());
    }).toList();

    return Container(
      color: venaBg,
      child: searched.isEmpty
          ? Center(child: emptyState(ref, text: 'No commission found'))
          : LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 1000
                    ? 4
                    : constraints.maxWidth > 720
                    ? 3
                    : constraints.maxWidth > 460
                    ? 2
                    : 1;

                double aspectRatio = constraints.maxWidth > 1000
                    ? 1.95
                    : constraints.maxWidth > 720
                    ? 1.75
                    : constraints.maxWidth > 460
                    ? 1.72
                    : 2.45;

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: aspectRatio,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: searched.length,
                  itemBuilder: (context, index) {
                    return CommissionCard(data: searched[index]);
                  },
                );
              },
            ),
    );
  }
}
