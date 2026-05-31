import 'package:venastudio/common.dart';

class CashReconciliationPage extends ConsumerStatefulWidget {
  const CashReconciliationPage({super.key});

  @override
  ConsumerState<CashReconciliationPage> createState() => _CashReconciliationPageState();
}

class _CashReconciliationPageState extends ConsumerState<CashReconciliationPage> {
  static const Color bg = Color(0xffEEF9FB);
  static const Color teal = Color(0xff00BFD8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff6B8794);
  static const Color line = Color(0xffCFEFF4);
  static const Color danger = Color(0xffD94B4B);
  static const Color success = Color(0xff13A76B);
  static const Color amber = Color(0xffF4A62A);

  final closing = TextEditingController();
  final notes = TextEditingController();
  final explanation = TextEditingController();

  @override
  void dispose() { closing.dispose(); notes.dispose(); explanation.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashReconciliationProvider);
    final user = financeCurrentUserFromWidget(ref);
    final isAdmin = financeIsAdmin(user);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: dark,
        elevation: 0,
        leading: context.backIcon(ref, () => context.go('/settings')),
        title: const Text('Cash Reconciliation', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: _pickDate, icon: const Icon(Icons.calendar_month_rounded))],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator(color: teal)),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final summary = Map<String, dynamic>.from(data['summary'] ?? {});
          final reports = data['reports'] is List ? (data['reports'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
          final myReport = data['my_report'] is Map ? Map<String, dynamic>.from(data['my_report']) : <String, dynamic>{};
          final expected = double.tryParse('${summary['expected_cash'] ?? 0}') ?? 0;
          final cashSales = double.tryParse('${summary['cash_sales'] ?? 0}') ?? 0;
          final expenses = double.tryParse('${summary['expenses'] ?? 0}') ?? 0;
          final hasSubmitted = myReport.isNotEmpty;
          final reported = double.tryParse('${myReport['reported_cash'] ?? 0}') ?? 0;
          final variance = reported - expected;
          final reportId = '${myReport['id'] ?? ''}';
          final explanationSubmitted = '${myReport['variance_explanation'] ?? ''}'.trim().isNotEmpty;

          return RefreshIndicator(
            color: teal,
            onRefresh: () => ref.read(cashReconciliationProvider.notifier).load(),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              if (isAdmin) ...[_adminSummary(cashSales, expenses, expected), const SizedBox(height: 14)],
              if (!hasSubmitted)
                _closingForm()
              else
                _afterSubmissionCard(
                  expected: expected,
                  reported: reported,
                  variance: variance,
                  reportId: reportId,
                  explanationSubmitted: explanationSubmitted,
                  existingExplanation: '${myReport['variance_explanation'] ?? ''}',
                ),
              const SizedBox(height: 14),
              if (isAdmin) ...[
                const Text('Reported Closings', style: TextStyle(color: dark, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 10),
                if (reports.isEmpty) const _ReconEmpty() else ...reports.map(_reportCard),
              ],
            ]),
          );
        },
      ),
    );
  }

  Widget _adminSummary(double cashSales, double expenses, double expected) => Row(children: [
    Expanded(child: _stat('Cash Sales', cashSales, success)),
    const SizedBox(width: 10),
    Expanded(child: _stat('Expenses', expenses, danger)),
    const SizedBox(width: 10),
    Expanded(child: _stat('Expected Cash', expected, teal)),
  ]);

  Widget _stat(String label, double amount, Color color) => Container(
    padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12)),
      const SizedBox(height: 5),
      Text(amount.money, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
    ]),
  );

  Widget _closingForm() => Container(
    padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Submit Closing Cash', style: TextStyle(color: dark, fontWeight: FontWeight.w900, fontSize: 18)),
      const SizedBox(height: 6),
      const Text('Enter the actual cash counted at closing. Expected cash will be shown after submission.', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      TextField(controller: closing, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cash counted at closing')),
      TextField(controller: notes, minLines: 1, maxLines: 4, decoration: const InputDecoration(labelText: 'Notes')),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _submit, icon: const Icon(Icons.save_rounded), label: const Text('Submit Closing'))),
    ]),
  );

  Widget _afterSubmissionCard({required double expected, required double reported, required double variance, required String reportId, required bool explanationSubmitted, required String existingExplanation}) {
    final hasVariance = variance.abs() > 0.0001;
    return Container(
      padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Closing Submitted', style: TextStyle(color: dark, fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 12),
        _miniRow('Expected Cash', expected.money, teal),
        _miniRow('Reported Cash', reported.money, dark),
        _miniRow('Variance', variance.money, variance == 0 ? success : variance < 0 ? danger : amber),
        if (hasVariance) ...[
          const SizedBox(height: 14),
          if (explanationSubmitted)
            Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bg, border: Border.all(color: line)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Variance Explanation', style: TextStyle(color: dark, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5), Text(existingExplanation, style: const TextStyle(color: muted)),
            ]))
          else ...[
            const Text('Variance explanation is required.', style: TextStyle(color: danger, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            TextField(controller: explanation, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Explain the variance')),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _submitExplanation(reportId), icon: const Icon(Icons.notes_rounded), label: const Text('Submit Explanation'))),
          ],
        ],
      ]),
    );
  }

  Widget _miniRow(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: muted, fontWeight: FontWeight.w800))), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900))]),
  );

  Widget _reportCard(Map<String, dynamic> r) {
    final expected = double.tryParse('${r['expected_cash'] ?? 0}') ?? 0;
    final reported = double.tryParse('${r['reported_cash'] ?? 0}') ?? 0;
    final variance = reported - expected;
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line)),
      child: Row(children: [
        Icon(variance == 0 ? Icons.verified_rounded : variance < 0 ? Icons.warning_amber_rounded : Icons.trending_up_rounded, color: variance == 0 ? success : variance < 0 ? danger : teal),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${r['store_id'] ?? r['store'] ?? 'Store'} • ${r['report_date'] ?? ''}', style: const TextStyle(color: dark, fontWeight: FontWeight.w900)),
          Text('Reported: ${reported.money} • Expected: ${expected.money}', style: const TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
          Text('By: ${r['reported_by_name'] ?? r['user_name'] ?? ''}', style: const TextStyle(color: muted, fontSize: 12)),
          if ('${r['variance_explanation'] ?? ''}'.trim().isNotEmpty) Text('Explanation: ${r['variance_explanation']}', style: const TextStyle(color: muted, fontSize: 12)),
        ])),
        Text(variance.money, style: TextStyle(color: variance == 0 ? success : variance < 0 ? danger : teal, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Future<void> _pickDate() async {
    final notifier = ref.read(cashReconciliationProvider.notifier);
    final d = await showDatePicker(context: context, initialDate: notifier.selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (d != null) await notifier.load(date: d);
  }

  Future<void> _submit() async {
    if (closing.text.trim().isEmpty) return;
    try {
      await ref.read(cashReconciliationProvider.notifier).submitClosing(amount: closing.text.trim(), notes: notes.text.trim());
      closing.clear(); notes.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Closing submitted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _submitExplanation(String reportId) async {
    if (reportId.isEmpty || explanation.text.trim().isEmpty) return;
    try {
      await ref.read(cashReconciliationProvider.notifier).submitExplanation(reportId: reportId, explanation: explanation.text.trim());
      explanation.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Explanation submitted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class _ReconEmpty extends StatelessWidget {
  const _ReconEmpty();
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _CashReconciliationPageState.line)), child: const Text('No closing reports submitted yet.', style: TextStyle(color: _CashReconciliationPageState.muted, fontWeight: FontWeight.w800)));
}
