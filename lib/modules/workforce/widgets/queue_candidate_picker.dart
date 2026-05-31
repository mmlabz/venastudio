import 'package:flutter/material.dart';

/// Drop-in picker for Vena Studio assignment screens.
///
/// Expected backend:
/// POST /workforce/queue_candidates.php
/// body: company_id, store_id/store, service_id
///
/// This widget intentionally does not depend on your existing service classes.
/// Pass a loader function from your current API client.
///
/// Example:
/// final picked = await showQueueCandidatePicker(
///   context: context,
///   companyId: companyId,
///   storeId: storeName,
///   serviceId: serviceId,
///   loadCandidates: (body) => api.post('/workforce/queue_candidates.php', body),
/// );
///
/// It only shows candidates returned by the backend:
/// checked_in + available + waiting + skilled for service.
class QueueCandidatePicker extends StatefulWidget {
  const QueueCandidatePicker({
    super.key,
    required this.companyId,
    required this.storeId,
    required this.serviceId,
    required this.loadCandidates,
  });

  final int companyId;
  final String storeId;
  final int serviceId;
  final Future<List<Map<String, dynamic>>> Function(Map<String, dynamic> body) loadCandidates;

  @override
  State<QueueCandidatePicker> createState() => _QueueCandidatePickerState();
}

class _QueueCandidatePickerState extends State<QueueCandidatePicker> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadCandidates({
      'company_id': widget.companyId,
      'store_id': widget.storeId,
      'store': widget.storeId,
      'service_id': widget.serviceId,
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.loadCandidates({
        'company_id': widget.companyId,
        'store_id': widget.storeId,
        'store': widget.storeId,
        'service_id': widget.serviceId,
      });
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 620),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Assign from Available Queue',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
              ],
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Busy beauticians are hidden. Only checked-in, available, skilled staff are shown.',
                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snap) {
                  final rows = snap.data ?? const <Map<String, dynamic>>[];

                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snap.hasError) {
                    return _Empty(text: '${snap.error}');
                  }

                  if (rows.isEmpty) {
                    return const _Empty(text: 'No available skilled beautician in queue.');
                  }

                  return ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final row = rows[i];
                      final name = '${row['employee_name'] ?? row['name'] ?? 'Beautician'}';
                      final pos = '${row['queue_position'] ?? i + 1}';
                      final employeeId = int.tryParse('${row['employee_id'] ?? row['id'] ?? 0}') ?? 0;

                      return Material(
                        color: const Color(0xFFF8FBFC),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: employeeId <= 0 ? null : () => Navigator.pop(context, row),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(child: Text(pos)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'AVAILABLE • CHECKED IN',
                                      style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w800),
                                    ),
                                  ]),
                                ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
      ),
    );
  }
}

Future<Map<String, dynamic>?> showQueueCandidatePicker({
  required BuildContext context,
  required int companyId,
  required String storeId,
  required int serviceId,
  required Future<List<Map<String, dynamic>>> Function(Map<String, dynamic> body) loadCandidates,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => QueueCandidatePicker(
      companyId: companyId,
      storeId: storeId,
      serviceId: serviceId,
      loadCandidates: loadCandidates,
    ),
  );
}
