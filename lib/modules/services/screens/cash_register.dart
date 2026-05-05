import 'package:intl/intl.dart';
import 'package:venastudio/common.dart';
ServiceUser? getCurrentCRUser(WidgetRef ref) {
  final activeAgent = LocalStorage.nosql.activeAgent;

  if (activeAgent != null) {
    return ServiceUser.fromMap(activeAgent);
  }

  return ref.watch(authenticationServiceProvider).valueOrNull?.user ??
      LocalStorage.nosql.user;
}
class CashRegisterPage extends ConsumerStatefulWidget {
  const CashRegisterPage({super.key});

  @override
  ConsumerState<CashRegisterPage> createState() => _CashRegisterPageState();
}

class _CashRegisterPageState extends ConsumerState<CashRegisterPage> {
  String dateBtn = 'Today';
  String selectedBranch = 'All';
  String selectedType = 'all';
  String selectedCategory = 'All';

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);
  static const Color venaSuccess = Color(0xff13A76B);

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseServicesProvider);
    final user = getCurrentCRUser(ref);
    final branchesService = ref.watch(branchesServicesProvider);
    final expenseCategories = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      backgroundColor: venaBg,
      appBar: AppBar(
        backgroundColor: venaBg,
        foregroundColor: venaDark,
        elevation: 0,
        leading: context.backIcon(ref, () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/settings');
          }
        }),
        title: const Text(
          'Cash Register',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add, color: venaTeal),
            label: const Text(
              'Add',
              style: TextStyle(color: venaTeal, fontWeight: FontWeight.w900),
            ),
            onPressed: () {
              AddExpense.show(context).then((value) {
                if (value == '200') {
                  ref.invalidate(expenseServicesProvider);
                }
              });
            },
          ),
        ],
      ),

      body: Column(
        children: [
          /// DATE
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _dateSelector(),
          ),

          /// FILTERS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              children: [
                if (user?.type == SUPERADMIN_TYPE_NAME)
                  branchesService.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox(),
                    data: (branches) {
                      return _dropdown(
                        label: 'Shop',
                        value: selectedBranch,
                        items: ['All', ...branches.map((b) => b['name'])],
                        onChanged: (v) => setState(() => selectedBranch = v!),
                      );
                    },
                  ),

                const SizedBox(height: 10),

                expenseCategories.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                  data: (cats) {
                    return _dropdown(
                      label: 'Category',
                      value: selectedCategory,
                      items: ['All', ...cats.map((c) => c['expense'])],
                      onChanged: (v) => setState(() => selectedCategory = v!),
                    );
                  },
                ),

                const SizedBox(height: 10),

                /// TYPE FILTER
                Row(
                  children: [
                    _chip('All', 'all'),
                    _chip('Debit', 'debit'),
                    _chip('Credit', 'credit'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// LIST
          Expanded(
            child: RefreshIndicator(
              color: venaTeal,
              onRefresh: () async {
                ref.invalidate(expenseServicesProvider);
              },
              child: expenses.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: venaTeal),
                ),
                error: (_, __) =>
                    const Center(child: Text('Error loading expenses')),
                data: (expenseData) {
                  final filtered = expenseData['data']
                      .where(
                        (e) =>
                            (selectedBranch == 'All' ||
                                e['shop'] == selectedBranch) &&
                            (selectedType == 'all' ||
                                e['type'] == selectedType) &&
                            (selectedCategory == 'All' ||
                                e['category'] == selectedCategory),
                      )
                      .toList();

                  if (filtered.isEmpty) {
                    return emptyState(ref, text: 'No transactions');
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _expenseCard(filtered[i], user),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// DATE BUTTON
  Widget _dateSelector() {
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
        icon: const Icon(Icons.date_range),
        label: Text(dateBtn),
        onPressed: () {
          showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2090),
          ).then((value) {
            if (value != null) {
              setState(() {
                dateBtn =
                    '${DateFormat.yMMMd().format(value.start)} - ${DateFormat.yMMMd().format(value.end)}';
              });

              ref
                  .read(expenseServicesProvider.notifier)
                  .init(range: (value.start, value.end));
            }
          });
        },
      ),
    );
  }

  /// DROPDOWN
  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: venaLine),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  /// TYPE CHIP
  Widget _chip(String label, String value) {
    final selected = selectedType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedType = value),
        child: Container(
          height: 36,
          margin: const EdgeInsets.only(right: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? venaTeal : Colors.white,
            border: Border.all(color: venaLine),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : venaDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  /// CARD
  Widget _expenseCard(Map expense, dynamic user) {
    final isDebit = expense['type'] == 'debit';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: venaLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            expense['category'],
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: venaDark,
            ),
          ),

          const SizedBox(height: 8),

          Text(expense['date_added'], style: const TextStyle(color: venaMuted)),

          if (user?.type == SUPERADMIN_TYPE_NAME)
            Text('Shop: ${expense['shop']}'),

          Text('Source: ${expense['source']}'),

          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                expense['amount'],
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isDebit ? venaDanger : venaSuccess,
                ),
              ),
              const Spacer(),
              Text('Bal: ${expense['shop_balance']}'),
            ],
          ),
        ],
      ),
    );
  }
}

class AddExpense extends ConsumerStatefulWidget {
  const AddExpense({super.key, this.expense});
  final Map<dynamic, dynamic>? expense;

  static Future<String?> show(
    BuildContext context, {
    Map<dynamic, dynamic>? expense,
  }) {
    return showDialog<String>(
      context: context,
      useRootNavigator: SrceenType.type(context.sz).isMobile,
      builder: (_) {
        return AddExpense(expense: expense);
      },
    );
  }

  @override
  ConsumerState<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends ConsumerState<AddExpense> {
  bool isUpdating = false;
  final GlobalKey<FormState> _form = GlobalKey();

  late final TextEditingController _cReason = TextEditingController(
    text: widget.expense == null ? '' : widget.expense!['reason'],
  );
  late final TextEditingController _cAmount = TextEditingController(
    text: widget.expense == null ? '' : widget.expense!['amount'],
  );
  late final TextEditingController _cShopName = TextEditingController();

  final List<Map<String, String>> eTypes = [
    {'value': 'debit', 'name': 'Reduce Cash'},
    {'value': 'credit', 'name': 'Add Cash'},
  ];

  late String? selectedType = widget.expense == null
      ? eTypes.first['value']
      : widget.expense!['type'] as String?;
  late String? selectedCategory = widget.expense == null
      ? null
      : widget.expense!['category'] as String?;
  String? shopId;

  @override
  Widget build(BuildContext context) {
    final dWidth = context.sz.width;
    final width = dWidth > 400.0 ? 400.0 : dWidth;
    final theme = ref.watch(themeServicesProvider);
    final expenseCategories = ref.watch(expenseCategoriesProvider);
    final branchesService = ref.watch(branchesServicesProvider);
    final user = getCurrentCRUser(ref);
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
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (user?.type == SUPERADMIN_TYPE_NAME) ...[
                            branchesService.when(
                              loading: () => const Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select shop',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  LinearProgressIndicator(),
                                ],
                              ),
                              error: (error, stackTrace) => Text(
                                'Unable to load shops',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.deleteColor,
                                ),
                              ),
                              data: (data) {
                                return TextFormField(
                                  controller: _cShopName,
                                  readOnly: true,
                                  validator: (value) =>
                                      (value?.isEmpty ?? true) ? '' : null,
                                  onTap: () {
                                    SelectShop.show(context, data).then((
                                      value,
                                    ) {
                                      if (value != null) {
                                        shopId = value['id'].toString();
                                        _cShopName.text = value['name'];
                                      }
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Select shop',
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          const Text(
                            'Expense type',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          DropdownButtonFormField(
                            value: selectedType,
                            validator: (value) =>
                                (value?.isEmpty ?? true) ? '' : null,
                            items: eTypes
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e['value'],
                                    child: Text(e['name'] as String),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedType = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Category',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          expenseCategories.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (error, stackTrace) =>
                                const SizedBox.shrink(),
                            data: (data) {
                              return DropdownButtonFormField<String>(
                                value: selectedCategory,
                                validator: (value) =>
                                    (value?.isEmpty ?? true) ? '' : null,
                                items: data
                                    .map(
                                      (e) => DropdownMenuItem<String>(
                                        value: e['expense'],
                                        child: Text(e['expense'] as String),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedCategory = value;
                                  });
                                },
                              );
                            },
                          ),
                          TextFormField(
                            controller: _cReason,
                            validator: (value) =>
                                (value?.isEmpty ?? true) ? '' : null,
                            minLines: 1,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              labelText: 'Reason',
                            ),
                          ),
                          TextFormField(
                            controller: _cAmount,
                            readOnly: widget.expense != null,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) =>
                                (value?.isEmpty ?? true) ? '' : null,
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                            ),
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
                          onPressed: isUpdating
                              ? null
                              : () {
                                  if (_form.currentState!.validate()) {
                                    setState(() {
                                      isUpdating = true;
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
                          child: isUpdating
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: theme.activeTextIconColor,
                                  ),
                                )
                              : Text(widget.expense == null ? 'ADD' : 'UPDATE'),
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

  void _update(WidgetRef ref) async {
    final activeAgent = LocalStorage.nosql.activeAgent;

    final ServiceUser? user = activeAgent != null
        ? ServiceUser.fromMap(activeAgent)
        : ref.read(authenticationServiceProvider).value?.user;
    final details = (
      reason: _cReason.text,
      type: selectedType as String,
      amount: _cAmount.text,
      category: selectedCategory as String,
      prevAmount: widget.expense?['amount'].toString() ?? '',
      id: widget.expense?['id'].toString() ?? '',
      store: user?.type == SUPERADMIN_TYPE_NAME
          ? (shopId ?? '')
          : (user?.storeId ?? ''),
    );
    try {
      await ref
          .read(expenseServicesProvider.notifier)
          .add(details: details, isUpdate: widget.expense != null);
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop('200');
    } catch (e) {
      print(e);
      setState(() {
        isUpdating = false;
      });
    }
  }
}
