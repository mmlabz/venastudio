import 'package:intl/intl.dart';
import 'package:venastudio/common.dart';

class PickMpesaCode extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onPick;
  final ScrollController? scrollController;

  const PickMpesaCode({super.key, required this.onPick, this.scrollController});

  static Future<Map<String, dynamic>?> show(BuildContext context) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.95,
          maxChildSize: 0.98,
          minChildSize: 0.7,
          expand: false,
          builder: (_, controller) {
            return Container(
              color: Colors.white,
              child: PickMpesaCode(
                onPick: (code) => Navigator.pop(context, code),
                scrollController: controller,
              ),
            );
          },
        );
      },
    );
  }

  @override
  ConsumerState<PickMpesaCode> createState() => _PickMpesaCodeState();
}

class _PickMpesaCodeState extends ConsumerState<PickMpesaCode> {
  String dateBtn = 'Today';
  (DateTime, DateTime)? range;
  String search = '';

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);
  static const Color venaSuccess = Color(0xff13A76B);

  @override
  Widget build(BuildContext context) {
    final codesState = ref.watch(mpesaCodesServicesProvider);

    List<Map<String, dynamic>> data = (codesState.value ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    /// 🔥 SEARCH FIX
    if (search.isNotEmpty) {
      data = data.where((code) {
        return code['transcode'].toString().toLowerCase().contains(
              search.toLowerCase(),
            ) ||
            code['username'].toString().toLowerCase().contains(
              search.toLowerCase(),
            ) ||
            code['phone'].toString().toLowerCase().contains(
              search.toLowerCase(),
            );
      }).toList();
    }

    return Scaffold(
      backgroundColor: venaBg,
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(child: _dateButton()),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: venaDark),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            /// SEARCH
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: TextField(
                onChanged: (val) => setState(() => search = val),
                style: const TextStyle(color: venaDark),
                decoration: InputDecoration(
                  hintText: 'Search code, phone, customer...',
                  hintStyle: const TextStyle(color: venaMuted),
                  prefixIcon: const Icon(Icons.search, color: venaMuted),
                  filled: true,
                  fillColor: Colors.white,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: venaLine),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: venaLine),
                  ),
                ),
              ),
            ),

            /// LIST
            Expanded(
              child: codesState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: venaTeal),
                ),
                error: (_, __) =>
                    const Center(child: Text('Failed to load data')),
                data: (_) => data.isEmpty
                    ? const Center(child: Text('No Mpesa Codes Found'))
                    : ListView.builder(
                        controller: widget.scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                        itemCount: data.length,
                        itemBuilder: (_, i) => _card(data[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 CLEAN CARD
  Widget _card(Map<String, dynamic> code) {
    final used = code['used'] == true;
    final amount = (num.tryParse(code['amount'].toString()) ?? 0).toDouble();

    return GestureDetector(
      onTap: () => widget.onPick(code),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: used ? venaDanger.withOpacity(0.3) : venaLine,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// DATE
            Text(
              DateFormat(
                'MMM d, y • hh:mm a',
              ).format(DateTime.parse(code['date'])),
              style: const TextStyle(
                color: venaMuted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 6),

            /// NAME + AMOUNT
            Row(
              children: [
                Expanded(
                  child: Text(
                    code['username'] ?? '',
                    style: const TextStyle(
                      color: venaDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  amount.money,
                  style: const TextStyle(
                    color: venaTeal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              code['phone'] ?? '',
              style: const TextStyle(color: venaMuted, fontSize: 12),
            ),

            const SizedBox(height: 8),

            /// CODE ROW
            Row(
              children: [
                Expanded(
                  child: Text(
                    code['transcode'],
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: used ? venaDanger : venaSuccess,
                      decoration: used ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (!used)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code['transcode']));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateButton() {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.white,
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
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        dateBtn =
            '${DateFormat('yMMMd').format(picked.start)} - ${DateFormat('yMMMd').format(picked.end)}';
        range = (picked.start, picked.end);
      });

      ref.read(mpesaCodesServicesProvider.notifier).init(range: range);
    }
  }
}
