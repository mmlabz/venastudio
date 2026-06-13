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
                  if (!isEmployeeType(user?.type) && isSmallScreen) ...[
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
            if (!isEmployeeType(userType)) ...[
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


  void _openCommissionServices(Map<String, dynamic> commission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: ref
                  .read(commissionServicesProvider.notifier)
                  .fetchCommissionServices(commission),
              builder: (context, snapshot) {
                final services = snapshot.data ?? [];
                final title = commission['name']?.toString() ?? 'Commission Services';

                return Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: venaDark,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Services, tickets and add-ons that affected this commission',
                                    style: TextStyle(
                                      color: venaMuted,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded, color: venaDark),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 1, color: venaLine),
                      Expanded(
                        child: snapshot.connectionState == ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator(color: venaTeal))
                            : services.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No service breakdown found',
                                      style: TextStyle(color: venaMuted, fontWeight: FontWeight.w800),
                                    ),
                                  )
                                : ListView.separated(
                                    controller: controller,
                                    padding: const EdgeInsets.all(14),
                                    itemBuilder: (context, index) {
                                      return _serviceBreakdownTile(services[index]);
                                    },
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemCount: services.length,
                                  ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }


  Widget _serviceBreakdownTile(Map<String, dynamic> item) {
    final commissionValue = _safeDouble(item['commission']);
    final serviceCommission = _safeDouble(item['serviceCommission']);
    final addonAdditions = _safeDouble(item['addonAdditions']);
    final addonDeductions = _safeDouble(item['addonDeductions']);
    final net = _safeDouble(item['net']);
    final duration = item['actualDuration']?.toString() ?? '';
    final addons = _safeMapList(item['addons']);
    final isAddonOnly = item['rowType']?.toString() == 'addon';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xffF8FDFF),
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
                  color: isAddonOnly
                      ? const Color(0xff13A86B).withOpacity(0.10)
                      : venaTeal.withOpacity(0.10),
                  border: Border.all(color: venaLine),
                ),
                child: Icon(
                  isAddonOnly ? Icons.add_circle_outline_rounded : Icons.spa_outlined,
                  color: isAddonOnly ? const Color(0xff13A86B) : venaTeal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['service']?.toString() ?? 'Service',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: venaDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    if ((item['parentService']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Linked to: ${item['parentService']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: venaMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                commissionValue.money,
                style: TextStyle(
                  color: commissionValue >= 0 ? venaTeal : const Color(0xffEF476F),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _pill('Ticket', item['ticket']?.toString() ?? '-'),
              _pill('Order', item['billno']?.toString() ?? '-'),
              _pill('Net', net.money),
              _pill('Time', duration.isEmpty ? '-' : duration),
              _pill('Base Comm', serviceCommission.money),
              if (addonAdditions > 0) _pill('Add-ons +', addonAdditions.money),
              if (addonDeductions > 0) _pill('Add-ons -', addonDeductions.money),
            ],
          ),
          if (addons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: venaLine),
            const SizedBox(height: 10),
            const Text(
              'Add-ons affecting this commission',
              style: TextStyle(
                color: venaDark,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...addons.map(_addonRow),
          ],
        ],
      ),
    );
  }

  Widget _addonRow(Map<String, dynamic> addon) {
    final effect = addon['effect']?.toString() ?? 'addition';
    final amount = _safeDouble(addon['amount']);
    final isAddition = effect == 'addition';

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isAddition
            ? const Color(0xff13A86B).withOpacity(0.07)
            : const Color(0xffEF476F).withOpacity(0.07),
        border: Border.all(
          color: isAddition
              ? const Color(0xff13A86B).withOpacity(0.22)
              : const Color(0xffEF476F).withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAddition ? Icons.add_rounded : Icons.remove_rounded,
            size: 16,
            color: isAddition ? const Color(0xff13A86B) : const Color(0xffEF476F),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${addon['name'] ?? 'Add-on'} • ${addon['label'] ?? ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: venaDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '${isAddition ? '+' : '-'}${amount.money}',
            style: TextStyle(
              color: isAddition ? const Color(0xff13A86B) : const Color(0xffEF476F),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  double _safeDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  }

  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _safeMapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: venaLine),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: venaDark,
          fontSize: 11,
          fontWeight: FontWeight.w800,
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
            ? 1.15
            : constraints.maxWidth > 720
            ? 1.05
            : constraints.maxWidth > 460
            ? 1.05
            : 1.35;

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
              return CommissionCard(
                data: data[index],
                onTap: () => _openCommissionServices(data[index]),
              );
            },
          ),
        );
      },
    );
  }
}

class CommissionCard extends ConsumerWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const CommissionCard({super.key, required this.data, this.onTap});

  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = (num.tryParse(data['amount'].toString()) ?? 0).toDouble();
    final commission = (num.tryParse(data['commission'].toString()) ?? 0)
        .toDouble();
    final servicesCount = _safeInt(data['servicesCount']);
    final addonAdds = (num.tryParse(data['addonAmount'].toString()) ?? 0).toDouble();
    final addonDeductions = (num.tryParse(data['deductAmount'].toString()) ?? 0).toDouble();

    return InkWell(
      onTap: onTap,
      child: Container(
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

          const SizedBox(height: 6),

          _infoRow('Services Done', '$servicesCount'),

          if (addonAdds > 0 || addonDeductions > 0) ...[
            const SizedBox(height: 6),
            _infoRow('Add-ons', '+${addonAdds.money} / -${addonDeductions.money}'),
          ],

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 34,
            child: OutlinedButton.icon(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: venaDark,
                side: const BorderSide(color: venaLine),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text(
                'View Services',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }


  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
