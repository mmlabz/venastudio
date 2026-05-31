import 'package:venastudio/common.dart';

class WorkforcePage extends ConsumerStatefulWidget {
  const WorkforcePage({super.key});

  @override
  ConsumerState<WorkforcePage> createState() => _WorkforcePageState();
}

class _WorkforcePageState extends ConsumerState<WorkforcePage> {
  final api = WorkforceApi();
  bool loading = true;
  Map<String, dynamic> data = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      data = await api.dashboard(ref);
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return WfShell(
      title: 'Workforce',
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded))],
      child: loading
          ? const Center(child: CircularProgressIndicator(color: wfTeal))
          : RefreshIndicator(
              color: wfTeal,
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                children: [
                  WfGradientCard(
                    child: Row(
                      children: [
                        Container(
                          height: 58,
                          width: 58,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(.17), borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.groups_3_rounded, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Operational Workforce Engine', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                              SizedBox(height: 4),
                              Text('Attendance, queues, shifts, stock readiness and smart assignment.', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                    childAspectRatio: 1.45,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _Metric('Attendance', '${data['attendance_total'] ?? 0}', Icons.fact_check_rounded, wfSuccess),
                      _Metric('In Queue', '${data['queue_total'] ?? 0}', Icons.alt_route_rounded, wfTeal),
                      _Metric('Pending Requests', '${data['pending_requests'] ?? 0}', Icons.event_available_rounded, wfAmber),
                      _Metric('Date', '${data['date'] ?? ''}', Icons.calendar_month_rounded, wfDark),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Control Center', style: TextStyle(color: wfDark, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: MediaQuery.of(context).size.width > 700 ? 260 : 500,
                      mainAxisExtent: 106,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _tools.length,
                    itemBuilder: (_, i) {
                      final t = _tools[i];
                      return WfCard(
                        onTap: () => context.go(t.path),
                        child: Row(
                          children: [
                            WfIconBox(icon: t.icon, color: t.color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 4),
                                  Text(t.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: wfMuted, fontSize: 12, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: wfMuted),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.title, this.value, this.icon, this.color);
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return WfCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        WfIconBox(icon: icon, color: color),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: wfDark, fontSize: 22, fontWeight: FontWeight.w900)),
          Text(title, style: const TextStyle(color: wfMuted, fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
  }
}

class _Tool {
  const _Tool(this.title, this.subtitle, this.icon, this.path, this.color);
  final String title;
  final String subtitle;
  final IconData icon;
  final String path;
  final Color color;
}

const _tools = [
  _Tool('Settings', 'Module rules and enforcement', Icons.tune_rounded, '/workforce/settings', wfTeal),
  _Tool('Teams', 'Day/Night teams', Icons.groups_rounded, '/workforce/teams', wfSuccess),
  _Tool('Shifts', 'Templates and rotations', Icons.schedule_rounded, '/workforce/shifts', wfAmber),
  _Tool('Assign Staff', 'Attach staff to teams and shifts', Icons.assignment_ind_rounded, '/workforce/assignments', wfTeal),
  _Tool('Attendance', 'Check-in and check-out report', Icons.fact_check_rounded, '/workforce/attendance', wfSuccess),
  _Tool('Queue', 'Live assignment queue', Icons.alt_route_rounded, '/workforce/queue', wfTeal),
  _Tool('Off & Leave', 'Requests and approvals', Icons.event_available_rounded, '/workforce/time_requests', wfAmber),
  _Tool('Skills', 'Service specialities', Icons.workspace_premium_rounded, '/workforce/skills', wfSuccess),
  _Tool('Stations', 'Beds, chairs and booths', Icons.chair_rounded, '/workforce/stations', wfTeal),
  _Tool('Recipes', 'Service product requirements', Icons.inventory_2_rounded, '/workforce/recipes', wfAmber),
  _Tool('Pending Returns', 'Confirm returned tools and products', Icons.assignment_return_rounded, '/workforce/pending_returns', wfSuccess),
  _Tool('WiFi IPs', 'Allowed shop network IPs', Icons.wifi_rounded, '/workforce/allowed_ips', wfDanger),
];
