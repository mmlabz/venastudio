import 'package:venastudio/common.dart';

class CartPayFirst extends ConsumerStatefulWidget {
  const CartPayFirst({super.key});

  static Future<bool?> show({required BuildContext context}) {
    final dWidth = context.sz.width;
    final width = dWidth > 400.0 ? 400.0 : dWidth;
    return showDialog<bool>(
      context: context,
      useRootNavigator: SrceenType.type(context.sz).isMobile,
      barrierDismissible: false,
      builder: (_) {
        return Center(
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Material(
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                ),
                const CartPayFirst(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  ConsumerState<CartPayFirst> createState() => _CartPayFirstState();
}

class _CartPayFirstState extends ConsumerState<CartPayFirst> {
  final TextEditingController _cCash = TextEditingController();
  final TextEditingController _cMpesaRef = TextEditingController();
  final TextEditingController _cMpesaRef2 = TextEditingController();
  final TextEditingController _cMpesaRef3 = TextEditingController();
  final TextEditingController _cBankRefNum = TextEditingController();
  late final TextEditingController _cStkNumPush = TextEditingController(
    text: () {
      String? text = ref.read(cartServiceProvider).phone;
      return text?.replaceFirst('+254', '0');
    }(),
  );
  bool loading = false;
  var paymentMethods = [
    {'name': 'Cash', 'state': false, 'enabled': true},
    {'name': 'Mpesa', 'state': false, 'enabled': true},
    {'name': 'Bank', 'state': false, 'enabled': true},
    {'name': 'STK Push', 'state': false, 'enabled': true},
  ];

  @override
  Widget build(BuildContext context) {
    final dWidth = context.sz.width;
    final width = dWidth > 400.0 ? 400.0 : dWidth;
    final theme = ref.watch(themeServicesProvider);
    final ttp = ServiceCartPage.calculateTotalPrice(
      ref.read(cartServiceProvider).items,
    );
    return Center(
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Material(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total'),
                          const SizedBox(width: double.maxFinite),
                          Text(
                            ttp.money,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Payment', style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),
                          SizedBox(width: width, child: paymentWidgets()),
                          const SizedBox(height: 16),
                          if (showPayments)
                            Card(
                              elevation: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (paymentMethods[0]['state'] as bool) ...[
                                      cashPayment(),
                                      const SizedBox(height: 8),
                                    ],
                                    if (paymentMethods[2]['state'] as bool) ...[
                                      bankPayment(),
                                      const SizedBox(height: 8),
                                    ],
                                    if (paymentMethods[1]['state'] as bool) ...[
                                      ...mpesaRefWidgets(),
                                      const SizedBox(height: 8),
                                    ],
                                    if (paymentMethods[3]['state'] as bool) ...[
                                      TextFormField(
                                        controller: _cStkNumPush,
                                        readOnly: true,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        validator: phoneValidation,
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        decoration: const InputDecoration(
                                          labelText: 'Phone number',
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextButton(
                              onPressed: (!loading)
                                  ? () async {
                                      if (completeIt) {
                                        setState(() {
                                          loading = true;
                                        });
                                        final payload = getPayload();
                                        final orderCreated =
                                            await ServiceCartPage.createOrder(
                                              context: context,
                                              ref: ref,
                                              payload: payload,
                                              isPayFirst: true,
                                            );
                                        if (mounted) {
                                          if (orderCreated) {
                                            context.pop(true);
                                          } else {
                                            context.showToast(
                                              'Unable to complete order',
                                              error: true,
                                              textColor:
                                                  theme.textIconPrimaryColor,
                                            );
                                            setState(() {
                                              loading = false;
                                            });
                                          }
                                        }
                                      }
                                    }
                                  : null,
                              style: TextButton.styleFrom(
                                backgroundColor: theme.primaryBackGround,
                                foregroundColor: theme.activeTextIconColor,
                                fixedSize: const Size(double.maxFinite, 20),
                              ),
                              child: loading
                                  ? SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        color: theme.activeTextIconColor,
                                      ),
                                    )
                                  : Text(
                                      'COMPLETE',
                                      style: TextStyle(
                                        color: theme.activeTextIconColor,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PayFirstPayload? getPayload() {
    final cash = paymentMethods[0]['state'] as bool;
    final mpesa = paymentMethods[1]['state'] as bool;
    final bank = paymentMethods[2]['state'] as bool;
    final stkpush = paymentMethods[3]['state'] as bool;

    if (cash && !mpesa && !bank) {
      return const PayFirstPayload(orderType: 'Cash', type: 'cash');
    } else if (bank || cash && !mpesa) {
      return PayFirstPayload(
        orderType: 'Equity',
        type: 'equity',
        reference: _cBankRefNum.text.trim(),
        cashAdd: double.tryParse(_cCash.text),
      );
    } else if (mpesa && !cash && !bank) {
      return PayFirstPayload(
        orderType: 'code',
        code: [
          if (_cMpesaRef.text.trim().isNotEmpty) _cMpesaRef.text,
          if (_cMpesaRef2.text.trim().isNotEmpty) _cMpesaRef2.text,
          if (_cMpesaRef3.text.trim().isNotEmpty) _cMpesaRef3.text,
        ],
      );
    } else if (cash && mpesa && !bank) {
      final cashAmt = double.tryParse(_cCash.text);
      return PayFirstPayload(
        orderType: 'code',
        type: 'code',
        reference: _cMpesaRef.text.trim(),
        code: [
          if (_cMpesaRef.text.trim().isNotEmpty) _cMpesaRef.text,
          if (_cMpesaRef2.text.trim().isNotEmpty) _cMpesaRef2.text,
          if (_cMpesaRef3.text.trim().isNotEmpty) _cMpesaRef3.text,
        ],
        cashAdd: cashAmt,
      );
    } else if (stkpush) {
      return PayFirstPayload(
        orderType: 'stkpush',
        type: 'stkpush',
        phonestk: _cStkNumPush.text.trim(),
      );
    }
    return null;
  }

  Wrap paymentWidgets() {
    return Wrap(
      runSpacing: 8,
      spacing: 8,
      children: paymentMethods
          .map(
            (e) => InkWell(
              onTap: e['enabled'] as bool
                  ? () {
                      final currState = !(e['state'] as bool);
                      switchStuff(e, currState);
                      setState(() {});
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(border: Border.all()),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: e['state'] as bool,
                      onChanged: e['enabled'] as bool
                          ? (value) {
                              if (value != null) {
                                switchStuff(e, value);
                                setState(() {});
                              }
                            }
                          : null,
                    ),
                    Text(e['name'] as String),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  TextField cashPayment() {
    return TextField(
      autofocus: true,
      readOnly: true,
      controller: _cCash,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Cash Amount'),
    );
  }

  TextField bankPayment() {
    return TextField(
      controller: _cBankRefNum,
      textCapitalization: TextCapitalization.characters,
      decoration: const InputDecoration(labelText: 'Bank Reference Number'),
    );
  }

  bool get completeIt {
    final theme = ref.watch(themeServicesProvider);
    final cash = paymentMethods[0]['state'] as bool;
    final mpesa = paymentMethods[1]['state'] as bool;
    final bank = paymentMethods[2]['state'] as bool;
    final stkpush = paymentMethods[3]['state'] as bool;
    final haspayment = cash || mpesa || bank || stkpush;
    bool mpesaok = true;
    bool cashok = true;
    bool bankok = true;
    bool stkok = true;
    if (mpesa) {
      mpesaok = _cMpesaRef.text.isNotEmpty;
    }
    if (mpesa && cash) {
      cashok = _cCash.text.isNotEmpty;
    }
    if (bank) {
      bankok = _cBankRefNum.text.isNotEmpty && _cBankRefNum.text.length > 4;
    }
    if (stkpush) {
      stkok = _cStkNumPush.text.isNotEmpty && _cStkNumPush.text.length == 10;
    }
    final validated = mpesaok && cashok && bankok && stkok;

    if (!bankok) {
      context.showToast(
        'Bank Reference Invalid',
        error: true,
        textColor: theme.textIconPrimaryColor,
      );
    }

    if (!stkok) {
      context.showToast(
        'Phone Number Invalid',
        error: true,
        textColor: theme.textIconPrimaryColor,
      );
    }
    return validated && haspayment;
  }

  void switchStuff(Map<String, Object> e, bool currState) {
    e['state'] = currState;
    if (currState) {
      if (e['name'] == 'Bank') {
        paymentMethods[1]['state'] = false;
        paymentMethods[3]['state'] = false;
      }
      if (e['name'] == 'Mpesa') {
        paymentMethods[2]['state'] = false;
        paymentMethods[3]['state'] = false;
      }
      if (e['name'] == 'Cash') {
        paymentMethods[1]['state'] = false;
        paymentMethods[2]['state'] = false;
        paymentMethods[3]['state'] = false;
      }
      if (e['name'] == 'STK Push') {
        paymentMethods[0]['state'] = false;
        paymentMethods[1]['state'] = false;
        paymentMethods[2]['state'] = false;
      }
    }
  }

  bool mpesa2 = false;
  bool mpesa3 = false;
  List<Widget> mpesaRefWidgets() {
    return [
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _cMpesaRef,
              textCapitalization: TextCapitalization.characters,
              validator: codeValidation,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(labelText: 'Mpesa Reference'),
            ),
          ),
          if (!(mpesa2 || mpesa3))
            IconButton(
              onPressed: () {
                setState(() => mpesa2 = true);
              },
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
      if (mpesa2)
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cMpesaRef2,
                validator: codeValidation,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Second Mpesa Reference',
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                _cMpesaRef2.clear();
                setState(() => mpesa2 = false);
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
            if (!mpesa3)
              IconButton(
                onPressed: () {
                  setState(() => mpesa3 = true);
                },
                icon: const Icon(Icons.add_rounded),
              ),
          ],
        ),
      if (mpesa3)
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cMpesaRef3,
                validator: codeValidation,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Third Mpesa Reference',
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                _cMpesaRef3.clear();
                setState(() => mpesa3 = false);
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
    ];
  }

  get showPayments {
    final hasPush = (paymentMethods[3]['state'] as bool);
    final hasbank = (paymentMethods[2]['state'] as bool);
    final hasMpesa = (paymentMethods[1]['state'] as bool);
    return hasPush || hasbank || hasMpesa;
  }
}

class PayFirstPayload {
  final String? orderType;
  final String? reference;
  final List<String>? code;
  final String? type;
  final String? phonestk;
  final double? cashAdd;

  const PayFirstPayload({
    this.orderType,
    this.reference,
    this.code,
    this.type,
    this.phonestk,
    this.cashAdd,
  });
}
