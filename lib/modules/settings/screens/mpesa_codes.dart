import 'package:intl/intl.dart';
import 'package:venastudio/common.dart';

class MpesaCodesPage extends ConsumerStatefulWidget {
  const MpesaCodesPage({super.key});

  @override
  ConsumerState<MpesaCodesPage> createState() => _MpesaCodesPageState();
}

class _MpesaCodesPageState extends ConsumerState<MpesaCodesPage> {
  String dateBtn = 'Today';
  (DateTime, DateTime)? range;
  bool? isUsed;

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);
  static const Color venaSuccess = Color(0xff13A76B);

  @override
  Widget build(BuildContext context) {
    final mpesaCodesService = ref.watch(mpesaCodesServicesProvider);

    return Scaffold(
      backgroundColor: venaBg,
      appBar: AppBar(
        backgroundColor: venaBg,
        foregroundColor: venaDark,
        elevation: 0,
        centerTitle: true,
        leading: context.backIcon(ref, () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/settings');
          }
        }),
        title: const Text(
          'M-Pesa Codes',
          style: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: venaDark),
            onPressed: () {
              if (mpesaCodesService is AsyncData) {
                showSearch(
                  context: context,
                  delegate: MpesaCodesSearch(
                    codes: (mpesaCodesService.value ?? [])
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList(),
                  ),
                );
              }
            },
          ),
        ],
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _dateButton(),
            ),
            Expanded(
              child: mpesaCodesService.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: venaTeal),
                ),
                error: (_, __) => const Center(
                  child: Text(
                    'Failed to load M-Pesa codes',
                    style: TextStyle(
                      color: venaDanger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                data: (data) {
                  if (data.isEmpty) {
                    return emptyState(ref, text: 'No M-Pesa Codes Found');
                  }

                  return RefreshIndicator(
                    color: venaTeal,
                    onRefresh: () async {
                      ref.invalidate(mpesaCodesServicesProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        return _buildMpesaCard(
                          Map<String, dynamic>.from(data[index]),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: venaTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.filter_list_rounded),
        label: Text(
          isUsed == null
              ? 'All Codes'
              : (isUsed! ? 'Used Codes' : 'Unused Codes'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        onPressed: () {
          SelectItem.show(context, [
            'ALL CODES',
            'USED CODES',
            'UNUSED CODES',
          ]).then((value) {
            if (value != null) {
              ref.read(mpesaCodesServicesProvider.notifier).filter(value);
              setState(() {
                isUsed = value == 'USED CODES'
                    ? true
                    : value == 'UNUSED CODES'
                    ? false
                    : null;
              });
            }
          });
        },
      ),
    );
  }

  Widget _dateButton() {
    return SizedBox(
      height: 44,
      width: double.infinity,
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
        onPressed: _selectDateRange,
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

  void _selectDateRange() async {
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
    );

    if (picked != null) {
      final startStr = DateFormat.yMMMEd().format(picked.start);
      final endStr = DateFormat.yMMMEd().format(picked.end);

      setState(() {
        dateBtn = '$startStr   -   $endStr';
        range = (picked.start, picked.end);
      });

      ref
          .read(mpesaCodesServicesProvider.notifier)
          .init(range: (picked.start, picked.end));
    }
  }

  Widget _buildMpesaCard(Map<String, dynamic> tn) {
    final used = tn['used'] == true;
    final amount = (num.tryParse(tn['amount'].toString()) ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        border: Border.all(
          color: used ? venaDanger.withOpacity(0.25) : venaLine,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: used
                      ? venaDanger.withOpacity(0.08)
                      : venaTeal.withOpacity(0.10),
                  border: Border.all(
                    color: used
                        ? venaDanger.withOpacity(0.25)
                        : venaTeal.withOpacity(0.25),
                  ),
                ),
                child: Icon(
                  used ? Icons.lock_outline_rounded : Icons.payments_outlined,
                  color: used ? venaDanger : venaTeal,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tn['transcode']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: used ? venaDanger : venaDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    decoration: used ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              _statusPill(used),
              if (!used) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: venaTeal,
                    size: 20,
                  ),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: tn['transcode'].toString()),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transaction Code Copied!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.calendar_today_outlined,
            DateFormat('MMM d, y • hh:mm a').format(
              DateTime.tryParse(tn['date'].toString()) ?? DateTime.now(),
            ),
          ),
          _infoRow(
            Icons.person_outline_rounded,
            tn['username']?.toString() ?? '',
          ),
          _infoRow(Icons.phone_outlined, tn['phone']?.toString() ?? ''),
          const SizedBox(height: 10),
          Container(height: 1, color: venaLine),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Amount',
                style: TextStyle(
                  color: venaMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                amount.money,
                style: const TextStyle(
                  color: venaTeal,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          if (used && tn['bill_no'] != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: venaDanger.withOpacity(0.08),
                border: Border.all(color: venaDanger.withOpacity(0.20)),
              ),
              child: Text(
                'Bill No. ${tn['bill_no']}',
                style: const TextStyle(
                  color: venaDanger,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusPill(bool used) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: used
            ? venaDanger.withOpacity(0.10)
            : venaSuccess.withOpacity(0.10),
        border: Border.all(
          color: used
              ? venaDanger.withOpacity(0.28)
              : venaSuccess.withOpacity(0.28),
        ),
      ),
      child: Text(
        used ? 'USED' : 'UNUSED',
        style: TextStyle(
          color: used ? venaDanger : venaSuccess,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: venaMuted),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: venaMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MpesaCodesSearch extends SearchDelegate {
  final List<Map<String, dynamic>> codes;

  MpesaCodesSearch({required this.codes});

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);
  static const Color venaSuccess = Color(0xff13A76B);

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
        hintStyle: TextStyle(color: venaMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: venaLine),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear_rounded),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    final searched = codes.where((tn) {
      return tn['username'].toString().toLowerCase().contains(
            query.toLowerCase(),
          ) ||
          tn['phone'].toString().contains(query) ||
          tn['transcode'].toString().toLowerCase().contains(
            query.toLowerCase(),
          );
    }).toList();

    return Container(
      color: venaBg,
      child: searched.isEmpty
          ? const Center(
              child: Text(
                'No results found',
                style: TextStyle(color: venaMuted, fontWeight: FontWeight.w800),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: searched.length,
              itemBuilder: (context, index) {
                return _buildMpesaCard(context, searched[index]);
              },
            ),
    );
  }

  Widget _buildMpesaCard(BuildContext context, Map<String, dynamic> tn) {
    final used = tn['used'] == true;
    final amount = (num.tryParse(tn['amount'].toString()) ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        border: Border.all(
          color: used ? venaDanger.withOpacity(0.25) : venaLine,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: used
                  ? venaDanger.withOpacity(0.08)
                  : venaTeal.withOpacity(0.10),
              border: Border.all(
                color: used
                    ? venaDanger.withOpacity(0.25)
                    : venaTeal.withOpacity(0.25),
              ),
            ),
            child: Icon(
              used ? Icons.lock_outline_rounded : Icons.payments_outlined,
              color: used ? venaDanger : venaTeal,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tn['transcode']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: used ? venaDanger : venaDark,
                    fontWeight: FontWeight.w900,
                    decoration: used ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tn['username'] ?? ''} • ${amount.money}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: venaMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            used ? 'USED' : 'UNUSED',
            style: TextStyle(
              color: used ? venaDanger : venaSuccess,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
