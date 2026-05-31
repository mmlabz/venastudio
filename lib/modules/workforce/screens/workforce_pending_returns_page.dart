import 'package:venastudio/common.dart';

class WorkforcePendingReturnsPage extends ConsumerStatefulWidget {
  const WorkforcePendingReturnsPage({super.key});

  @override
  ConsumerState<WorkforcePendingReturnsPage> createState() =>
      _WorkforcePendingReturnsPageState();
}

class _WorkforcePendingReturnsPageState
    extends ConsumerState<WorkforcePendingReturnsPage> {
  final api = WorkforceApi();
  bool loading = true;
  bool confirming = false;
  List<Map<String, dynamic>> returns = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      returns = await api.pendingReturns(ref);
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    }
    if (mounted) setState(() => loading = false);
  }

  int _int(dynamic v) => int.tryParse('$v') ?? 0;
  double _double(dynamic v) => double.tryParse('$v') ?? 0;

  String _fmtQty(dynamic v) {
    final n = _double(v);
    final s = n.toStringAsFixed(2);
    return s.replaceAll(RegExp(r'\.00$'), '').replaceAll(RegExp(r'0$'), '');
  }

  List<Map<String, dynamic>> _itemsOf(Map<String, dynamic> row) {
    final raw = row['items'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> _confirm(Map<String, dynamic> row) async {
    final notes = await _ReturnConfirmDialog.show(context, row);
    if (notes == null) return;

    setState(() => confirming = true);
    try {
      final res = await api.confirmReturn(ref, returnRequestId: _int(row['id']), notes: notes);
      final ok = '${res['success'] ?? res['status'] ?? 0}' == '1' || res['success'] == true;
      if (!ok) throw Exception(res['message'] ?? 'Unable to confirm returned items');
      Fluttertoast.showToast(msg: 'Returned items confirmed');
      await load();
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    }
    if (mounted) setState(() => confirming = false);
  }

  @override
  Widget build(BuildContext context) {
    return WfShell(
      title: 'Pending Returns',
      actions: [
        IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded)),
      ],
      child: loading
          ? const Center(child: CircularProgressIndicator(color: wfTeal))
          : RefreshIndicator(
              color: wfTeal,
              onRefresh: load,
              child: returns.isEmpty
                  ? const WfEmpty(
                      icon: Icons.assignment_return_rounded,
                      title: 'No pending returns',
                      message:
                          'Returned items submitted from VenaPro will appear here for front-office confirmation.',
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      itemCount: returns.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) => _returnCard(returns[index]),
                    ),
            ),
    );
  }

  Widget _returnCard(Map<String, dynamic> row) {
    final items = _itemsOf(row);
    final employeeName = '${row['employee_name'] ?? row['staff_name'] ?? 'Beautician'}';
    final serviceName = '${row['service_name'] ?? 'Service'}';
    final requestId = _int(row['id']);
    final assignmentId = _int(row['assignment_id']);

    return WfCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const WfIconBox(
                icon: Icons.assignment_return_rounded,
                color: wfAmber,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: wfDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$serviceName • Request #$requestId • Assignment #$assignmentId',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: wfMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: wfAmber.withOpacity(.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: wfAmber.withOpacity(.3)),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    color: wfAmber,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text(
              'No items attached to this return request.',
              style: TextStyle(color: wfMuted, fontWeight: FontWeight.w700),
            )
          else
            ...items.map(_returnItemTile),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: WfGhostButton(
                  label: 'Refresh',
                  icon: Icons.refresh_rounded,
                  onTap: load,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: WfPrimaryButton(
                  label: confirming ? 'Confirming...' : 'Confirm Receipt',
                  icon: Icons.check_circle_rounded,
                  onTap: confirming ? () {} : () => _confirm(row),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _returnItemTile(Map<String, dynamic> item) {
    final name = '${item['product_name'] ?? item['name'] ?? 'Product'}';
    final returned = _fmtQty(item['quantity_returned'] ?? item['qty_returned'] ?? 0);
    final damaged = _fmtQty(item['quantity_damaged'] ?? item['qty_damaged'] ?? 0);
    final condition = '${item['condition_returned'] ?? item['condition'] ?? ''}'.trim();
    final tracking = '${item['tracking_type'] ?? item['product_type'] ?? ''}'.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: wfBg.withOpacity(.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: wfLine),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: wfTeal.withOpacity(.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: wfTeal, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (tracking.isNotEmpty) tracking,
                    if (condition.isNotEmpty) 'Condition: $condition',
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: wfMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Returned $returned',
                style: const TextStyle(color: wfSuccess, fontWeight: FontWeight.w900, fontSize: 12),
              ),
              if (_double(damaged) > 0)
                Text(
                  'Damaged $damaged',
                  style: const TextStyle(color: wfDanger, fontWeight: FontWeight.w900, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReturnConfirmDialog extends StatefulWidget {
  const _ReturnConfirmDialog({required this.row});
  final Map<String, dynamic> row;

  static Future<String?> show(BuildContext context, Map<String, dynamic> row) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReturnConfirmDialog(row: row),
    );
  }

  @override
  State<_ReturnConfirmDialog> createState() => _ReturnConfirmDialogState();
}

class _ReturnConfirmDialogState extends State<_ReturnConfirmDialog> {
  final notes = TextEditingController();

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employee = '${widget.row['employee_name'] ?? 'Beautician'}';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Confirm returned items?',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm that front office has physically received the items returned by $employee. Stock will update only after this confirmation.',
            style: const TextStyle(color: wfMuted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: notes,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Confirmation notes',
              hintText: 'Example: Received at reception in good condition',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, notes.text.trim()),
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Confirm Receipt'),
          style: ElevatedButton.styleFrom(
            backgroundColor: wfTeal,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}
