import 'package:venastudio/common.dart';

class WorkforceStationsPage extends ConsumerStatefulWidget {
  const WorkforceStationsPage({super.key});

  @override
  ConsumerState<WorkforceStationsPage> createState() =>
      _WorkforceStationsPageState();
}

class _WorkforceStationsPageState extends ConsumerState<WorkforceStationsPage> {
  final api = WorkforceApi();

  bool loading = true;
  List<Map<String, dynamic>> rows = [];
  String selectedType = 'all';

  final stationTypes = const [
    {'id': 'all', 'name': 'All', 'icon': Icons.grid_view_rounded},
    {'id': 'nails', 'name': 'Nails', 'icon': Icons.back_hand_rounded},
    {'id': 'lashes', 'name': 'Lashes', 'icon': Icons.visibility_rounded},
    {'id': 'pedicure', 'name': 'Pedicure', 'icon': Icons.spa_rounded},
    {'id': 'waxing', 'name': 'Waxing', 'icon': Icons.auto_awesome_rounded},
    {'id': 'tattoo', 'name': 'Tattoo', 'icon': Icons.brush_rounded},
    {'id': 'piercing', 'name': 'Piercing', 'icon': Icons.diamond_rounded},
    {'id': 'custom', 'name': 'Custom', 'icon': Icons.chair_rounded},
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      rows = await api.stations(ref);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }

    if (mounted) setState(() => loading = false);
  }

  List<Map<String, dynamic>> get filteredRows {
    if (selectedType == 'all') return rows;

    return rows.where((row) {
      return '${row['station_type'] ?? ''}' == selectedType;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> groupedRows() {
    final map = <String, List<Map<String, dynamic>>>{};

    for (final row in filteredRows) {
      final type = '${row['station_type'] ?? 'custom'}';
      map.putIfAbsent(type, () => []).add(row);
    }

    return map;
  }

  int countType(String type) {
    if (type == 'all') return rows.length;
    return rows.where((row) => '${row['station_type'] ?? ''}' == type).length;
  }

  String typeLabel(String type) {
    final found = stationTypes.where((e) => e['id'] == type);
    if (found.isNotEmpty) return '${found.first['name']}';
    return type.isEmpty ? 'Custom' : type;
  }

  IconData typeIcon(String type) {
    final found = stationTypes.where((e) => e['id'] == type);
    if (found.isNotEmpty) return found.first['icon'] as IconData;
    return Icons.chair_rounded;
  }

  Future<void> openSingle({
    Map<String, dynamic>? item,
    String? forcedType,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _StationDialog(
        api: api,
        ref_: ref,
        item: item,
        initialType: forcedType ?? selectedType,
      ),
    );

    if (ok == true) load();
  }

  Future<void> openBulk({String? forcedType}) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BulkStationDialog(
        api: api,
        ref_: ref,
        initialType: forcedType ?? selectedType,
      ),
    );

    if (ok == true) load();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupedRows();

    return WfShell(
      title: 'Stations',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: WfGhostButton(
            label: 'Bulk Add',
            icon: Icons.grid_view_rounded,
            onTap: () => openBulk(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: WfPrimaryButton(
            label: 'Add One',
            icon: Icons.add_rounded,
            onTap: () => openSingle(),
            compact: true,
          ),
        ),
      ],
      child: loading
          ? const Center(child: CircularProgressIndicator(color: wfTeal))
          : Column(
              children: [
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: stationTypes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, index) {
                      final type = stationTypes[index];
                      final id = '${type['id']}';
                      final selected = selectedType == id;
                      final count = countType(id);

                      return InkWell(
                        onTap: () => setState(() => selectedType = id),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 150,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected ? wfTeal : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? wfTeal : wfLine,
                            ),
                            boxShadow: [
                              if (selected)
                                BoxShadow(
                                  color: wfTeal.withOpacity(.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                type['icon'] as IconData,
                                color: selected ? Colors.white : wfTeal,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${type['name']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            selected ? Colors.white : wfDark,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      '$count stations',
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white70
                                            : wfMuted,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: rows.isEmpty
                      ? WfEmpty(
                          icon: Icons.chair_rounded,
                          title: 'No stations',
                          message:
                              'Add lash beds, nail stations, pedicure chairs and work areas.',
                          action: WfPrimaryButton(
                            label: 'Bulk Add Stations',
                            icon: Icons.grid_view_rounded,
                            onTap: () => openBulk(),
                          ),
                        )
                      : grouped.isEmpty
                          ? WfEmpty(
                              icon: Icons.category_rounded,
                              title: 'No ${typeLabel(selectedType)} stations',
                              message:
                                  'Create stations for this category to organize assignments better.',
                              action: WfPrimaryButton(
                                label: 'Add ${typeLabel(selectedType)}',
                                icon: Icons.add_rounded,
                                onTap: () => openBulk(forcedType: selectedType),
                              ),
                            )
                          : RefreshIndicator(
                              color: wfTeal,
                              onRefresh: load,
                              child: ListView(
                                children: grouped.entries.map((entry) {
                                  final type = entry.key;
                                  final stations = entry.value;

                                  return _StationCategorySection(
                                    title: typeLabel(type),
                                    icon: typeIcon(type),
                                    stations: stations,
                                    onAddOne: () =>
                                        openSingle(forcedType: type),
                                    onBulkAdd: () => openBulk(forcedType: type),
                                    onEdit: openSingle,
                                  );
                                }).toList(),
                              ),
                            ),
                ),
              ],
            ),
    );
  }
}

class _StationCategorySection extends StatelessWidget {
  const _StationCategorySection({
    required this.title,
    required this.icon,
    required this.stations,
    required this.onAddOne,
    required this.onBulkAdd,
    required this.onEdit,
  });

  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> stations;
  final VoidCallback onAddOne;
  final VoidCallback onBulkAdd;
  final void Function({Map<String, dynamic>? item, String? forcedType}) onEdit;

  @override
  Widget build(BuildContext context) {
    final activeCount = stations.where((s) {
      return '${s['is_active'] ?? 1}' == '1';
    }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: wfLine),
      ),
      child: Column(
        children: [
          Row(
            children: [
              WfIconBox(icon: icon, color: wfTeal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: wfDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '$activeCount active • ${stations.length} total',
                      style: const TextStyle(
                        color: wfMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              WfGhostButton(
                label: 'Bulk Add',
                icon: Icons.grid_view_rounded,
                onTap: onBulkAdd,
              ),
              const SizedBox(width: 8),
              WfPrimaryButton(
                label: 'Add One',
                icon: Icons.add_rounded,
                onTap: onAddOne,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stations.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 310,
              mainAxisExtent: 82,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, index) {
              final item = stations[index];
              final active = '${item['is_active'] ?? 1}' == '1';

              return InkWell(
                onTap: () => onEdit(item: item),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xffF7FBFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: wfLine),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        active
                            ? Icons.chair_rounded
                            : Icons.block_rounded,
                        color: active ? wfTeal : wfMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item['name'] ?? 'Station'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: wfDark,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              active ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                color: wfMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_rounded, color: wfMuted, size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StationDialog extends StatefulWidget {
  const _StationDialog({
    required this.api,
    required this.ref_,
    this.item,
    this.initialType = 'custom',
  });

  final WorkforceApi api;
  final WidgetRef ref_;
  final Map<String, dynamic>? item;
  final String initialType;

  @override
  State<_StationDialog> createState() => _StationDialogState();
}

class _StationDialogState extends State<_StationDialog> {
  final name = TextEditingController();

  String stationType = 'custom';
  bool active = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    stationType =
        widget.initialType == 'all' ? 'custom' : widget.initialType;

    final item = widget.item;
    if (item != null) {
      name.text = '${item['name'] ?? ''}';
      stationType = '${item['station_type'] ?? 'custom'}';
      active = '${item['is_active'] ?? 1}' == '1';
    }
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Station name is required')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await widget.api.post(
        '/workforce/save_station.php',
        widget.ref_,
        {
          'id': widget.item == null ? '' : '${widget.item!['id'] ?? ''}',
          'name': name.text.trim(),
          'station_type': stationType,
          'is_active': active ? '1' : '0',
        },
      );

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
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.item == null ? 'Add Station' : 'Edit Station',
        style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WfTextField(
              controller: name,
              label: 'Station Name',
              hint: 'Nail Station 1',
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: stationType,
              decoration: InputDecoration(
                labelText: 'Station Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'nails', child: Text('Nails')),
                DropdownMenuItem(value: 'lashes', child: Text('Lashes')),
                DropdownMenuItem(value: 'pedicure', child: Text('Pedicure')),
                DropdownMenuItem(value: 'waxing', child: Text('Waxing')),
                DropdownMenuItem(value: 'tattoo', child: Text('Tattoo')),
                DropdownMenuItem(value: 'piercing', child: Text('Piercing')),
                DropdownMenuItem(value: 'custom', child: Text('Custom')),
              ],
              onChanged: (value) {
                setState(() => stationType = value ?? 'custom');
              },
            ),
            SwitchListTile(
              value: active,
              activeColor: wfTeal,
              onChanged: (value) => setState(() => active = value),
              title: const Text('Active'),
            ),
          ],
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

class _BulkStationDialog extends StatefulWidget {
  const _BulkStationDialog({
    required this.api,
    required this.ref_,
    this.initialType = 'custom',
  });

  final WorkforceApi api;
  final WidgetRef ref_;
  final String initialType;

  @override
  State<_BulkStationDialog> createState() => _BulkStationDialogState();
}

class _BulkStationDialogState extends State<_BulkStationDialog> {
  final prefix = TextEditingController();
  final count = TextEditingController(text: '5');
  final startNumber = TextEditingController(text: '1');

  String stationType = 'custom';
  bool active = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    stationType =
        widget.initialType == 'all' ? 'custom' : widget.initialType;

    prefix.text = defaultPrefix(stationType);
  }

  String defaultPrefix(String type) {
    if (type == 'nails') return 'Nail Station';
    if (type == 'lashes') return 'Lash Bed';
    if (type == 'pedicure') return 'Pedicure Chair';
    if (type == 'waxing') return 'Waxing Room';
    if (type == 'tattoo') return 'Tattoo Booth';
    if (type == 'piercing') return 'Piercing Station';
    return 'Station';
  }

  @override
  void dispose() {
    prefix.dispose();
    count.dispose();
    startNumber.dispose();
    super.dispose();
  }

  List<String> previewNames() {
    final total = int.tryParse(count.text.trim()) ?? 0;
    final start = int.tryParse(startNumber.text.trim()) ?? 1;
    final base = prefix.text.trim().isEmpty ? 'Station' : prefix.text.trim();

    if (total <= 0) return [];

    return List.generate(total, (index) => '$base ${start + index}');
  }

  Future<void> save() async {
    final total = int.tryParse(count.text.trim()) ?? 0;

    if (prefix.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Station prefix is required')),
      );
      return;
    }

    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Count must be greater than zero')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await widget.api.post(
        '/workforce/bulk_save_stations.php',
        widget.ref_,
        {
          'prefix': prefix.text.trim(),
          'station_type': stationType,
          'count': count.text.trim(),
          'start_number': startNumber.text.trim(),
          'is_active': active ? '1' : '0',
        },
      );

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
  Widget build(BuildContext context) {
    final previews = previewNames();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      title: const Text(
        'Bulk Add Stations',
        style: TextStyle(color: wfDark, fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 740,
        height: 480,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xffF7FBFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: wfLine),
                ),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: stationType,
                      decoration: InputDecoration(
                        labelText: 'Station Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'nails', child: Text('Nails')),
                        DropdownMenuItem(
                            value: 'lashes', child: Text('Lashes')),
                        DropdownMenuItem(
                            value: 'pedicure', child: Text('Pedicure')),
                        DropdownMenuItem(
                            value: 'waxing', child: Text('Waxing')),
                        DropdownMenuItem(
                            value: 'tattoo', child: Text('Tattoo')),
                        DropdownMenuItem(
                            value: 'piercing', child: Text('Piercing')),
                        DropdownMenuItem(
                            value: 'custom', child: Text('Custom')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          stationType = value ?? 'custom';
                          prefix.text = defaultPrefix(stationType);
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    WfTextField(
                      controller: prefix,
                      label: 'Station Prefix',
                      hint: 'Nail Station',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: count,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Count',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: startNumber,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Start Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      value: active,
                      activeColor: wfTeal,
                      onChanged: (value) => setState(() => active = value),
                      title: const Text('Create as active'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xffF7FBFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: wfLine),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview',
                      style: TextStyle(
                        color: wfDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: previews.isEmpty
                          ? const Center(
                              child: Text(
                                'Enter count to preview stations',
                                style: TextStyle(
                                  color: wfMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: previews.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, index) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: wfLine),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.chair_rounded,
                                        size: 18,
                                        color: wfTeal,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          previews[index],
                                          style: const TextStyle(
                                            color: wfDark,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: saving ? null : save,
          icon: const Icon(Icons.grid_view_rounded),
          label: Text(saving ? 'Creating...' : 'Create Stations'),
        ),
      ],
    );
  }
}
