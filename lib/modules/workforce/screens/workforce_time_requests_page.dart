import 'package:venastudio/common.dart';

class WorkforceTimeRequestsPage extends ConsumerStatefulWidget {
  const WorkforceTimeRequestsPage({super.key});

  @override
  ConsumerState<WorkforceTimeRequestsPage> createState() =>
      _WorkforceTimeRequestsPageState();
}

class _WorkforceTimeRequestsPageState
    extends ConsumerState<WorkforceTimeRequestsPage> {
  final api = WorkforceApi();

  bool loading = true;
  String filter = '';
  String typeFilter = '';
  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> employees = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final r = await Future.wait([
        api.timeRequests(ref, status: filter, requestType: typeFilter),
        api.employees(ref),
      ]);
      rows = r[0];
      employees = r[1];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> grantBulk() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _BulkTimeRequestDialog(api: api, ref_: ref, employees: employees),
    );
    if (ok == true) load();
  }

  Future<void> act(Map<String, dynamic> r, bool approve) async {
    String note = '';

    if (!approve) {
      final typed = await _RejectDialog.show(context);
      if (typed == null) return;
      note = typed;
    }

    try {
      await api.timeRequestAction(
        ref,
        requestId: '${r['id']}',
        action: approve ? 'approve' : 'reject',
        note: note,
      );
      load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => WfShell(
        title: 'Off & Leave',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: WfPrimaryButton(
              label: 'Bulk Grant',
              icon: Icons.group_add_rounded,
              onTap: grantBulk,
              compact: true,
            ),
          ),
          IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded)),
        ],
        child: loading
            ? const Center(child: CircularProgressIndicator(color: wfTeal))
            : Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['', 'pending', 'approved', 'rejected']
                        .map(
                          (x) => ChoiceChip(
                            label: Text(x.isEmpty ? 'All Status' : x),
                            selected: filter == x,
                            onSelected: (_) {
                              setState(() => filter = x);
                              load();
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      '',
                      'off',
                      'leave',
                      'late_checkin',
                      'early_checkout'
                    ]
                        .map(
                          (x) => ChoiceChip(
                            label: Text(x.isEmpty ? 'All Types' : _label(x)),
                            selected: typeFilter == x,
                            onSelected: (_) {
                              setState(() => typeFilter = x);
                              load();
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: rows.isEmpty
                        ? const WfEmpty(
                            icon: Icons.event_available_rounded,
                            title: 'No requests',
                            message:
                                'Staff off, leave, late check-in and early checkout requests appear here.',
                          )
                        : RefreshIndicator(
                            color: wfTeal,
                            onRefresh: load,
                            child: ListView.separated(
                              itemCount: rows.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final r = rows[i];
                                return _TimeRequestCard(
                                  row: r,
                                  onApprove: () => act(r, true),
                                  onReject: () => act(r, false),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      );
}

class _TimeRequestCard extends StatelessWidget {
  const _TimeRequestCard({
    required this.row,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> row;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final type = '${row['request_type'] ?? ''}';
    final status = '${row['status'] ?? 'pending'}'.toLowerCase();
    final start = '${row['start_date'] ?? row['from_date'] ?? ''}';
    final end = '${row['end_date'] ?? row['to_date'] ?? start}';
    final reason = '${row['reason'] ?? ''}'.trim();
    final requestedTime = '${row['requested_time'] ?? ''}'.trim();
    final shiftTime = '${row['shift_time'] ?? ''}'.trim();
    final title = '${row['display_title'] ?? _title(type)}';
    final rejection = '${row['rejection_reason'] ?? ''}'.trim();
    final reviewActor = '${row['review_actor_name'] ?? row['reviewed_by_name'] ?? row['approved_by_name'] ?? ''}'.trim();
    final reviewActorId = '${row['review_actor_id'] ?? row['reviewed_by'] ?? row['approved_by'] ?? ''}'.trim();
    final reviewedAt = '${row['reviewed_at_text'] ?? row['reviewed_at'] ?? row['approved_at'] ?? ''}'.trim();
    final reviewLabel = status == 'approved'
        ? 'Approved by'
        : status == 'rejected'
            ? 'Rejected by'
            : '';
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE5EEF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          WfIconBox(icon: _icon(type), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${row['staff_name'] ?? 'Staff'}',
                  style: const TextStyle(
                      color: wfDark, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(title,
                  style: const TextStyle(
                      color: wfDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
              const SizedBox(height: 3),
              Text(start == end ? start : '$start to $end',
                  style: const TextStyle(
                      color: wfMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ]),
          ),
          WfChip(label: status, color: color),
        ]),
        if (shiftTime.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            type == 'late_checkin'
                ? 'Shift starts: $shiftTime'
                : 'Shift ends: $shiftTime',
            style: const TextStyle(color: wfMuted, fontWeight: FontWeight.w700),
          ),
        ],
        if (requestedTime.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            type == 'late_checkin'
                ? 'Requested arrival: $requestedTime'
                : 'Requested checkout: $requestedTime',
            style: const TextStyle(color: wfTeal, fontWeight: FontWeight.w900),
          ),
        ],
        if (reason.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(reason,
              style:
                  const TextStyle(color: wfMuted, fontWeight: FontWeight.w600)),
        ],
        if (rejection.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Rejected: $rejection',
              style: const TextStyle(
                  color: Colors.redAccent, fontWeight: FontWeight.w700)),
        ],
        if (reviewLabel.isNotEmpty &&
            (reviewActor.isNotEmpty || reviewActorId.isNotEmpty || reviewedAt.isNotEmpty)) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(.18)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user_rounded, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      if (reviewActor.isNotEmpty)
                        '$reviewLabel: $reviewActor'
                      else if (reviewActorId.isNotEmpty)
                        '$reviewLabel ID: $reviewActorId',
                      if (reviewedAt.isNotEmpty) 'at $reviewedAt',
                    ].join(' • '),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (status == 'pending') ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            WfPrimaryButton(
              label: 'Approve',
              icon: Icons.check_rounded,
              onTap: onApprove,
              compact: true,
            ),
            WfGhostButton(
              label: 'Reject',
              icon: Icons.close_rounded,
              onTap: onReject,
            ),
          ]),
        ],
      ]),
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const _RejectDialog(),
    );
  }

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final controller = TextEditingController(text: 'Rejected');

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Request'),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Reason',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}

class _BulkTimeRequestDialog extends StatefulWidget {
  const _BulkTimeRequestDialog(
      {required this.api, required this.ref_, required this.employees});
  final WorkforceApi api;
  final WidgetRef ref_;
  final List<Map<String, dynamic>> employees;

  @override
  State<_BulkTimeRequestDialog> createState() => _BulkTimeRequestDialogState();
}

class _BulkTimeRequestDialogState extends State<_BulkTimeRequestDialog> {
  final reason = TextEditingController();
  final search = TextEditingController();
  final Set<String> selected = {};
  String type = 'off';
  DateTime start = DateTime.now();
  DateTime end = DateTime.now();
  bool saving = false;

  List<Map<String, dynamic>> get filtered {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return widget.employees;
    return widget.employees
        .where((e) => '${e['name'] ?? ''}'.toLowerCase().contains(q))
        .toList();
  }

  Future<void> pickStart() async {
    final d = await showDatePicker(
        context: context,
        initialDate: start,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035));
    if (d != null) setState(() => start = d);
  }

  Future<void> pickEnd() async {
    final d = await showDatePicker(
        context: context,
        initialDate: end.isBefore(start) ? start : end,
        firstDate: start,
        lastDate: DateTime(2035));
    if (d != null) setState(() => end = d);
  }

  Future<void> save() async {
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one staff')));
      return;
    }

    setState(() => saving = true);
    try {
      await widget.api.post('/workforce/time_request_bulk_grant.php',
          widget.ref_, {
        'employee_ids': selected.join(','),
        'request_type': type,
        'date': wfDate(start),
        'start_date': wfDate(start),
        'end_date': wfDate(end),
        'from_date': wfDate(start),
        'to_date': wfDate(end),
        'reason': reason.text.trim().isEmpty
            ? 'Bulk granted by management'
            : reason.text.trim(),
        'user_id': widget.api.ctx(widget.ref_).userId,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    if (mounted) setState(() => saving = false);
  }

  @override
  void dispose() {
    reason.dispose();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = filtered;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Bulk Grant Off / Leave',
          style: TextStyle(color: wfDark, fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: 760,
        height: 620,
        child: Column(children: [
          Wrap(spacing: 10, runSpacing: 10, children: [
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: type,
                decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16))),
                items: const [
                  DropdownMenuItem(value: 'off', child: Text('Off')),
                  DropdownMenuItem(value: 'leave', child: Text('Leave')),
                ],
                onChanged: (v) => setState(() => type = v ?? 'off'),
              ),
            ),
            WfGhostButton(
                label: 'Start ${wfShortDate(wfDate(start))}',
                icon: Icons.calendar_month_rounded,
                onTap: pickStart),
            WfGhostButton(
                label: 'End ${wfShortDate(wfDate(end))}',
                icon: Icons.event_rounded,
                onTap: pickEnd),
          ]),
          const SizedBox(height: 12),
          WfTextField(controller: reason, label: 'Reason', maxLines: 2),
          const SizedBox(height: 12),
          TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
                labelText: 'Search staff',
                prefixIcon: const Icon(Icons.search_rounded),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
          ),
          Row(children: [
            TextButton(
              onPressed: () => setState(() {
                selected
                  ..clear()
                  ..addAll(items.map((e) => '${e['id']}'));
              }),
              child: const Text('Select visible'),
            ),
            TextButton(
                onPressed: () => setState(selected.clear),
                child: const Text('Clear')),
            const Spacer(),
            WfChip(label: '${selected.length} selected', color: wfTeal),
          ]),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = items[i];
                final id = '${e['id']}';
                return CheckboxListTile(
                  value: selected.contains(id),
                  activeColor: wfTeal,
                  onChanged: (v) => setState(() =>
                      v == true ? selected.add(id) : selected.remove(id)),
                  title: Text('${e['name'] ?? 'Staff'}'),
                  subtitle: Text('${e['role'] ?? e['type'] ?? ''}'),
                );
              },
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: saving ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        ElevatedButton(
            onPressed: saving ? null : save,
            child: Text(saving ? 'Saving...' : 'Grant ${selected.length} Staff')),
      ],
    );
  }
}

Color _statusColor(String status) {
  if (status == 'approved') return wfTeal;
  if (status == 'declined' || status == 'rejected') return Colors.redAccent;
  return Colors.orange;
}

IconData _icon(String type) {
  if (type == 'leave') return Icons.flight_takeoff_rounded;
  if (type == 'late_checkin') return Icons.login_rounded;
  if (type == 'early_checkout') return Icons.logout_rounded;
  return Icons.weekend_rounded;
}

String _title(String type) {
  if (type == 'leave') return 'Leave Request';
  if (type == 'late_checkin') return 'Late Check-in Request';
  if (type == 'early_checkout') return 'Early Checkout Request';
  return 'Off Day Request';
}

String _label(String type) {
  if (type == 'leave') return 'Leave';
  if (type == 'late_checkin') return 'Late Check-in';
  if (type == 'early_checkout') return 'Early Checkout';
  if (type == 'off') return 'Off';
  return type;
}
