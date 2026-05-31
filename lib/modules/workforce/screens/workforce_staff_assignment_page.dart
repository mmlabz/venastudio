import 'package:venastudio/common.dart';

class WorkforceStaffAssignmentPage extends ConsumerStatefulWidget {
  const WorkforceStaffAssignmentPage({super.key});

  @override
  ConsumerState<WorkforceStaffAssignmentPage> createState() =>
      _WorkforceStaffAssignmentPageState();
}

class _WorkforceStaffAssignmentPageState extends ConsumerState<WorkforceStaffAssignmentPage> {
  final api = WorkforceApi();
  bool loading = true;
  Map<String, dynamic> summary = {};
  List<Map<String, dynamic>> teams = [];
  List<Map<String, dynamic>> unassigned = [];
  List<Map<String, dynamic>> shifts = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final a = await api.post('/workforce/assignments.php', ref, {});
      final u = await api.get('/workforce/unassigned_staff.php', ref);
      final sh = await api.shifts(ref);

      summary = a['summary'] is Map ? Map<String, dynamic>.from(a['summary']) : {};
      final rawTeams = a['teams'] ?? a['data'] ?? [];
      teams = rawTeams is List
          ? rawTeams.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : [];
      unassigned = u;
      shifts = sh;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> openAssign({Map<String, dynamic>? team}) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AssignStaffDialog(api: api, ref_: ref, preselectedTeam: team, shifts: shifts),
    );
    if (ok == true) load();
  }

  Future<void> openTeam(Map<String, dynamic> team) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TeamDetailsDialog(api: api, ref_: ref, team: team, shifts: shifts),
    );
    if (ok == true) load();
  }

  @override
  Widget build(BuildContext context) {
    final assigned = summary['assigned_staff'] ?? 0;
    final unassignedCount = summary['unassigned_staff'] ?? unassigned.length;
    final teamCount = summary['team_count'] ?? teams.length;
    final shiftCount = summary['shift_count'] ?? shifts.length;

    return WfShell(
      title: 'Staff Assignment',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: WfPrimaryButton(
            label: 'Assign Staff',
            icon: Icons.group_add_rounded,
            onTap: () => openAssign(),
            compact: true,
          ),
        ),
        IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded)),
      ],
      child: loading
          ? const Center(child: CircularProgressIndicator(color: wfTeal))
          : RefreshIndicator(
              color: wfTeal,
              onRefresh: load,
              child: ListView(
                children: [
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.9,
                    children: [
                      _StatTile(label: 'Assigned', value: '$assigned', icon: Icons.assignment_turned_in_rounded, color: wfSuccess),
                      _StatTile(label: 'Unassigned', value: '$unassignedCount', icon: Icons.person_off_rounded, color: wfAmber),
                      _StatTile(label: 'Teams', value: '$teamCount', icon: Icons.groups_rounded, color: wfTeal),
                      _StatTile(label: 'Shifts', value: '$shiftCount', icon: Icons.schedule_rounded, color: wfDark),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Teams', style: TextStyle(color: wfDark, fontWeight: FontWeight.w900, fontSize: 18)),
                      ),
                      WfGhostButton(label: 'Assign', icon: Icons.group_add_rounded, onTap: () => openAssign()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (teams.isEmpty)
                    WfEmpty(
                      icon: Icons.groups_rounded,
                      title: 'No team assignments',
                      message: 'Assign staff into teams to organize operations.',
                      action: WfPrimaryButton(label: 'Assign Staff', icon: Icons.group_add_rounded, onTap: () => openAssign()),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: teams.length,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 540,
                        mainAxisExtent: 205,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (_, index) {
                        final team = teams[index];
                        return _TeamCard(
                          team: team,
                          onTap: () => openTeam(team),
                          onAssign: () => openAssign(team: team),
                        );
                      },
                    ),
                  const SizedBox(height: 18),
                  _UnassignedSection(staff: unassigned.take(10).toList(), total: unassigned.length, onAssign: () => openAssign()),
                ],
              ),
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => WfCard(
        child: Row(
          children: [
            WfIconBox(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900, fontSize: 20)),
                  Text(label, style: const TextStyle(color: wfMuted, fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team, required this.onTap, required this.onAssign});
  final Map<String, dynamic> team;
  final VoidCallback onTap, onAssign;

  @override
  Widget build(BuildContext context) {
    final staffCount = int.tryParse('${team['staff_count'] ?? 0}') ?? 0;
    final members = '${team['staff_preview'] ?? ''}';

    return WfCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WfIconBox(
                icon: '${team['team_type'] ?? 'day'}' == 'night' ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                color: wfTeal,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${team['name'] ?? 'Team'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900, fontSize: 17)),
                  Text('${team['shift_name'] ?? 'No shift linked'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: wfMuted, fontWeight: FontWeight.w800, fontSize: 12)),
                ]),
              ),
              WfChip(label: '$staffCount staff', color: wfSuccess),
            ],
          ),
          const SizedBox(height: 14),
          Text(members.isEmpty ? 'No staff assigned yet' : members, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: wfDark, fontWeight: FontWeight.w700)),
          const Spacer(),
          Row(
            children: [
              WfGhostButton(label: 'View Team', icon: Icons.visibility_rounded, onTap: onTap),
              const SizedBox(width: 8),
              WfPrimaryButton(label: 'Assign', icon: Icons.group_add_rounded, onTap: onAssign, compact: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnassignedSection extends StatelessWidget {
  const _UnassignedSection({required this.staff, required this.total, required this.onAssign});
  final List<Map<String, dynamic>> staff;
  final int total;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) => WfCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const WfIconBox(icon: Icons.person_off_rounded, color: wfAmber),
              const SizedBox(width: 12),
              const Expanded(child: Text('Unassigned Staff', style: TextStyle(color: wfDark, fontWeight: FontWeight.w900, fontSize: 17))),
              WfChip(label: '$total staff', color: wfAmber),
              const SizedBox(width: 10),
              WfPrimaryButton(label: 'Assign', icon: Icons.group_add_rounded, onTap: onAssign, compact: true),
            ]),
            const SizedBox(height: 12),
            if (staff.isEmpty)
              const Text('Everyone is currently assigned.', style: TextStyle(color: wfMuted, fontWeight: FontWeight.w800))
            else
              Wrap(spacing: 8, runSpacing: 8, children: staff.map((s) => WfChip(label: '${s['name'] ?? 'Staff'}', color: wfTeal)).toList()),
          ],
        ),
      );
}

class _AssignStaffDialog extends StatefulWidget {
  const _AssignStaffDialog({required this.api, required this.ref_, required this.shifts, this.preselectedTeam});
  final WorkforceApi api;
  final WidgetRef ref_;
  final List<Map<String, dynamic>> shifts;
  final Map<String, dynamic>? preselectedTeam;

  @override
  State<_AssignStaffDialog> createState() => _AssignStaffDialogState();
}

class _AssignStaffDialogState extends State<_AssignStaffDialog> {
  bool loading = true, saving = false;
  List<Map<String, dynamic>> staff = [], teams = [];
  final selectedStaff = <String>{};
  final search = TextEditingController();
  String teamId = '', shiftId = '';
  DateTime startDate = DateTime.now();
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    teamId = '${widget.preselectedTeam?['id'] ?? ''}';
    shiftId = '${widget.preselectedTeam?['shift_id'] ?? ''}';
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final r = await Future.wait([
        widget.api.get('/workforce/unassigned_staff.php', widget.ref_),
        widget.api.teams(widget.ref_),
      ]);
      staff = r[0];
      teams = r[1];
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, dynamic>> get visibleStaff {
    final q = search.text.trim().toLowerCase();
    return staff.where((s) {
      final name = '${s['name'] ?? ''}'.toLowerCase();
      final no = '${s['employee_no'] ?? ''}'.toLowerCase();
      return q.isEmpty || name.contains(q) || no.contains(q);
    }).toList();
  }

  Future<void> pickStart() async {
    final d = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (d != null) setState(() => startDate = d);
  }

  Future<void> pickEnd() async {
    final d = await showDatePicker(context: context, initialDate: endDate ?? startDate, firstDate: startDate, lastDate: DateTime(2035));
    if (d != null) setState(() => endDate = d);
  }

  Future<void> save() async {
    if (teamId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select team')));
      return;
    }
    if (selectedStaff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select staff')));
      return;
    }
    setState(() => saving = true);
    try {
      await widget.api.post('/workforce/bulk_assign_staff.php', widget.ref_, {
        'employee_ids': selectedStaff.join(','),
        'team_id': teamId,
        'shift_id': shiftId,
        'start_date': wfDate(startDate),
        'end_date': endDate == null ? '' : wfDate(endDate!),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final visible = visibleStaff;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      title: const Text('Assign Staff to Team', style: TextStyle(color: wfDark, fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: 920,
        height: 640,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: wfTeal))
            : Row(
                children: [
                  Expanded(
                    child: _Panel(
                      title: 'Staff',
                      footer: '${selectedStaff.length} selected',
                      child: Column(children: [
                        TextField(
                          controller: search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Search staff',
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          TextButton(onPressed: () => setState(() => visible.forEach((s) => selectedStaff.add('${s['id']}'))), child: const Text('Select visible')),
                          TextButton(onPressed: () => setState(selectedStaff.clear), child: const Text('Clear')),
                        ]),
                        Expanded(
                          child: ListView.builder(
                            itemCount: visible.length,
                            itemBuilder: (_, i) {
                              final s = visible[i];
                              final id = '${s['id']}';
                              return CheckboxListTile(
                                value: selectedStaff.contains(id),
                                dense: true,
                                activeColor: wfTeal,
                                onChanged: (v) => setState(() => v == true ? selectedStaff.add(id) : selectedStaff.remove(id)),
                                title: Text('${s['name'] ?? 'Staff'}'),
                                subtitle: '${s['primary_category_name'] ?? ''}'.isEmpty ? null : Text('Primary: ${s['primary_category_name']}'),
                              );
                            },
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 330,
                    child: _Panel(
                      title: 'Assignment',
                      child: Column(children: [
                        DropdownButtonFormField<String>(
                          value: teamId.isEmpty ? null : teamId,
                          decoration: InputDecoration(labelText: 'Team', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                          items: teams.map((t) => DropdownMenuItem(value: '${t['id']}', child: Text('${t['name'] ?? 'Team'}'))).toList(),
                          onChanged: (v) => setState(() => teamId = v ?? ''),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: shiftId.isEmpty ? null : shiftId,
                          decoration: InputDecoration(labelText: 'Shift Template', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                          items: widget.shifts.map((s) => DropdownMenuItem(value: '${s['id']}', child: Text('${s['name'] ?? 'Shift'}'))).toList(),
                          onChanged: (v) => setState(() => shiftId = v ?? ''),
                        ),
                        const SizedBox(height: 12),
                        WfGhostButton(label: 'Start: ${wfShortDate(wfDate(startDate))}', icon: Icons.calendar_month_rounded, onTap: pickStart),
                        const SizedBox(height: 8),
                        WfGhostButton(label: endDate == null ? 'No End Date' : 'End: ${wfShortDate(wfDate(endDate!))}', icon: Icons.event_rounded, onTap: pickEnd),
                        if (endDate != null) TextButton(onPressed: () => setState(() => endDate = null), child: const Text('Clear End Date')),
                        const Spacer(),
                        WfPrimaryButton(label: saving ? 'Assigning...' : 'Assign ${selectedStaff.length} Staff', icon: Icons.group_add_rounded, onTap: saving ? () {} : save),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
      actions: [TextButton(onPressed: saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel'))],
    );
  }
}

class _TeamDetailsDialog extends StatefulWidget {
  const _TeamDetailsDialog({required this.api, required this.ref_, required this.team, required this.shifts});
  final WorkforceApi api;
  final WidgetRef ref_;
  final Map<String, dynamic> team;
  final List<Map<String, dynamic>> shifts;

  @override
  State<_TeamDetailsDialog> createState() => _TeamDetailsDialogState();
}

class _TeamDetailsDialogState extends State<_TeamDetailsDialog> {
  bool loading = true, removing = false;
  List<Map<String, dynamic>> members = [];
  final selected = <String>{};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final res = await widget.api.post('/workforce/team_assignments.php', widget.ref_, {'team_id': '${widget.team['id']}'});
      final raw = res['members'] ?? res['data'] ?? [];
      members = raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> removeSelected() async {
    if (selected.isEmpty) return;
    setState(() => removing = true);
    try {
      await widget.api.post('/workforce/remove_team_assignment.php', widget.ref_, {'assignment_ids': selected.join(',')});
      selected.clear();
      await load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => removing = false);
  }

  Future<void> openAssign() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AssignStaffDialog(api: widget.api, ref_: widget.ref_, shifts: widget.shifts, preselectedTeam: widget.team),
    );
    if (ok == true) load();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text('${widget.team['name'] ?? 'Team'}', style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 780,
          height: 620,
          child: loading
              ? const Center(child: CircularProgressIndicator(color: wfTeal))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  WfCard(
                    child: Row(children: [
                      const WfIconBox(icon: Icons.groups_rounded, color: wfTeal),
                      const SizedBox(width: 12),
                      Expanded(child: Text('${members.length} staff assigned • ${widget.team['shift_name'] ?? 'No shift'}', style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900))),
                      WfPrimaryButton(label: 'Assign More', icon: Icons.group_add_rounded, onTap: openAssign, compact: true),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: members.isEmpty
                        ? const Center(child: Text('No staff assigned to this team yet.', style: TextStyle(color: wfMuted, fontWeight: FontWeight.w800)))
                        : ListView.separated(
                            itemCount: members.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, index) {
                              final m = members[index];
                              final id = '${m['assignment_id'] ?? m['id']}';
                              return WfCard(
                                child: Row(children: [
                                  Checkbox(value: selected.contains(id), activeColor: wfTeal, onChanged: (v) => setState(() => v == true ? selected.add(id) : selected.remove(id))),
                                  const WfIconBox(icon: Icons.person_rounded, color: wfTeal),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('${m['staff_name'] ?? 'Staff'}', style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900)),
                                    Text('${m['shift_name'] ?? 'No shift'} • From ${m['start_date'] ?? '-'}', style: const TextStyle(color: wfMuted, fontWeight: FontWeight.w700, fontSize: 12)),
                                  ])),
                                  const WfChip(label: 'Active', color: wfSuccess),
                                ]),
                              );
                            },
                          ),
                  ),
                ]),
        ),
        actions: [
          if (selected.isNotEmpty) TextButton.icon(onPressed: removing ? null : removeSelected, icon: const Icon(Icons.remove_circle_outline_rounded), label: Text(removing ? 'Removing...' : 'Remove Selected')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Close')),
        ],
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.footer});
  final String title;
  final Widget child;
  final String? footer;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xffF7FBFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: wfLine)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900))),
            if (footer != null) Text(footer!, style: const TextStyle(color: wfMuted, fontSize: 12, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 10),
          Expanded(child: child),
        ]),
      );
}
