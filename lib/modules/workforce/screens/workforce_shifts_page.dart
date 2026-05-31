import 'dart:convert';
import 'package:venastudio/common.dart';

class WorkforceShiftsPage extends ConsumerStatefulWidget {
  const WorkforceShiftsPage({super.key});

  @override
  ConsumerState<WorkforceShiftsPage> createState() =>
      _WorkforceShiftsPageState();
}

class _WorkforceShiftsPageState extends ConsumerState<WorkforceShiftsPage> {
  final api = WorkforceApi();

  bool loading = true;
  List<Map<String, dynamic>> shifts = [];
  List<Map<String, dynamic>> teams = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      final result = await Future.wait([
        api.shifts(ref),
        api.teams(ref),
      ]);

      shifts = result[0];
      teams = result[1];
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> open([Map<String, dynamic>? shift]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ShiftDialog(
        api: api,
        ref_: ref,
        teams: teams,
        shift: shift,
      ),
    );

    if (saved == true) load();
  }

  @override
  Widget build(BuildContext context) {
    return WfShell(
      title: 'Shift Templates',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: WfPrimaryButton(
            label: 'Add Shift',
            icon: Icons.add_rounded,
            onTap: () => open(),
            compact: true,
          ),
        ),
      ],
      child: loading
          ? const Center(child: CircularProgressIndicator(color: wfTeal))
          : shifts.isEmpty
              ? WfEmpty(
                  icon: Icons.schedule_rounded,
                  title: 'No shift templates',
                  message:
                      'Create day/night templates with different times per day and rotating offs.',
                  action: WfPrimaryButton(
                    label: 'Create Shift',
                    icon: Icons.add_rounded,
                    onTap: () => open(),
                  ),
                )
              : RefreshIndicator(
                  color: wfTeal,
                  onRefresh: load,
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 460,
                      mainAxisExtent: 156,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: shifts.length,
                    itemBuilder: (_, index) {
                      final shift = shifts[index];
                      final days = shift['days'] is List
                          ? List<Map<String, dynamic>>.from(
                              (shift['days'] as List).whereType<Map>().map(
                                    (e) => Map<String, dynamic>.from(e),
                                  ),
                            )
                          : <Map<String, dynamic>>[];

                      final workingDays = days
                          .where((e) => '${e['is_working_day'] ?? 1}' == '1')
                          .length;

                      final shiftType = '${shift['shift_type'] ?? 'day'}';
                      final rotationType = '${shift['rotation_type'] ?? 'fixed'}';
                      final active = '${shift['is_active'] ?? 1}' == '1';

                      return WfCard(
                        onTap: () => open(shift),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                WfIconBox(
                                  icon: shiftType == 'night'
                                      ? Icons.nights_stay_rounded
                                      : Icons.schedule_rounded,
                                  color: shiftType == 'night' ? wfAmber : wfTeal,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${shift['name'] ?? 'Shift'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: wfDark,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${shift['team_name'] ?? 'No linked team'}',
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
                                const Icon(Icons.edit_rounded, color: wfMuted),
                              ],
                            ),
                            const Spacer(),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                WfChip(label: shiftType, color: wfTeal),
                                WfChip(label: rotationType, color: wfAmber),
                                WfChip(label: '$workingDays days', color: wfSuccess),
                                WfChip(
                                  label: active ? 'Active' : 'Inactive',
                                  color: active ? wfSuccess : wfMuted,
                                ),
                              ],
                            ),
                            if ('${shift['week_a_off_day'] ?? ''}'.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Rotation off: ${shift['week_a_off_day']} / ${shift['week_b_off_day']}',
                                  style: const TextStyle(
                                    color: wfMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _DayCfg {
  _DayCfg(this.day);

  final String day;
  bool working = true;

  final start = TextEditingController(text: '09:00');
  final end = TextEditingController(text: '19:00');
  final grace = TextEditingController(text: '15');
  final earlyGrace = TextEditingController(text: '10');
  final latePenalty = TextEditingController(text: '0');
  final earlyPenalty = TextEditingController(text: '0');
  final absencePenalty = TextEditingController(text: '0');

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': day.toLowerCase(),
      'is_working_day': working ? '1' : '0',
      'start_time': start.text.trim(),
      'end_time': end.text.trim(),
      'grace_minutes': grace.text.trim(),
      'early_leave_grace_minutes': earlyGrace.text.trim(),
      'late_penalty_amount': latePenalty.text.trim(),
      'early_leave_penalty_amount': earlyPenalty.text.trim(),
      'absence_penalty_amount': absencePenalty.text.trim(),
    };
  }

  void dispose() {
    start.dispose();
    end.dispose();
    grace.dispose();
    earlyGrace.dispose();
    latePenalty.dispose();
    earlyPenalty.dispose();
    absencePenalty.dispose();
  }
}

class _ShiftDialog extends StatefulWidget {
  const _ShiftDialog({
    required this.api,
    required this.ref_,
    required this.teams,
    this.shift,
  });

  final WorkforceApi api;
  final WidgetRef ref_;
  final List<Map<String, dynamic>> teams;
  final Map<String, dynamic>? shift;

  @override
  State<_ShiftDialog> createState() => _ShiftDialogState();
}

class _ShiftDialogState extends State<_ShiftDialog> {
  final name = TextEditingController();

  String shiftType = 'day';
  String rotationType = 'fixed';
  String weekA = 'sunday';
  String weekB = 'monday';
  String teamId = '';

  DateTime rotationStart = DateTime.now();
  bool active = true;
  bool saving = false;

  late List<_DayCfg> days;

  @override
  void initState() {
    super.initState();

    days = const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ].map(_DayCfg.new).toList();

    final shift = widget.shift;
    if (shift == null) return;

    name.text = '${shift['name'] ?? ''}';
    shiftType = '${shift['shift_type'] ?? 'day'}';
    rotationType = '${shift['rotation_type'] ?? 'fixed'}';
    weekA = '${shift['week_a_off_day'] ?? 'sunday'}';
    weekB = '${shift['week_b_off_day'] ?? 'monday'}';
    teamId = '${shift['team_id'] ?? ''}';
    active = '${shift['is_active'] ?? 1}' == '1';
    rotationStart =
        DateTime.tryParse('${shift['rotation_start_date'] ?? ''}') ??
            DateTime.now();

    if (shift['days'] is! List) return;

    for (final raw in shift['days'] as List) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final key = '${item['day_of_week'] ?? ''}'.toLowerCase();

      for (final day in days) {
        if (day.day.toLowerCase() != key) continue;

        day.working = '${item['is_working_day'] ?? 1}' == '1';
        day.start.text = _time5('${item['start_time'] ?? '09:00'}');
        day.end.text = _time5('${item['end_time'] ?? '19:00'}');
        day.grace.text = '${item['grace_minutes'] ?? 15}';
        day.earlyGrace.text = '${item['early_leave_grace_minutes'] ?? 10}';
        day.latePenalty.text = '${item['late_penalty_amount'] ?? 0}';
        day.earlyPenalty.text = '${item['early_leave_penalty_amount'] ?? 0}';
        day.absencePenalty.text = '${item['absence_penalty_amount'] ?? 0}';
      }
    }
  }

  String _time5(String value) {
    if (value.length >= 5) return value.substring(0, 5);
    return value;
  }

  @override
  void dispose() {
    name.dispose();
    for (final day in days) {
      day.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Shift name required');
      return;
    }

    setState(() => saving = true);

    try {
      await widget.api.post(
        '/workforce/save_shift.php',
        widget.ref_,
        {
          'id': widget.shift == null ? '' : '${widget.shift!['id'] ?? ''}',
          'name': name.text.trim(),
          'team_id': teamId,
          'shift_type': shiftType,
          'rotation_type': rotationType,
          'week_a_off_day': rotationType == 'weekly_alternating' ? weekA : '',
          'week_b_off_day': rotationType == 'weekly_alternating' ? weekB : '',
          'rotation_start_date': wfDate(rotationStart),
          'is_active': active ? '1' : '0',
          'days_json': jsonEncode(days.map((e) => e.toJson()).toList()),
        },
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    }

    if (mounted) setState(() => saving = false);
  }

  Future<void> pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: rotationStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) setState(() => rotationStart = picked);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 1100 ? 980.0 : width * .94;
    final dialogHeight = MediaQuery.of(context).size.height * .86;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [wfTeal, Color(0xff0498AA)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.16),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.schedule_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.shift == null
                              ? 'Create Shift Template'
                              : 'Edit Shift Template',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Compact weekly schedule, penalties and rotating off-days.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topForm(),
                    const SizedBox(height: 14),
                    if (rotationType == 'weekly_alternating') _rotationForm(),
                    if (rotationType == 'weekly_alternating')
                      const SizedBox(height: 14),
                    _daysTable(),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: active,
                      activeColor: wfTeal,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) => setState(() => active = value),
                      title: const Text(
                        'Active template',
                        style: TextStyle(
                          color: wfDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: wfLine.withOpacity(.8))),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      saving
                          ? 'Saving shift template...'
                          : 'Tip: use 19:00 → 05:00 for overnight shifts.',
                      style: const TextStyle(
                        color: wfMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: saving ? null : save,
                    icon: saving
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(saving ? 'Saving...' : 'Save Shift'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topForm() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 310,
          child: WfTextField(
            controller: name,
            label: 'Template Name',
            hint: 'Day Shift - Sunday/Monday Rotation',
          ),
        ),
        SizedBox(
          width: 150,
          child: _dropdown(
            label: 'Shift Type',
            value: shiftType,
            items: const {
              'day': 'Day',
              'night': 'Night',
              'custom': 'Custom',
            },
            onChanged: (value) => setState(() => shiftType = value),
          ),
        ),
        SizedBox(
          width: 210,
          child: _dropdown(
            label: 'Rotation',
            value: rotationType,
            items: const {
              'fixed': 'Fixed',
              'weekly_alternating': 'Weekly Alternating',
            },
            onChanged: (value) => setState(() => rotationType = value),
          ),
        ),
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<String>(
            value: teamId.isEmpty ? null : teamId,
            decoration: InputDecoration(
              labelText: 'Linked Team',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              isDense: true,
            ),
            items: widget.teams
                .map(
                  (team) => DropdownMenuItem<String>(
                    value: '${team['id']}',
                    child: Text('${team['name'] ?? 'Team'}'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => teamId = value ?? ''),
          ),
        ),
      ],
    );
  }

  Widget _rotationForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: wfTeal.withOpacity(.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: wfTeal.withOpacity(.14)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 180,
            child: _dayDrop(
              label: 'Week A Off',
              value: weekA,
              onChanged: (value) => setState(() => weekA = value),
            ),
          ),
          SizedBox(
            width: 180,
            child: _dayDrop(
              label: 'Week B Off',
              value: weekB,
              onChanged: (value) => setState(() => weekB = value),
            ),
          ),
          WfGhostButton(
            label: 'Start: ${wfShortDate(wfDate(rotationStart))}',
            icon: Icons.calendar_month_rounded,
            onTap: pickStart,
          ),
        ],
      ),
    );
  }

  Widget _daysTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: wfLine),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: wfDark.withOpacity(.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 92, child: _TableHead('Day')),
                SizedBox(width: 62, child: _TableHead('Work')),
                SizedBox(width: 84, child: _TableHead('Start')),
                SizedBox(width: 84, child: _TableHead('End')),
                SizedBox(width: 82, child: _TableHead('Grace')),
                SizedBox(width: 102, child: _TableHead('Early Grace')),
                SizedBox(width: 108, child: _TableHead('Late Pen.')),
                SizedBox(width: 108, child: _TableHead('Early Pen.')),
                Expanded(child: _TableHead('Absent Pen.')),
              ],
            ),
          ),
          for (int i = 0; i < days.length; i++)
            _DayRow(
              day: days[i],
              shaded: i.isOdd,
              onChanged: () => setState(() {}),
            ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        isDense: true,
      ),
      items: items.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
      onChanged: (next) => onChanged(next ?? value),
    );
  }

  Widget _dayDrop({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    const items = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        isDense: true,
      ),
      items: items
          .map(
            (day) => DropdownMenuItem(
              value: day,
              child: Text(day),
            ),
          )
          .toList(),
      onChanged: (next) => onChanged(next ?? value),
    );
  }
}

class _TableHead extends StatelessWidget {
  const _TableHead(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: wfDark,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.shaded,
    required this.onChanged,
  });

  final _DayCfg day;
  final bool shaded;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: shaded ? wfDark.withOpacity(.018) : Colors.white,
        border: Border(top: BorderSide(color: wfLine.withOpacity(.55))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              day.day.substring(0, 3),
              style: const TextStyle(
                color: wfDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(
            width: 62,
            child: Switch(
              value: day.working,
              activeColor: wfTeal,
              onChanged: (value) {
                day.working = value;
                onChanged();
              },
            ),
          ),
          _mini(day.start, enabled: day.working),
          _mini(day.end, enabled: day.working),
          _mini(day.grace, enabled: day.working),
          SizedBox(width: 102, child: _field(day.earlyGrace, day.working)),
          SizedBox(width: 108, child: _field(day.latePenalty, day.working)),
          SizedBox(width: 108, child: _field(day.earlyPenalty, day.working)),
          Expanded(child: _field(day.absencePenalty, day.working)),
        ],
      ),
    );
  }

  Widget _mini(TextEditingController controller, {required bool enabled}) {
    return SizedBox(width: 84, child: _field(controller, enabled));
  }

  Widget _field(TextEditingController controller, bool enabled) {
    return TextField(
      enabled: enabled,
      controller: controller,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: enabled ? Colors.white : wfMuted.withOpacity(.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
