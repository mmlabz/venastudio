import 'package:venastudio/common.dart';

const Color financeSetupBg = Color(0xffEEF9FB);
const Color financeSetupCard = Color(0xffffffff);
const Color financeSetupTeal = Color(0xff43C5D8);
const Color financeSetupDark = Color(0xff07304A);
const Color financeSetupMuted = Color(0xff668392);
const Color financeSetupLine = Color(0xffCFEFF4);
const Color financeSetupSoftTeal = Color(0xffE4F8FB);
const Color financeSetupWarning = Color(0xffF4A62A);
const Color financeSetupSuccess = Color(0xff13A76B);
const Color financeSetupDanger = Color(0xffD94B4B);

class FinanceSetupPage extends ConsumerStatefulWidget {
  const FinanceSetupPage({super.key});

  @override
  ConsumerState<FinanceSetupPage> createState() => _FinanceSetupPageState();
}

class _FinanceSetupPageState extends ConsumerState<FinanceSetupPage> {
  bool categoriesOpen = true;
  bool paymentOptionsOpen = true;

  @override
  Widget build(BuildContext context) {
    final user = financeCurrentUserFromWidget(ref);
    final isSuperAdmin = financeIsSuperAdmin(user);

    if (!isSuperAdmin) {
      return Scaffold(
        backgroundColor: financeSetupBg,
        appBar: _appBar(),
        body: const Center(
          child: Text(
            'Only superadmin can manage finance setup.',
            style: TextStyle(
              color: financeSetupDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    final categories = ref.watch(financeExpenseCategoriesProvider);
    final options = ref.watch(financePaymentOptionsProvider);

    return Scaffold(
      backgroundColor: financeSetupBg,
      appBar: _appBar(),
      body: RefreshIndicator(
        color: financeSetupTeal,
        onRefresh: () async {
          await ref.read(financeExpenseCategoriesProvider.notifier).load();
          await ref.read(financePaymentOptionsProvider.notifier).load();
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 850;

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              children: [
                _hero(categories, options),
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child:
                              _categoriesPanel(categories, collapsible: false)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _paymentOptionsPanel(options,
                              collapsible: false)),
                    ],
                  )
                else ...[
                  _categoriesPanel(categories, collapsible: true),
                  const SizedBox(height: 14),
                  _paymentOptionsPanel(options, collapsible: true),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: financeSetupBg,
      foregroundColor: financeSetupDark,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Finance Setup',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: financeSetupDark,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () async {
            await ref.read(financeExpenseCategoriesProvider.notifier).load();
            await ref.read(financePaymentOptionsProvider.notifier).load();
          },
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _hero(
    AsyncValue<List<Map<String, dynamic>>> categories,
    AsyncValue<List<Map<String, dynamic>>> options,
  ) {
    final catCount = categories.valueOrNull?.length ?? 0;
    final optionCount = options.valueOrNull?.length ?? 0;
    final cashImpactCount = (options.valueOrNull ?? [])
        .where((e) => '${e['affects_cash_reconciliation'] ?? 0}' == '1')
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            financeSetupTeal.withOpacity(.95),
            const Color(0xff2AA8C4),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: financeSetupTeal.withOpacity(.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finance Control Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage expense categories and payment options used across Vena Studio.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _heroStat('Categories', '$catCount')),
              const SizedBox(width: 10),
              Expanded(child: _heroStat('Payment Options', '$optionCount')),
              const SizedBox(width: 10),
              Expanded(child: _heroStat('Cash Impact', '$cashImpactCount')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(.92),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoriesPanel(
    AsyncValue<List<Map<String, dynamic>>> categories, {
    required bool collapsible,
  }) {
    return _panel(
      title: 'Expense Categories',
      subtitle: 'Cost groups staff can select when recording expenses.',
      actionLabel: 'New Category',
      actionIcon: Icons.add_rounded,
      collapsible: collapsible,
      isOpen: categoriesOpen,
      onToggle: () => setState(() => categoriesOpen = !categoriesOpen),
      onAction: () => _CategoryDialog.show(context),
      child: categories.when(
        loading: () => const _LoadingBlock(),
        error: (e, _) => _ErrorBlock(
          message: '$e',
          hint:
              'Check expense_categories.php and confirm expense_categories has is_active column.',
        ),
        data: (data) {
          if (data.isEmpty) {
            return const _EmptyBlock(
              icon: Icons.category_outlined,
              title: 'No categories yet',
              message:
                  'Create categories like Rent, Transport, Supplies, Marketing.',
            );
          }

          return Column(
            children: data.map((e) {
              final name = '${e['expense'] ?? e['category'] ?? ''}';
              final active = '${e['is_active'] ?? 1}' == '1';

              return _setupTile(
                icon: Icons.folder_copy_rounded,
                title: name,
                subtitle: active ? 'Active expense category' : 'Inactive',
                badge: active ? 'Active' : 'Off',
                badgeColor: active ? financeSetupSuccess : financeSetupWarning,
                onTap: () => _CategoryDialog.show(context, item: e),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _paymentOptionsPanel(
    AsyncValue<List<Map<String, dynamic>>> options, {
    required bool collapsible,
  }) {
    return _panel(
      title: 'Payment Options',
      subtitle: 'How expenses are paid and whether they affect physical cash.',
      actionLabel: 'New Option',
      actionIcon: Icons.add_card_rounded,
      collapsible: collapsible,
      isOpen: paymentOptionsOpen,
      onToggle: () => setState(() => paymentOptionsOpen = !paymentOptionsOpen),
      onAction: () => _PaymentOptionDialog.show(context),
      child: options.when(
        loading: () => const _LoadingBlock(),
        error: (e, _) => _ErrorBlock(
          message: '$e',
          hint: 'Check payment_options.php and payment_options table.',
        ),
        data: (data) {
          if (data.isEmpty) {
            return const _EmptyBlock(
              icon: Icons.credit_card_off_rounded,
              title: 'No payment options yet',
              message: 'Create Cash, M-PESA, Bank or other payment methods.',
            );
          }

          return Column(
            children: data.map((e) {
              final name = '${e['name'] ?? ''}';
              final code = '${e['code'] ?? ''}';
              final hasFee = '${e['has_transaction_cost'] ?? 0}' == '1';
              final cashImpact =
                  '${e['affects_cash_reconciliation'] ?? 0}' == '1';

              return _setupTile(
                icon: cashImpact
                    ? Icons.money_rounded
                    : Icons.account_balance_rounded,
                title: name,
                subtitle:
                    '$code • Transaction cost: ${hasFee ? 'Yes' : 'No'} • Cash impact: ${cashImpact ? 'Yes' : 'No'}',
                badge: cashImpact ? 'Cash' : 'Non-cash',
                badgeColor: cashImpact ? financeSetupSuccess : financeSetupTeal,
                onTap: () => _PaymentOptionDialog.show(context, item: e),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _panel({
    required String title,
    required String subtitle,
    required String actionLabel,
    required IconData actionIcon,
    required bool collapsible,
    required bool isOpen,
    required VoidCallback onToggle,
    required VoidCallback onAction,
    required Widget child,
  }) {
    final showBody = !collapsible || isOpen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: financeSetupCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: financeSetupLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: collapsible ? onToggle : null,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                if (collapsible) ...[
                  Icon(
                    isOpen
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    color: financeSetupDark,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: financeSetupDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: financeSetupMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: financeSetupTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(actionIcon, size: 18),
                  label: Text(
                    actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState:
                showBody ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: child,
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _setupTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xffFAFEFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: financeSetupLine),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: onTap,
        leading: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: financeSetupSoftTeal,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: financeSetupTeal, size: 21),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: financeSetupDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: financeSetupMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
            const Icon(Icons.edit_rounded, color: financeSetupMuted),
          ],
        ),
      ),
    );
  }
}

class _CategoryDialog extends ConsumerStatefulWidget {
  const _CategoryDialog({this.item});

  final Map<String, dynamic>? item;

  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? item,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _CategoryDialog(item: item),
    );
  }

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  final name = TextEditingController();
  bool active = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    if (item != null) {
      name.text = '${item['expense'] ?? item['category'] ?? ''}';
      active = '${item['is_active'] ?? 1}' == '1';
    }
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add Category' : 'Edit Category'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: active,
              onChanged: (v) => setState(() => active = v),
              title: const Text('Active'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
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
    if (name.text.trim().isEmpty) return;

    setState(() => saving = true);

    try {
      await ref.read(financeExpenseCategoriesProvider.notifier).save(
            id: '${widget.item?['id'] ?? ''}',
            name: name.text.trim(),
            isActive: active ? '1' : '0',
          );

      if (mounted) Navigator.pop(context);
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

class _PaymentOptionDialog extends ConsumerStatefulWidget {
  const _PaymentOptionDialog({this.item});

  final Map<String, dynamic>? item;

  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? item,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _PaymentOptionDialog(item: item),
    );
  }

  @override
  ConsumerState<_PaymentOptionDialog> createState() =>
      _PaymentOptionDialogState();
}

class _PaymentOptionDialogState extends ConsumerState<_PaymentOptionDialog> {
  final name = TextEditingController();
  final code = TextEditingController();

  bool hasFee = false;
  bool cashImpact = false;
  bool active = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    if (item != null) {
      name.text = '${item['name'] ?? ''}';
      code.text = '${item['code'] ?? ''}';
      hasFee = '${item['has_transaction_cost'] ?? 0}' == '1';
      cashImpact = '${item['affects_cash_reconciliation'] ?? 0}' == '1';
      active = '${item['is_active'] ?? 1}' == '1';
    }
  }

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.item == null ? 'Add Payment Option' : 'Edit Payment Option',
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: code,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  hintText: 'cash / mpesa / bank',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: hasFee,
                onChanged: (v) => setState(() => hasFee = v),
                title: const Text('Has Transaction Cost'),
              ),
              SwitchListTile(
                value: cashImpact,
                onChanged: (v) => setState(() => cashImpact = v),
                title: const Text('Affects Cash Reconciliation'),
                subtitle: const Text(
                  'Only cash-like methods should reduce physical cash.',
                ),
              ),
              SwitchListTile(
                value: active,
                onChanged: (v) => setState(() => active = v),
                title: const Text('Active'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
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
    if (name.text.trim().isEmpty || code.text.trim().isEmpty) return;

    setState(() => saving = true);

    try {
      await ref.read(financePaymentOptionsProvider.notifier).save(
            id: '${widget.item?['id'] ?? ''}',
            name: name.text.trim(),
            code: code.text.trim().toLowerCase().replaceAll(' ', '_'),
            hasTransactionCost: hasFee,
            affectsCashReconciliation: cashImpact,
            isActive: active,
          );

      if (mounted) Navigator.pop(context);
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

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(22),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({
    required this.message,
    required this.hint,
  });

  final String message;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffFFF7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffFFD0D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Could not load this section',
            style: TextStyle(
              color: financeSetupDanger,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(message),
          const SizedBox(height: 5),
          Text(
            hint,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({
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
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xffFAFEFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: financeSetupLine),
      ),
      child: Column(
        children: [
          Icon(icon, color: financeSetupTeal, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: financeSetupDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: financeSetupMuted),
          ),
        ],
      ),
    );
  }
}
