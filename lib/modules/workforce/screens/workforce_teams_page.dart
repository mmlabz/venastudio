import 'package:venastudio/common.dart';

class WorkforceTeamsPage extends ConsumerStatefulWidget {
  const WorkforceTeamsPage({super.key});

  @override
  ConsumerState<WorkforceTeamsPage> createState() => _WorkforceTeamsPageState();
}

class _WorkforceTeamsPageState extends ConsumerState<WorkforceTeamsPage> {
  final WorkforceApi api = WorkforceApi();

  bool loading = true;
  List<Map<String, dynamic>> teams = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      teams = await api.teams(ref);
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> open([Map<String, dynamic>? item]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _TeamDialog(item: item, api: api, ref_: ref),
    );

    if (saved == true) load();
  }

  @override
  Widget build(BuildContext context) {
    return WfShell(
      title: 'Teams',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: WfPrimaryButton(
            label: 'Add Team',
            icon: Icons.add_rounded,
            onTap: () => open(),
            compact: true,
          ),
        ),
      ],
      child: loading
          ? const Center(child: CircularProgressIndicator(color: wfTeal))
          : teams.isEmpty
              ? WfEmpty(
                  icon: Icons.groups_rounded,
                  title: 'No teams yet',
                  message: 'Create Day Team A/B or Night Team A/B.',
                  action: WfPrimaryButton(
                    label: 'Create Team',
                    icon: Icons.add_rounded,
                    onTap: () => open(),
                  ),
                )
              : RefreshIndicator(
                  color: wfTeal,
                  onRefresh: load,
                  child: ListView.separated(
                    itemCount: teams.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final team = teams[index];
                      final active = '${team['is_active'] ?? 1}' == '1';
                      final type = '${team['team_type'] ?? 'day'}';

                      return WfCard(
                        onTap: () => open(team),
                        child: Row(
                          children: [
                            WfIconBox(
                              icon: type == 'night'
                                  ? Icons.nights_stay_rounded
                                  : Icons.wb_sunny_rounded,
                              color: active ? wfTeal : wfMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${team['name'] ?? 'Team'}',
                                    style: const TextStyle(
                                      color: wfDark,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$type • ${active ? 'Active' : 'Inactive'}',
                                    style: const TextStyle(
                                      color: wfMuted,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if ('${team['description'] ?? ''}'.isNotEmpty)
                                    Text(
                                      '${team['description']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: wfMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.edit_rounded, color: wfMuted),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _TeamDialog extends StatefulWidget {
  const _TeamDialog({this.item, required this.api, required this.ref_});

  final Map<String, dynamic>? item;
  final WorkforceApi api;
  final WidgetRef ref_;

  @override
  State<_TeamDialog> createState() => _TeamDialogState();
}

class _TeamDialogState extends State<_TeamDialog> {
  final TextEditingController name = TextEditingController();
  final TextEditingController desc = TextEditingController();

  String type = 'day';
  bool active = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      name.text = '${item['name'] ?? ''}';
      desc.text = '${item['description'] ?? ''}';
      type = '${item['team_type'] ?? 'day'}';
      active = '${item['is_active'] ?? 1}' == '1';
    }
  }

  @override
  void dispose() {
    name.dispose();
    desc.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Team name required');
      return;
    }

    setState(() => saving = true);

    try {
      await widget.api.post('/workforce/save_team.php', widget.ref_, {
        'id': widget.item == null ? '' : '${widget.item!['id'] ?? ''}',
        'name': name.text.trim(),
        'description': desc.text.trim(),
        'team_type': type,
        'is_active': active ? '1' : '0',
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      Fluttertoast.showToast(msg: '$e');
    }

    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.item == null ? 'Add Team' : 'Edit Team',
        style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WfTextField(controller: name, label: 'Team Name', hint: 'Day Team A'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: type,
                decoration: InputDecoration(
                  labelText: 'Team Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: const [
                  DropdownMenuItem(value: 'day', child: Text('Day Team')),
                  DropdownMenuItem(value: 'night', child: Text('Night Team')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom Team')),
                ],
                onChanged: (value) => setState(() => type = value ?? 'day'),
              ),
              const SizedBox(height: 10),
              WfTextField(controller: desc, label: 'Description', maxLines: 3),
              SwitchListTile(
                value: active,
                activeColor: wfTeal,
                onChanged: (value) => setState(() => active = value),
                title: const Text('Active'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: saving ? null : save,
          child: Text(saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
