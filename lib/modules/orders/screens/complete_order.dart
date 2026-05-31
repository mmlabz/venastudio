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
  void initState() {
    super.initState();

    _cCash.addListener(_refreshCompleteButton);
    _cMpesaRef.addListener(_refreshCompleteButton);
    _cMpesaRef2.addListener(_refreshCompleteButton);
    _cMpesaRef3.addListener(_refreshCompleteButton);
    _cBankRefNum.addListener(_refreshCompleteButton);
    _cStkNumPush.addListener(_refreshCompleteButton);
  }

  void _refreshCompleteButton() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _cCash.removeListener(_refreshCompleteButton);
    _cMpesaRef.removeListener(_refreshCompleteButton);
    _cMpesaRef2.removeListener(_refreshCompleteButton);
    _cMpesaRef3.removeListener(_refreshCompleteButton);
    _cBankRefNum.removeListener(_refreshCompleteButton);
    _cStkNumPush.removeListener(_refreshCompleteButton);

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

  Future<bool> _ensureReturnablesReady(Map<dynamic, dynamic> order) async {
    final api = ApiProvider();
    final user = LocalStorage.nosql.activeAgent != null
        ? ServiceUser.fromMap(LocalStorage.nosql.activeAgent!)
        : ref.read(authenticationServiceProvider).valueOrNull?.user ??
            LocalStorage.nosql.user;

    final billNo = '${order['billno'] ?? order['bill_no'] ?? ''}';
    final companyId =
        '${user?.shop ?? order['company_id'] ?? order['shop'] ?? ''}';

    final response = await api.post(
      '/workforce/check_order_returnables_before_complete.php',
      body: {
        'company_id': companyId,
        'order_no': billNo,
      },
    );

    final data = response['data'] is Map ? response['data'] as Map : response;
    final outstanding =
        data['outstanding'] is List ? data['outstanding'] as List : const [];

    if (outstanding.isEmpty) return true;

    if (!mounted) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReturnablesReceiptDialog(
        items: outstanding,
        companyId: companyId,
        orderNo: billNo,
        receivedById: '${user?.id ?? 0}',
        receivedByName: '${user?.name ?? ''}',
      ),
    );

    return confirmed == true;
  }

  Future<void> _handleCompleteOrder(Map<dynamic, dynamic> order) async {
    if (!completeIt || loading) return;

    setState(() => loading = true);

    try {
      final canComplete = await _ensureReturnablesReady(order);

      if (!canComplete) {
        if (mounted) setState(() => loading = false);
        return;
      }

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
    if (mpesa && cash) cashok = _cCash.text.trim().isNotEmpty;

    if (bank) {
      bankok = _cBankRefNum.text.trim().length >= 4;
    }

    if (stkpush) {
      stkok = _cStkNumPush.text.trim().length == 10;
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

class _ReturnablesReceiptDialog extends StatefulWidget {
  const _ReturnablesReceiptDialog({
    required this.items,
    required this.companyId,
    required this.orderNo,
    required this.receivedById,
    required this.receivedByName,
  });

  final List items;
  final String companyId;
  final String orderNo;
  final String receivedById;
  final String receivedByName;

  @override
  State<_ReturnablesReceiptDialog> createState() =>
      _ReturnablesReceiptDialogState();
}

class _ReturnablesReceiptDialogState extends State<_ReturnablesReceiptDialog> {
  bool loading = false;
  String error = '';

  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);

  Future<void> _confirm() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final api = ApiProvider();
      await api.post('/workforce/confirm_order_returnables.php', body: {
        'company_id': widget.companyId,
        'order_no': widget.orderNo,
        'received_by_id': widget.receivedById,
        'received_by_name': widget.receivedByName,
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = '$e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(18),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.assignment_return_rounded,
                    color: Color(0xff8B5CF6),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Returnable Items Required',
                      style: TextStyle(
                        color: venaDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'This order cannot be completed until front office confirms receipt of the returnable items below.',
                style: TextStyle(
                  color: venaMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.items.length,
                  separatorBuilder: (_, __) => const Divider(color: venaLine),
                  itemBuilder: (_, index) {
                    final item = widget.items[index] as Map;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xffF4F0FF),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          color: Color(0xff8B5CF6),
                        ),
                      ),
                      title: Text(
                        '${item['product_name'] ?? item['name'] ?? 'Returnable item'}',
                        style: const TextStyle(
                          color: venaDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Text(
                        'Beautician: ${item['employee_name'] ?? ''}',
                        style: const TextStyle(color: venaMuted),
                      ),
                      trailing: Text(
                        'x${item['quantity'] ?? item['qty'] ?? item['outstanding_qty'] ?? 1}',
                        style: const TextStyle(
                          color: venaDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  error,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loading
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : _confirm,
                      icon: loading
                          ? const SizedBox(
                              height: 15,
                              width: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: const Text('Confirm Receipt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: venaTeal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
