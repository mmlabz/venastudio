import 'package:intl/intl.dart';
import 'package:venastudio/common.dart';

class EditSavisPage extends ConsumerStatefulWidget {
  const EditSavisPage({super.key, this.savis});
  final Savis? savis;

  static Future<String?> show(BuildContext context, [Savis? savis]) {
    return showDialog<String>(
      useRootNavigator: SrceenType.type(context.sz).isMobile,
      context: context,
      builder: (_) {
        return EditSavisPage(savis: savis);
      },
    );
  }

  @override
  ConsumerState<EditSavisPage> createState() => _EditSavisPageState();
}

class _EditSavisPageState extends ConsumerState<EditSavisPage> {
  bool isupdating = false;
  final GlobalKey<FormState> _form = GlobalKey();
  late final TextEditingController _cName = TextEditingController(
    text: widget.savis?.name.value,
  );
  late final TextEditingController _cAmount = TextEditingController(
    text: widget.savis?.amount.toString().value,
  );
  late final TextEditingController _cCommission = TextEditingController(
    text: widget.savis?.commission.toString().value,
  );
  late final TextEditingController _cDiscount = TextEditingController(
    text: widget.savis?.discount.toString().value,
  );
  late final TextEditingController _cQuantity = TextEditingController(
    text: widget.savis?.quantity.toString().value,
  );

  late final TextEditingController _cType = TextEditingController(
    text: toBeginningOfSentenceCase(widget.savis?.type.toString().value),
  );

  late final TextEditingController _cDiscountDuration = TextEditingController(
    text: () {
      final start = DateTime.tryParse(widget.savis?.discountStartDate ?? '');
      final end = DateTime.tryParse(widget.savis?.discountEndDate ?? '');
      if (startDate != null && endDate != null) {
        return '${DateFormat.yMMMd().format(start!)} - ${DateFormat.yMMMd().format(end!)}';
      }
    }(),
  );

  late DateTime? startDate = DateTime.tryParse(
    widget.savis?.discountStartDate ?? '',
  );
  late DateTime? endDate = DateTime.tryParse(
    widget.savis?.discountEndDate ?? '',
  );

  @override
  Widget build(BuildContext context) {
    final dWidth = context.sz.width;
    final width = dWidth > 400.0 ? 400.0 : dWidth;
    final theme = ref.watch(themeServicesProvider);

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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Form(
                      key: _form,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _cName,
                            validator: (value) =>
                                (value?.isEmpty ?? true) ? '' : null,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                          ),
                          TextFormField(
                            controller: _cAmount,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) =>
                                (value?.isEmpty ?? true) ? '' : null,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                            ),
                          ),
                          TextFormField(
                            controller: _cCommission,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Commission',
                            ),
                          ),
                          TextFormField(
                            controller: _cDiscount,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Discount',
                            ),
                          ),
                          TextFormField(
                            controller: _cDiscountDuration,
                            readOnly: true,
                            onTap: () {
                              showDateRangePicker(
                                useRootNavigator: false,
                                context: context,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 400),
                                ),
                              ).then((value) {
                                if (value != null) {
                                  startDate = value.start;
                                  endDate = value.end;
                                  _cDiscountDuration.text =
                                      '${DateFormat.yMMMd().format(value.start)} - ${DateFormat.yMMMd().format(value.end)}';
                                }
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Discount duration',
                            ),
                          ),
                          TextFormField(
                            controller: _cQuantity,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Service type'),
                          ),
                          DropdownButtonFormField(
                            value: _cType.text.isEmpty ? null : _cType.text,
                            hint: const Text('Tap to select'),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Service type required';
                              }
                              return null;
                            },
                            items: ['Main', 'Addon']
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                _cType.text = newValue;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: .5,
                    thickness: .5,
                    color: theme.inactiveBackGround,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Consumer(
                      builder: (context, ref, _) {
                        return TextButton(
                          onPressed: isupdating
                              ? null
                              : () {
                                  if (_form.currentState!.validate()) {
                                    setState(() {
                                      isupdating = true;
                                    });
                                    _update(ref);
                                  }
                                },
                          style: TextButton.styleFrom(
                            backgroundColor: theme.primaryBackGround,
                            foregroundColor: theme.activeTextIconColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            fixedSize: const Size(double.maxFinite, 20),
                          ),
                          child: isupdating
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: theme.activeTextIconColor,
                                  ),
                                )
                              : Text(widget.savis == null ? 'ADD' : 'UPDATE'),
                        );
                      },
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

  _update(WidgetRef ref) async {
    final theme = ref.watch(themeServicesProvider);
    try {
      final oldsavis = widget.savis;
      final newSavis = Savis(
        id: oldsavis?.id ?? 0,
        name: _cName.text,
        amount: num.tryParse(_cAmount.text) ?? oldsavis?.amount ?? 0,
        discount: num.tryParse(_cDiscount.text) ?? oldsavis?.discount ?? 0,
        commission:
            num.tryParse(_cCommission.text) ?? oldsavis?.commission ?? 0,
        hours: 0,
        minutes: 0,
        type: _cType.text,
        quantity: num.tryParse(_cQuantity.text) ?? oldsavis?.quantity ?? 0,
        discountStartDate: startDate?.toString() ?? '',
        discountEndDate: endDate?.toString() ?? '',
      );
      if (widget.savis == null) {
        await ref.read(businessServicesProvider.notifier).add(newSavis);
      } else {
        await ref.read(businessServicesProvider.notifier).update(newSavis);
      }

      // ignore: use_build_context_synchronously
      Navigator.of(context).pop('200');
    } catch (e) {
      context.showToast(
        'Unable to update',
        error: true,
        textColor: theme.textIconPrimaryColor,
      );
      setState(() {
        isupdating = false;
      });
    }
  }
}
