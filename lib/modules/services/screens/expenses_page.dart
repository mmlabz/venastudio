import 'package:venastudio/common.dart';

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff00BFD8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff6B8794);
  static const Color line = Color(0xffCFEFF4);
  static const Color danger = Color(0xffD94B4B);
  static const Color success = Color(0xff13A76B);

  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(financeExpensesProvider);
    final user = financeCurrentUserFromWidget(ref);
    final isAdmin = financeIsAdmin(user);
    final isSuperAdmin = financeIsSuperAdmin(user);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: dark,
        elevation: 0,
        leading: context.backIcon(ref, () => context.go('/settings')),
        title: const Text(
          'Expenses',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          if (isSuperAdmin)
            IconButton(
              tooltip: 'Finance Setup',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FinanceSetupPage(),
                  ),
                );
              },
              icon: const Icon(Icons.tune_rounded),
            ),
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          TextButton.icon(
            onPressed: () async {
              final ok = await _ExpenseDialog.show(
                context,
                selectedDate: selectedDate,
              );

              if (ok == true) {
                await ref.read(financeExpensesProvider.notifier).load(
                      start: selectedDate,
                      end: selectedDate,
                    );
              }
            },
            icon: const Icon(Icons.add_rounded, color: teal),
            label: const Text(
              'Add',
              style: TextStyle(color: teal, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      body: rows.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: teal),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final debit = data
              .where((e) => '${e['type']}' == 'debit')
              .fold<double>(
                0,
                (s, e) =>
                    s +
                    (double.tryParse('${e['amount'] ?? e['expense'] ?? 0}') ??
                        0) +
                    (double.tryParse('${e['transaction_cost'] ?? 0}') ?? 0),
              );

          final credit = data
              .where((e) => '${e['type']}' == 'credit')
              .fold<double>(
                0,
                (s, e) =>
                    s +
                    (double.tryParse('${e['amount'] ?? e['expense'] ?? 0}') ??
                        0),
              );

          return RefreshIndicator(
            color: teal,
            onRefresh: () {
              return ref.read(financeExpensesProvider.notifier).load(
                    start: selectedDate,
                    end: selectedDate,
                  );
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (isAdmin) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _stat(
                          'Cash Out',
                          debit,
                          danger,
                          Icons.arrow_upward_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _stat(
                          'Cash In',
                          credit,
                          success,
                          Icons.arrow_downward_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                if (data.isEmpty)
                  const _EmptyFinance(
                    icon: Icons.receipt_long_rounded,
                    title: 'No expenses today',
                    message:
                        'Record petty cash, supplies, transport or any cash movement here.',
                  )
                else
                  ...data.map(_expenseCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (d != null) {
      setState(() => selectedDate = d);
      await ref.read(financeExpensesProvider.notifier).load(start: d, end: d);
    }
  }

  Widget _stat(String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  amount.money,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseCard(Map<String, dynamic> row) {
    final isDebit = '${row['type']}' == 'debit';
    final amount =
        double.tryParse('${row['amount'] ?? row['expense'] ?? 0}') ?? 0;
    final trx = double.tryParse('${row['transaction_cost'] ?? 0}') ?? 0;
    final total = amount + trx;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Icon(
            isDebit
                ? Icons.call_made_rounded
                : Icons.call_received_rounded,
            color: isDebit ? danger : success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${row['category'] ?? row['expense_category'] ?? row['classification'] ?? 'Expense'}',
                  style: const TextStyle(
                    color: dark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${row['description'] ?? row['reason'] ?? ''}',
                  style: const TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${row['payment_method'] ?? 'cash'}'
                  '${trx > 0 ? ' • Fee ${trx.money}' : ''}'
                  '${('${row['reference_no'] ?? ''}'.isNotEmpty) ? ' • Ref ${row['reference_no']}' : ''}',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
                Text(
                  '${row['date_added'] ?? row['added_date'] ?? row['dt'] ?? ''}',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            total.money,
            style: TextStyle(
              color: isDebit ? danger : success,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseDialog extends ConsumerStatefulWidget {
  const _ExpenseDialog({required this.selectedDate});

  final DateTime selectedDate;

  static Future<bool?> show(
    BuildContext context, {
    required DateTime selectedDate,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => _ExpenseDialog(selectedDate: selectedDate),
    );
  }

  @override
  ConsumerState<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends ConsumerState<_ExpenseDialog> {
  final amount = TextEditingController();
  final transactionCost = TextEditingController(text: '0');
  final referenceNo = TextEditingController();
  final reason = TextEditingController();

  String type = 'debit';
  String? category;
  Map<String, dynamic>? paymentOption;
  bool saving = false;

  @override
  void dispose() {
    amount.dispose();
    transactionCost.dispose();
    referenceNo.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(financeExpenseCategoriesProvider);
    final options = ref.watch(financePaymentOptionsProvider);

    final hasTransactionCost =
        '${paymentOption?['has_transaction_cost'] ?? 0}' == '1';

    return AlertDialog(
      title: const Text('Record Expense'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(
                    value: 'debit',
                    child: Text('Cash Out / Expense'),
                  ),
                  DropdownMenuItem(
                    value: 'credit',
                    child: Text('Cash In / Adjustment'),
                  ),
                ],
                onChanged: (v) => setState(() => type = v ?? 'debit'),
              ),
              cats.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox(),
                data: (data) {
                  return DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: data.map((e) {
                      final label = '${e['expense'] ?? e['category']}';
                      return DropdownMenuItem<String>(
                        value: label,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => category = v),
                  );
                },
              ),
              options.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox(),
                data: (data) {
                  return DropdownButtonFormField<String>(
                    value: paymentOption == null
                        ? null
                        : '${paymentOption!['id']}',
                    decoration:
                        const InputDecoration(labelText: 'Payment Method'),
                    items: data.map((e) {
                      return DropdownMenuItem<String>(
                        value: '${e['id']}',
                        child: Text('${e['name']}'),
                      );
                    }).toList(),
                    onChanged: (v) {
                      final selected = data.where((e) => '${e['id']}' == v);
                      setState(() {
                        paymentOption =
                            selected.isEmpty ? null : selected.first;
                      });
                    },
                  );
                },
              ),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              if (hasTransactionCost)
                TextField(
                  controller: transactionCost,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Transaction Cost'),
                ),
              TextField(
                controller: referenceNo,
                decoration: const InputDecoration(
                  labelText: 'Reference No. / Transaction Code',
                ),
              ),
              TextField(
                controller: reason,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Reason / Description',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: saving ? null : _save,
          child: Text(saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (amount.text.trim().isEmpty ||
        category == null ||
        paymentOption == null ||
        reason.text.trim().isEmpty) {
      return;
    }

    setState(() => saving = true);

    try {
      await ref.read(financeExpensesProvider.notifier).addExpense(
            amount: amount.text.trim(),
            category: category!,
            reason: reason.text.trim(),
            type: type,
            paymentOptionId: '${paymentOption!['id']}',
            paymentMethod: '${paymentOption!['code']}',
            transactionCost: transactionCost.text.trim().isEmpty
                ? '0'
                : transactionCost.text.trim(),
            referenceNo: referenceNo.text.trim(),
            date: widget.selectedDate,
          );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }

    if (mounted) setState(() => saving = false);
  }
}

class _EmptyFinance extends StatelessWidget {
  const _EmptyFinance({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _ExpensesPageState.line),
      ),
      child: Column(
        children: [
          Icon(icon, color: _ExpensesPageState.teal, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: _ExpensesPageState.dark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ExpensesPageState.muted),
          ),
        ],
      ),
    );
  }
}
