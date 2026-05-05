import 'package:venastudio/common.dart';

void showCompleteSnack(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red : Colors.black87,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

class CompleteOrderPage extends ConsumerStatefulWidget {
  const CompleteOrderPage({super.key, required this.orderId});
  final num orderId;

  @override
  ConsumerState<CompleteOrderPage> createState() => _CompleteOrderPageState();
}

class _CompleteOrderPageState extends ConsumerState<CompleteOrderPage> {
  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  bool loading = false;

  final TextEditingController _cCash = TextEditingController();
  final TextEditingController _cMpesaRef = TextEditingController();
  final TextEditingController _cMpesaRef2 = TextEditingController();
  final TextEditingController _cMpesaRef3 = TextEditingController();
  final TextEditingController _cBankRefNum = TextEditingController();

  late final TextEditingController _cStkNumPush = TextEditingController(
    text: () {
      final text = ref
          .read(orderServicesProvider)
          .orders
          .where((element) => element['id'] == widget.orderId)
          .firstOrNull?['customer'];

      return text?.toString().replaceFirst('+254', '0') ?? '';
    }(),
  );

  var paymentMethods = [
    {'name': 'Cash', 'state': false, 'enabled': true},
    {'name': 'Mpesa', 'state': false, 'enabled': true},
    {'name': 'Bank', 'state': false, 'enabled': true},
    {'name': 'STK Push', 'state': false, 'enabled': true},
  ];

  @override
  void dispose() {
    _cCash.dispose();
    _cMpesaRef.dispose();
    _cMpesaRef2.dispose();
    _cMpesaRef3.dispose();
    _cBankRefNum.dispose();
    _cStkNumPush.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeServicesProvider);
    final allorders = ref.watch(orderServicesProvider);
    final order = allorders.orders
        .where((element) => element['id'] == widget.orderId)
        .firstOrNull;

    if (order == null) {
      return Scaffold(
        backgroundColor: venaBg,
        body: emptyState(ref, text: 'Order not found'),
      );
    }

    final orderAmt = (order['amount'] as num).toDouble();
    final amtPaid = (order['amount_paid'] as num).toDouble();

    return Scaffold(
      backgroundColor: venaBg,
      appBar: AppBar(
        title: Text(
          'Complete Order - ${order['billno']}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: venaDark,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: venaBg,
        foregroundColor: venaDark,
        elevation: 0,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: venaTeal,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            onPressed: loading ? null : _pickMpesaCode,
            child: const Text('Use Code'),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffF8FDFF), Color(0xffEEF9FB), Color(0xffE4F7FA)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _summaryCard(orderAmt, amtPaid),
                        const SizedBox(height: 12),
                        _sectionTitle('PAYMENT METHOD'),
                        const SizedBox(height: 8),
                        paymentWidgets(theme),
                        if (showPayments) ...[
                          const SizedBox(height: 12),
                          _paymentDetails(theme),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _bottomCompleteBar(theme, order),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMpesaCode() async {
    final selected = await PickMpesaCode.show(context);

    if (!mounted) return;

    if (selected != null) {
      final transcode = selected['transcode']?.toString() ?? '';

      if (_cMpesaRef.text.trim().isEmpty) {
        _cMpesaRef.text = transcode;
      } else if (_cMpesaRef2.text.trim().isEmpty) {
        _cMpesaRef2.text = transcode;
      } else if (_cMpesaRef3.text.trim().isEmpty) {
        _cMpesaRef3.text = transcode;
      } else {
        _cMpesaRef.text = transcode;
      }

      final mpesaIndex = paymentMethods.indexWhere(
        (method) => method['name'] == 'Mpesa',
      );

      if (mpesaIndex >= 0 && !(paymentMethods[mpesaIndex]['state'] as bool)) {
        setState(() {
          paymentMethods[mpesaIndex]['state'] = true;
        });
      }

      context.showToast('Code selected: $transcode', textColor: venaDark);
    }
  }

  Widget _summaryCard(double orderAmt, double amtPaid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: Row(
        children: [
          _amountBlock('TOTAL', orderAmt.money, true),
          if (amtPaid > 0) ...[
            const Spacer(),
            _amountBlock('PAID', amtPaid.money, false),
          ],
        ],
      ),
    );
  }

  Widget _amountBlock(String label, String amount, bool highlight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: venaMuted,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: highlight ? venaTeal : venaDark,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: venaDark,
        fontWeight: FontWeight.w900,
        fontSize: 12,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _paymentDetails(theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        border: Border.all(color: venaLine),
      ),
      child: Column(
        children: [
          if (paymentMethods[0]['state'] as bool) ...[
            cashPayment(theme),
            const SizedBox(height: 8),
          ],
          if (paymentMethods[2]['state'] as bool) ...[
            bankPayment(theme),
            const SizedBox(height: 8),
          ],
          if (paymentMethods[1]['state'] as bool) ...[
            ...mpesaRefWidgets(theme),
            const SizedBox(height: 8),
          ],
          if (paymentMethods[3]['state'] as bool) ...[
            TextFormField(
              controller: _cStkNumPush,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: phoneValidation,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: _inputDecoration('Phone number'),
              style: const TextStyle(
                color: venaDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bottomCompleteBar(theme, Map<dynamic, dynamic> order) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Color(0xffF8FDFF),
          border: Border(top: BorderSide(color: venaLine)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (!loading && completeIt)
                    ? () => _handleCompleteOrder(order)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: venaTeal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: venaTeal.withOpacity(0.30),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'COMPLETE ORDER',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCompleteOrder(Map<dynamic, dynamic> order) async {
    if (!completeIt || loading) return;

    setState(() => loading = true);

    try {
      await completeOrder(order);

      if (!mounted) return;

      showCompleteSnack(context, 'Order completed');

      context.go('/orders');

      Future.microtask(() {
        ref.invalidate(orderServicesProvider);
      });
    } catch (_) {
      if (!mounted) return;

      showCompleteSnack(context, 'Unable to complete order', error: true);

      setState(() => loading = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: const TextStyle(
        color: venaMuted,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: venaLine),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: venaTeal, width: 1.4),
      ),
    );
  }

  bool get showPayments {
    final hasPush = paymentMethods[3]['state'] as bool;
    final hasbank = paymentMethods[2]['state'] as bool;
    final hasMpesa = paymentMethods[1]['state'] as bool;
    final hasCash = paymentMethods[0]['state'] as bool;

    return hasPush || hasbank || hasMpesa || hasCash;
  }

  TextField cashPayment(theme) {
    return TextField(
      readOnly: true,
      controller: _cCash,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: venaDark, fontWeight: FontWeight.w800),
      decoration: _inputDecoration('Cash Amount'),
    );
  }

  TextField bankPayment(theme) {
    return TextField(
      autofocus: true,
      readOnly: true,
      controller: _cBankRefNum,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(color: venaDark, fontWeight: FontWeight.w800),
      decoration: _inputDecoration('Bank Reference Number'),
    );
  }

  Future<void> completeOrder(Map<dynamic, dynamic> order) async {
    final cash = paymentMethods[0]['state'] as bool;
    final mpesa = paymentMethods[1]['state'] as bool;
    final bank = paymentMethods[2]['state'] as bool;
    final stkpush = paymentMethods[3]['state'] as bool;

    final notifier = ref.read(orderServicesProvider.notifier);

    if (cash && !mpesa && !bank && !stkpush) {
      return notifier.completeOrder(
        order: order,
        orderType: 'Cash',
        type: 'cash',
        url: 'request.php',
      );
    }

    if (bank || (cash && !mpesa && !stkpush)) {
      return notifier.completeOrder(
        order: order,
        orderType: 'Equity',
        type: 'equity',
        reference: _cBankRefNum.text.trim(),
        url: 'request.php',
        cashAdd: double.tryParse(_cCash.text),
      );
    }

    if (mpesa && !cash && !bank && !stkpush) {
      return notifier.completeOrder(
        order: order,
        orderType: 'code',
        code: _mpesaCodes(),
        url: 'request.php',
      );
    }

    if (cash && mpesa && !bank && !stkpush) {
      return notifier.completeOrder(
        order: order,
        orderType: 'code',
        reference: _cMpesaRef.text.trim(),
        code: _mpesaCodes(),
        url: 'request.php',
        cashAdd: double.tryParse(_cCash.text),
      );
    }

    if (stkpush) {
      return notifier.completeOrder(
        order: order,
        orderType: 'stkpush',
        phonestk: _cStkNumPush.text.trim(),
        url: 'request.php',
      );
    }
  }

  List<String> _mpesaCodes() {
    return [
      if (_cMpesaRef.text.trim().isNotEmpty) _cMpesaRef.text.trim(),
      if (_cMpesaRef2.text.trim().isNotEmpty) _cMpesaRef2.text.trim(),
      if (_cMpesaRef3.text.trim().isNotEmpty) _cMpesaRef3.text.trim(),
    ];
  }

  bool get completeIt {
    final cash = paymentMethods[0]['state'] as bool;
    final mpesa = paymentMethods[1]['state'] as bool;
    final bank = paymentMethods[2]['state'] as bool;
    final stkpush = paymentMethods[3]['state'] as bool;
    final haspayment = cash || mpesa || bank || stkpush;

    bool mpesaok = true;
    bool cashok = true;
    bool bankok = true;
    bool stkok = true;

    if (mpesa) mpesaok = _mpesaCodes().isNotEmpty;
    if (mpesa && cash) cashok = _cCash.text.isNotEmpty;

    if (bank) {
      bankok = _cBankRefNum.text.isNotEmpty && _cBankRefNum.text.length > 4;
    }

    if (stkpush) {
      stkok = _cStkNumPush.text.isNotEmpty && _cStkNumPush.text.length == 10;
    }

    return mpesaok && cashok && bankok && stkok && haspayment;
  }

  List<Widget> mpesaRefWidgets(theme) {
    return [
      TextFormField(
        controller: _cMpesaRef,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(color: venaDark, fontWeight: FontWeight.w800),
        decoration: _inputDecoration('Mpesa Reference'),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _cMpesaRef2,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(color: venaDark, fontWeight: FontWeight.w800),
        decoration: _inputDecoration('Mpesa Reference 2'),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _cMpesaRef3,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(color: venaDark, fontWeight: FontWeight.w800),
        decoration: _inputDecoration('Mpesa Reference 3'),
      ),
    ];
  }

  Widget paymentWidgets(theme) {
    return Column(
      children: paymentMethods.map<Widget>((method) {
        final selected = method['state'] as bool;

        return InkWell(
          onTap: loading
              ? null
              : () {
                  setState(() {
                    method['state'] = !selected;
                  });
                },
          child: Container(
            height: 48,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? venaTeal.withOpacity(0.08) : Colors.white,
              border: Border.all(
                color: selected ? venaTeal : venaLine,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: loading
                      ? null
                      : (val) {
                          setState(() {
                            method['state'] = val ?? false;
                          });
                        },
                  activeColor: venaTeal,
                  checkColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  side: const BorderSide(color: venaLine, width: 1.4),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    method['name'] as String,
                    style: TextStyle(
                      color: selected ? venaDark : venaMuted,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
