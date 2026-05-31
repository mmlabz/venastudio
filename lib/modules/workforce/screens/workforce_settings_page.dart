import 'package:venastudio/common.dart';

class WorkforceSettingsPage extends ConsumerStatefulWidget {
  const WorkforceSettingsPage({super.key});
  @override
  ConsumerState<WorkforceSettingsPage> createState() => _WorkforceSettingsPageState();
}

class _WorkforceSettingsPageState extends ConsumerState<WorkforceSettingsPage> {
  final api = WorkforceApi();
  bool loading = true;
  bool saving = false;
  Map<String, dynamic> s = {};

  @override
  void initState() { super.initState(); load(); }

  bool yes(String key) => '${s[key] ?? '0'}' == '1' || s[key] == true;
  void setVal(String key, bool value) { setState(() => s[key] = value ? '1' : '0'); save(); }

  Future<void> load() async {
    setState(() => loading = true);
    try { final res = await api.settings(ref); s = Map<String, dynamic>.from(res['settings'] ?? {}); } catch (e) { Fluttertoast.showToast(msg: '$e'); }
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final res = await api.post('/workforce/save_settings.php', ref, s);
      s = Map<String, dynamic>.from(res['settings'] ?? s);
      Fluttertoast.showToast(msg: 'Settings saved');
    } catch (e) { Fluttertoast.showToast(msg: '$e'); }
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return WfShell(
      title: 'Workforce Settings',
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded))],
      child: loading ? const Center(child: CircularProgressIndicator(color: wfTeal)) : ListView(
        children: [
          WfGradientCard(child: Row(children: [
            Container(height: 52, width: 52, decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white)),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Superadmin Control', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              SizedBox(height: 4),
              Text('Switch modules on/off and control workforce enforcement.', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
            ])),
          ])),
          const SizedBox(height: 16),
          _Switch(title: 'Attendance Module', subtitle: 'Enable VenaPro check-in/out and attendance tracking.', value: yes('attendance_enabled'), onChanged: (v)=>setVal('attendance_enabled', v)),
          _Switch(title: 'Attendance Rules', subtitle: 'Apply lateness, early checkout and absence penalties.', value: yes('attendance_rules_enabled'), onChanged: (v)=>setVal('attendance_rules_enabled', v)),
          _Switch(title: 'Track Stock Before Assignment', subtitle: 'Require issuing products before assigning services.', value: yes('track_stock_enabled'), onChanged: (v)=>setVal('track_stock_enabled', v)),
          _Switch(title: 'Require Shift Before Online', subtitle: 'Block VenaPro online status without a valid shift.', value: yes('require_shift_before_online'), onChanged: (v)=>setVal('require_shift_before_online', v)),
          _Switch(title: 'Require Products Before Assignment', subtitle: 'Block assignment until required products are issued.', value: yes('require_products_before_assignment'), onChanged: (v)=>setVal('require_products_before_assignment', v)),
          _Switch(title: 'Strict Attendance Enforcement', subtitle: 'Block staff with no team/shift assignment.', value: yes('strict_attendance_enforcement'), onChanged: (v)=>setVal('strict_attendance_enforcement', v)),
          _Switch(title: 'Smart Staff Recommendations', subtitle: 'Allow queue engine to recommend the best available staff.', value: yes('auto_recommend_staff'), onChanged: (v)=>setVal('auto_recommend_staff', v)),
          if (saving) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(color: wfTeal))),
        ],
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.title, required this.subtitle, required this.value, required this.onChanged});
  final String title; final String subtitle; final bool value; final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return WfCard(margin: const EdgeInsets.only(bottom: 10), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: wfMuted, fontSize: 12, fontWeight: FontWeight.w700)),
      ])),
      Switch(value: value, onChanged: onChanged, activeColor: wfTeal),
    ]));
  }
}
