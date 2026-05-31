import 'package:venastudio/common.dart';

class WorkforceAllowedIpsPage extends ConsumerStatefulWidget {
  const WorkforceAllowedIpsPage({super.key});
  @override
  ConsumerState<WorkforceAllowedIpsPage> createState() =>
      _WorkforceAllowedIpsPageState();
}

class _WorkforceAllowedIpsPageState
    extends ConsumerState<WorkforceAllowedIpsPage> {
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
      rows = await api.allowedIps(ref);
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> open([Map<String, dynamic>? item]) async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => _IpDialog(api: api, ref_: ref, item: item));
    if (ok == true) load();
  }

  @override
  Widget build(BuildContext context) => WfShell(
      title: 'Allowed WiFi IPs',
      actions: [
        Padding(
            padding: const EdgeInsets.only(right: 12),
            child: WfPrimaryButton(
                label: 'Add IP',
                icon: Icons.add_rounded,
                onTap: () => open(),
                compact: true))
      ],
      child: loading
          ? const Center(child: CircularProgressIndicator(color: wfTeal))
          : rows.isEmpty
              ? WfEmpty(
                  icon: Icons.wifi_rounded,
                  title: 'No allowed IPs',
                  message:
                      'Add shop WiFi public IP addresses to enforce check-in/out.',
                  action: WfPrimaryButton(
                      label: 'Add IP',
                      icon: Icons.add_rounded,
                      onTap: () => open()))
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    return WfCard(
                        onTap: () => open(r),
                        child: Row(children: [
                          const WfIconBox(
                              icon: Icons.wifi_rounded, color: wfTeal),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('${r['label'] ?? 'Shop WiFi'}',
                                    style: const TextStyle(
                                        color: wfDark,
                                        fontWeight: FontWeight.w900)),
                                Text(
                                    '${r['ip_address'] ?? ''} • ${'${r['is_active'] ?? 1}' == '1' ? 'Active' : 'Inactive'}',
                                    style: const TextStyle(
                                        color: wfMuted,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12))
                              ])),
                          const Icon(Icons.edit_rounded, color: wfMuted)
                        ]));
                  }));
}

class _IpDialog extends StatefulWidget {
  const _IpDialog({required this.api, required this.ref_, this.item});
  final WorkforceApi api;
  final WidgetRef ref_;
  final Map<String, dynamic>? item;
  @override
  State<_IpDialog> createState() => _IpDialogState();
}

class _IpDialogState extends State<_IpDialog> {
  final label = TextEditingController();
  final ip = TextEditingController();
  bool active = true;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final i = widget.item;
    if (i != null) {
      label.text = '${i['label'] ?? ''}';
      ip.text = '${i['ip_address'] ?? ''}';
      active = '${i['is_active'] ?? 1}' == '1';
    }
  }

  Future<void> save() async {
    if (ip.text.trim().isEmpty) return;
    setState(() => saving = true);
    try {
      await widget.api.post('/workforce/save_allowed_ip.php', widget.ref_, {
        'id': '${widget.item?['id'] ?? ''}',
        'label': label.text.trim(),
        'ip_address': ip.text.trim(),
        'is_active': active ? '1' : '0'
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    }
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Allowed WiFi IP'),
          content: SizedBox(
              width: 430,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                WfTextField(
                    controller: label, label: 'Label', hint: 'Main Shop WiFi'),
                const SizedBox(height: 10),
                WfTextField(
                    controller: ip,
                    label: 'Public IP Address',
                    hint: '102.xxx.xxx.xxx'),
                SwitchListTile(
                    value: active,
                    onChanged: (v) => setState(() => active = v),
                    title: const Text('Active'))
              ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: saving ? null : save,
                child: Text(saving ? 'Saving...' : 'Save'))
          ]);
}
