import 'package:venastudio/common.dart';

class WorkforceQueuePage extends ConsumerStatefulWidget {
  const WorkforceQueuePage({super.key});
  @override
  ConsumerState<WorkforceQueuePage> createState() => _WorkforceQueuePageState();
}

class _WorkforceQueuePageState extends ConsumerState<WorkforceQueuePage> {
  final api = WorkforceApi();
  bool loading = true;
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      rows = await api.queue(ref, date: wfDate(DateTime.now()));
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final waiting = rows.where(_isWaiting).toList();
    final busy = rows.where(_isBusy).toList();
    final blocked = rows.where((r) => !_isWaiting(r) && !_isBusy(r)).toList();

    return WfShell(
      title: 'Assignment Queue',
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded))],
      child: loading
          ? const Center(child: CircularProgressIndicator(color: wfTeal))
          : rows.isEmpty
              ? const WfEmpty(
                  icon: Icons.alt_route_rounded,
                  title: 'No queue today',
                  message: 'Staff will appear here after check-in from VenaPro.',
                )
              : RefreshIndicator(
                  color: wfTeal,
                  onRefresh: load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    children: [
                      _QueueSummary(waiting: waiting.length, busy: busy.length, blocked: blocked.length),
                      const SizedBox(height: 14),
                      _SectionTitle(title: 'Eligible Queue', subtitle: 'Only these staff can receive the next job'),
                      const SizedBox(height: 8),
                      if (waiting.isEmpty)
                        const WfCard(child: Text('No eligible beautician is waiting right now.', style: TextStyle(color: wfMuted, fontWeight: FontWeight.w800)))
                      else
                        ...waiting.map((r) => _QueueRow(row: r, mode: _RowMode.waiting)),
                      if (busy.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _SectionTitle(title: 'Busy / Assigned', subtitle: 'Blocked from new work until service completion'),
                        const SizedBox(height: 8),
                        ...busy.map((r) => _QueueRow(row: r, mode: _RowMode.busy)),
                      ],
                      if (blocked.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _SectionTitle(title: 'Not Eligible', subtitle: 'Offline, not checked in, unavailable, or missing queue state'),
                        const SizedBox(height: 8),
                        ...blocked.map((r) => _QueueRow(row: r, mode: _RowMode.blocked)),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  static bool _isBusy(Map<String, dynamic> r) {
    final status = '${r['status'] ?? ''}'.toLowerCase();
    final availability = '${r['availability_status'] ?? ''}'.toLowerCase();
    final order = '${r['current_order_id'] ?? r['assigned_order_id'] ?? r['order_id'] ?? ''}'.trim();
    return status == 'busy' || availability == 'busy' || (order.isNotEmpty && order != '0' && order != 'null');
  }

  static bool _isWaiting(Map<String, dynamic> r) {
    if (_isBusy(r)) return false;
    final status = '${r['status'] ?? ''}'.toLowerCase();
    final availability = '${r['availability_status'] ?? ''}'.toLowerCase();
    final attendance = '${r['attendance_status'] ?? ''}'.toLowerCase();
    final pos = int.tryParse('${r['queue_position'] ?? r['position'] ?? ''}') ?? 0;
    return (status == 'waiting' || status == 'queued' || pos > 0) &&
        (availability == 'available' || availability == 'online' || availability == '') &&
        attendance != 'not_checked_in';
  }
}

class _QueueSummary extends StatelessWidget {
  const _QueueSummary({required this.waiting, required this.busy, required this.blocked});
  final int waiting;
  final int busy;
  final int blocked;

  @override
  Widget build(BuildContext context) {
    return WfGradientCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Live Assignment Health', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Reception should only assign from the eligible queue. Busy staff remain visible but blocked.', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _MiniMetric(label: 'Eligible', value: '$waiting')),
          const SizedBox(width: 10),
          Expanded(child: _MiniMetric(label: 'Busy', value: '$busy')),
          const SizedBox(width: 10),
          Expanded(child: _MiniMetric(label: 'Blocked', value: '$blocked')),
        ]),
      ]),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: wfDark, fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: wfMuted, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    ]);
  }
}

enum _RowMode { waiting, busy, blocked }

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.row, required this.mode});
  final Map<String, dynamic> row;
  final _RowMode mode;

  @override
  Widget build(BuildContext context) {
    final name = '${row['staff_name'] ?? row['employee_name'] ?? row['name'] ?? 'Staff'}';
    final pos = '${row['queue_position'] ?? row['position'] ?? '-'}';
    final status = '${row['status'] ?? ''}'.trim();
    final availability = '${row['availability_status'] ?? ''}'.trim();
    final attendance = '${row['attendance_status'] ?? ''}'.trim();
    final order = '${row['current_order_id'] ?? row['assigned_order_id'] ?? row['order_id'] ?? ''}'.trim();
    final service = '${row['service_name'] ?? row['current_service'] ?? row['main_service'] ?? ''}'.trim();
    final checkin = '${row['checkin_time'] ?? row['joined_at'] ?? ''}'.trim();

    final color = mode == _RowMode.waiting ? wfSuccess : mode == _RowMode.busy ? wfAmber : wfMuted;
    final label = mode == _RowMode.waiting ? (pos == '1' ? 'NEXT' : 'WAITING') : mode == _RowMode.busy ? 'BUSY' : 'BLOCKED';
    final icon = mode == _RowMode.waiting ? Icons.check_circle_rounded : mode == _RowMode.busy ? Icons.spa_rounded : Icons.block_rounded;

    return WfCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Stack(
          alignment: Alignment.center,
          children: [
            WfIconBox(icon: icon, color: color),
            if (mode == _RowMode.waiting)
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(.25))),
                  child: Text('#$pos', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(_details(availability, attendance, status), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: wfMuted, fontWeight: FontWeight.w700, fontSize: 12)),
            if (order.isNotEmpty && order != '0' && order != 'null') ...[
              const SizedBox(height: 4),
              Text('Assigned Order #$order${service.isNotEmpty ? ' • $service' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: wfAmber, fontSize: 12, fontWeight: FontWeight.w900)),
            ] else if (checkin.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Joined: $checkin', style: const TextStyle(color: wfMuted, fontSize: 12)),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        WfChip(label: label, color: color),
      ]),
    );
  }

  static String _details(String availability, String attendance, String status) {
    final parts = [availability, attendance, status].where((e) => e.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'No status provided' : parts.join(' • ');
  }
}
