import 'package:venastudio/common.dart';

class WorkforceAttendancePage extends ConsumerStatefulWidget {
  const WorkforceAttendancePage({super.key});
  @override
  ConsumerState<WorkforceAttendancePage> createState() =>
      _WorkforceAttendancePageState();
}

class _WorkforceAttendancePageState
    extends ConsumerState<WorkforceAttendancePage> {
  final api = WorkforceApi();
  bool loading = true;
  List<Map<String, dynamic>> rows = [];
  DateTime date = DateTime.now();
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      rows = await api.attendance(ref, start: wfDate(date), end: wfDate(date));
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> pick() async {
    final d = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035));
    if (d != null) {
      setState(() => date = d);
      load();
    }
  }

  @override
  Widget build(BuildContext context) => WfShell(
      title: 'Attendance',
      actions: [
        IconButton(
            onPressed: pick, icon: const Icon(Icons.calendar_month_rounded)),
        IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded))
      ],
      child: loading
          ? const Center(child: CircularProgressIndicator(color: wfTeal))
          : rows.isEmpty
              ? WfEmpty(
                  icon: Icons.fact_check_rounded,
                  title: 'No attendance',
                  message:
                      'No check-ins found for ${wfShortDate(wfDate(date))}.')
              : RefreshIndicator(
                  color: wfTeal,
                  onRefresh: load,
                  child: ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final r = rows[i];
                        return WfCard(
                            child: Row(children: [
                          const WfIconBox(
                              icon: Icons.person_pin_circle_rounded,
                              color: wfSuccess),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('${r['staff_name'] ?? 'Staff'}',
                                    style: const TextStyle(
                                        color: wfDark,
                                        fontWeight: FontWeight.w900)),
                                Text(
                                    '${r['attendance_date'] ?? ''} • ${r['attendance_status'] ?? ''} • ${r['availability_status'] ?? ''}',
                                    style: const TextStyle(
                                        color: wfMuted,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                                Text(
                                    'In: ${r['check_in'] ?? '-'}   Out: ${r['check_out'] ?? '-'}',
                                    style: const TextStyle(
                                        color: wfMuted, fontSize: 12))
                              ])),
                        ]));
                      })));
}
