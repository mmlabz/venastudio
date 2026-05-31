import 'dart:convert';

import 'package:venastudio/common.dart';

import '../controllers/workforce_api.dart';
import '../widgets/workforce_ui.dart';

class WorkforceSkillsPage extends ConsumerStatefulWidget {
  const WorkforceSkillsPage({super.key});

  @override
  ConsumerState<WorkforceSkillsPage> createState() =>
      _WorkforceSkillsPageState();
}

class _WorkforceSkillsPageState extends ConsumerState<WorkforceSkillsPage> {
  final api = WorkforceApi();

  bool loading = true;
  List<Map<String, dynamic>> summaries = [];
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> services = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      final result = await Future.wait([
        api.get('/workforce/staff_skill_summary.php', ref),
        api.employees(ref),
        api.get('/workforce/service_categories.php', ref),
        api.get('/workforce/services.php', ref),
      ]);

      summaries = result[0];
      employees = result[1];
      categories = result[2];
      services = result[3];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> openBulk() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BulkSkillDialog(
        api: api,
        ref_: ref,
        employees: employees,
        categories: categories,
        services: services,
      ),
    );

    if (ok == true) load();
  }

  Future<void> openEditor(Map<String, dynamic> staff) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditStaffSkillsDialog(
        api: api,
        ref_: ref,
        staff: staff,
        categories: categories,
        services: services,
      ),
    );

    if (ok == true) load();
  }

  @override
  Widget build(BuildContext context) {
    return WfShell(
      title: 'Staff Skills',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: WfPrimaryButton(
            label: 'Bulk Map',
            icon: Icons.add_rounded,
            onTap: openBulk,
            compact: true,
          ),
        ),
      ],
      child: loading
          ? const Center(child: CircularProgressIndicator(color: wfTeal))
          : summaries.isEmpty
              ? WfEmpty(
                  icon: Icons.workspace_premium_rounded,
                  title: 'No staff skills',
                  message:
                      'Bulk-map staff to categories and services. Primary skills are category-based.',
                  action: WfPrimaryButton(
                    label: 'Bulk Map Skills',
                    icon: Icons.add_rounded,
                    onTap: openBulk,
                  ),
                )
              : RefreshIndicator(
                  color: wfTeal,
                  onRefresh: load,
                  child: ListView.separated(
                    itemCount: summaries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final item = summaries[index];
                      final total =
                          int.tryParse('${item['total_skills'] ?? 0}') ?? 0;
                      final primary = '${item['primary_category_name'] ?? ''}';
                      final categoryText =
                          '${item['category_summary'] ?? ''}'.trim();

                      return WfCard(
                        onTap: () => openEditor(item),
                        child: Row(
                          children: [
                            const WfIconBox(
                              icon: Icons.workspace_premium_rounded,
                              color: wfTeal,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item['staff_name'] ?? 'Staff'}',
                                    style: const TextStyle(
                                      color: wfDark,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    primary.isEmpty
                                        ? 'Primary: Not set'
                                        : 'Primary: $primary',
                                    style: const TextStyle(
                                      color: wfMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (categoryText.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: categoryText
                                          .split('|')
                                          .where((e) => e.trim().isNotEmpty)
                                          .map((e) => WfChip(
                                                label: e.trim(),
                                                color: wfTeal,
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            WfChip(label: '$total skills', color: wfSuccess),
                            const SizedBox(width: 10),
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

class _BulkSkillDialog extends StatefulWidget {
  const _BulkSkillDialog({
    required this.api,
    required this.ref_,
    required this.employees,
    required this.categories,
    required this.services,
  });

  final WorkforceApi api;
  final WidgetRef ref_;
  final List<Map<String, dynamic>> employees;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> services;

  @override
  State<_BulkSkillDialog> createState() => _BulkSkillDialogState();
}

class _BulkSkillDialogState extends State<_BulkSkillDialog> {
  final staffSearch = TextEditingController();
  final serviceSearch = TextEditingController();

  final selectedStaff = <String>{};
  final selectedCategories = <String>{};
  final excludedServices = <String>{};

  String primaryCategoryId = '';
  String skillLevel = 'good';
  bool saving = false;

  @override
  void dispose() {
    staffSearch.dispose();
    serviceSearch.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get visibleStaff {
    final query = staffSearch.text.trim().toLowerCase();

    return widget.employees.where((staff) {
      final name = '${staff['name'] ?? ''}'.toLowerCase();
      final code =
          '${staff['employee_no'] ?? staff['agent_code'] ?? ''}'.toLowerCase();
      return query.isEmpty || name.contains(query) || code.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get selectedCategoryServices {
    final query = serviceSearch.text.trim().toLowerCase();

    return widget.services.where((service) {
      final categoryId =
          '${service['category'] ?? service['service_type_id'] ?? ''}';
      final name = '${service['name'] ?? ''}'.toLowerCase();

      return selectedCategories.contains(categoryId) &&
          (query.isEmpty || name.contains(query));
    }).toList();
  }

  int get includedServiceCount {
    return selectedCategoryServices
        .where((service) => !excludedServices.contains('${service['id']}'))
        .length;
  }

  void selectVisibleStaff() {
    setState(() {
      for (final staff in visibleStaff) {
        selectedStaff.add('${staff['id']}');
      }
    });
  }

  Future<void> save() async {
    if (selectedStaff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one staff')),
      );
      return;
    }

    if (selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one category')),
      );
      return;
    }

    if (primaryCategoryId.isNotEmpty &&
        !selectedCategories.contains(primaryCategoryId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primary category must be selected')),
      );
      return;
    }

    if (includedServiceCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No services left to map')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await widget.api.post(
        '/workforce/bulk_save_skills.php',
        widget.ref_,
        {
          'employee_ids': selectedStaff.join(','),
          'service_type_ids': selectedCategories.join(','),
          'excluded_service_ids': excludedServices.join(','),
          'primary_service_type_id': primaryCategoryId,
          'skill_level': skillLevel,
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
    final staff = visibleStaff;
    final services = selectedCategoryServices;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      title: const Text(
        'Bulk Map Staff Skills',
        style: TextStyle(color: wfDark, fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 1120,
        height: 700,
        child: Row(
          children: [
            Expanded(
              child: _Panel(
                title: '1. Staff',
                footer: '${selectedStaff.length} selected',
                child: Column(
                  children: [
                    TextField(
                      controller: staffSearch,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Search staff',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: selectVisibleStaff,
                          child: const Text('Select visible'),
                        ),
                        TextButton(
                          onPressed: () => setState(selectedStaff.clear),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    Expanded(
                      child: staff.isEmpty
                          ? const Center(
                              child: Text(
                                'No staff found',
                                style: TextStyle(
                                  color: wfMuted,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: staff.length,
                              itemBuilder: (_, index) {
                                final item = staff[index];
                                final id = '${item['id']}';

                                return CheckboxListTile(
                                  value: selectedStaff.contains(id),
                                  dense: true,
                                  activeColor: wfTeal,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedStaff.add(id);
                                      } else {
                                        selectedStaff.remove(id);
                                      }
                                    });
                                  },
                                  title: Text('${item['name'] ?? 'Staff'}'),
                                  subtitle:
                                      '${item['employee_no'] ?? ''}'.isEmpty
                                          ? null
                                          : Text('${item['employee_no']}'),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Panel(
                title: '2. Categories',
                footer: '${selectedCategories.length} selected',
                child: widget.categories.isEmpty
                    ? const Center(
                        child: Text(
                          'No categories found',
                          style: TextStyle(
                            color: wfMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: widget.categories.length,
                        itemBuilder: (_, index) {
                          final category = widget.categories[index];
                          final id = '${category['id']}';

                          final count = widget.services.where((service) {
                            return '${service['category'] ?? service['service_type_id'] ?? ''}' ==
                                id;
                          }).length;

                          final selected = selectedCategories.contains(id);
                          final primary = primaryCategoryId == id;

                          return CheckboxListTile(
                            value: selected,
                            dense: true,
                            activeColor: wfTeal,
                            secondary: selected
                                ? IconButton(
                                    tooltip: 'Set as primary category',
                                    icon: Icon(
                                      primary
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: primary ? wfAmber : wfMuted,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        primaryCategoryId =
                                            primary ? '' : id;
                                      });
                                    },
                                  )
                                : null,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedCategories.add(id);
                                  primaryCategoryId =
                                      primaryCategoryId.isEmpty
                                          ? id
                                          : primaryCategoryId;
                                } else {
                                  selectedCategories.remove(id);

                                  if (primaryCategoryId == id) {
                                    primaryCategoryId = selectedCategories.isEmpty
                                        ? ''
                                        : selectedCategories.first;
                                  }

                                  for (final service in widget.services.where((s) {
                                    return '${s['category'] ?? s['service_type_id'] ?? ''}' ==
                                        id;
                                  })) {
                                    excludedServices.remove('${service['id']}');
                                  }
                                }
                              });
                            },
                            title: Text('${category['name'] ?? 'Category'}'),
                            subtitle: Text(
                              primary ? '$count services • Primary' : '$count services',
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Panel(
                title: '3. Services',
                footer: '$includedServiceCount included',
                child: Column(
                  children: [
                    TextField(
                      controller: serviceSearch,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Search selected services',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedCategories.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Select a category to show its services.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: wfMuted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: services.isEmpty
                            ? const Center(
                                child: Text(
                                  'No services found in selected categories.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: wfMuted,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: services.length,
                                itemBuilder: (_, index) {
                                  final service = services[index];
                                  final id = '${service['id']}';
                                  final included =
                                      !excludedServices.contains(id);

                                  return CheckboxListTile(
                                    value: included,
                                    dense: true,
                                    activeColor: wfTeal,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          excludedServices.remove(id);
                                        } else {
                                          excludedServices.add(id);
                                        }
                                      });
                                    },
                                    title: Text(
                                      '${service['name'] ?? 'Service'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                      ),
                    const Divider(),
                    DropdownButtonFormField<String>(
                      value: skillLevel,
                      decoration: InputDecoration(
                        labelText: 'Skill Level',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'basic', child: Text('Basic')),
                        DropdownMenuItem(value: 'good', child: Text('Good')),
                        DropdownMenuItem(value: 'expert', child: Text('Expert')),
                      ],
                      onChanged: (value) {
                        setState(() => skillLevel = value ?? 'good');
                      },
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
          icon: const Icon(Icons.save_rounded),
          label: Text(saving ? 'Saving...' : 'Save Skills'),
        ),
      ],
    );
  }
}

class _EditStaffSkillsDialog extends StatefulWidget {
  const _EditStaffSkillsDialog({
    required this.api,
    required this.ref_,
    required this.staff,
    required this.categories,
    required this.services,
  });

  final WorkforceApi api;
  final WidgetRef ref_;
  final Map<String, dynamic> staff;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> services;

  @override
  State<_EditStaffSkillsDialog> createState() => _EditStaffSkillsDialogState();
}

class _EditStaffSkillsDialogState extends State<_EditStaffSkillsDialog> {
  bool loading = true;
  bool saving = false;

  List<Map<String, dynamic>> rows = [];
  final activeSkillIds = <String>{};
  final levels = <String, String>{};
  String primaryCategoryId = '';

  int get employeeId =>
      int.tryParse('${widget.staff['employee_id'] ?? widget.staff['id'] ?? 0}') ??
      0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      final res = await widget.api.post(
        '/workforce/staff_skills.php',
        widget.ref_,
        {'employee_id': '$employeeId'},
      );

      final raw = res['skills'] ?? res['data'] ?? [];
      if (raw is List) {
        rows = raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      activeSkillIds.clear();
      levels.clear();

      for (final row in rows) {
        final serviceId = '${row['service_id'] ?? ''}';
        if (serviceId.isEmpty) continue;
        activeSkillIds.add(serviceId);
        levels[serviceId] = '${row['skill_level'] ?? 'good'}';
      }

      final primary = res['primary_category'];
      if (primary is Map) {
        primaryCategoryId = '${primary['service_type_id'] ?? ''}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }

    if (mounted) setState(() => loading = false);
  }

  Map<String, List<Map<String, dynamic>>> groupedServices() {
    final map = <String, List<Map<String, dynamic>>>{};

    for (final service in widget.services) {
      final cat = '${service['category'] ?? service['service_type_id'] ?? ''}';
      map.putIfAbsent(cat, () => []).add(service);
    }

    return map;
  }

  int countActiveInCategory(String categoryId) {
    return widget.services.where((service) {
      final cat = '${service['category'] ?? service['service_type_id'] ?? ''}';
      final sid = '${service['id']}';
      return cat == categoryId && activeSkillIds.contains(sid);
    }).length;
  }

  Future<void> save() async {
    setState(() => saving = true);

    try {
      final payload = activeSkillIds.map((serviceId) {
        final service = widget.services.firstWhere(
          (s) => '${s['id']}' == serviceId,
          orElse: () => {},
        );

        return {
          'service_id': serviceId,
          'service_type_id':
              '${service['category'] ?? service['service_type_id'] ?? ''}',
          'skill_level': levels[serviceId] ?? 'good',
        };
      }).toList();

      await widget.api.post(
        '/workforce/update_staff_skills.php',
        widget.ref_,
        {
          'employee_id': '$employeeId',
          'primary_service_type_id': primaryCategoryId,
          'skills_json': jsonEncode(payload),
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
    final grouped = groupedServices();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      title: Text(
        'Edit Skills — ${widget.staff['staff_name'] ?? 'Staff'}',
        style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 920,
        height: 680,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: wfTeal))
            : Row(
                children: [
                  SizedBox(
                    width: 280,
                    child: _Panel(
                      title: 'Categories',
                      child: ListView.builder(
                        itemCount: widget.categories.length,
                        itemBuilder: (_, index) {
                          final category = widget.categories[index];
                          final id = '${category['id']}';
                          final activeCount = countActiveInCategory(id);
                          final primary = primaryCategoryId == id;

                          return ListTile(
                            dense: true,
                            leading: IconButton(
                              tooltip: 'Set primary',
                              icon: Icon(
                                primary
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: primary ? wfAmber : wfMuted,
                              ),
                              onPressed: activeCount == 0
                                  ? null
                                  : () {
                                      setState(() {
                                        primaryCategoryId =
                                            primary ? '' : id;
                                      });
                                    },
                            ),
                            title: Text('${category['name'] ?? 'Category'}'),
                            subtitle: Text('$activeCount active skills'),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Panel(
                      title: 'Services',
                      child: ListView(
                        children: widget.categories.map((category) {
                          final categoryId = '${category['id']}';
                          final services = grouped[categoryId] ?? [];

                          if (services.isEmpty) return const SizedBox.shrink();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: wfLine),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${category['name']}',
                                        style: const TextStyle(
                                          color: wfDark,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          for (final s in services) {
                                            final sid = '${s['id']}';
                                            activeSkillIds.add(sid);
                                            levels[sid] = levels[sid] ?? 'good';
                                          }
                                          primaryCategoryId =
                                              primaryCategoryId.isEmpty
                                                  ? categoryId
                                                  : primaryCategoryId;
                                        });
                                      },
                                      child: const Text('Select all'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          for (final s in services) {
                                            final sid = '${s['id']}';
                                            activeSkillIds.remove(sid);
                                          }
                                          if (primaryCategoryId == categoryId) {
                                            primaryCategoryId = '';
                                          }
                                        });
                                      },
                                      child: const Text('Clear'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ...services.map((service) {
                                  final sid = '${service['id']}';
                                  final active = activeSkillIds.contains(sid);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: active,
                                          activeColor: wfTeal,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value == true) {
                                                activeSkillIds.add(sid);
                                                levels[sid] = levels[sid] ?? 'good';
                                                primaryCategoryId =
                                                    primaryCategoryId.isEmpty
                                                        ? categoryId
                                                        : primaryCategoryId;
                                              } else {
                                                activeSkillIds.remove(sid);
                                                if (countActiveInCategory(categoryId) == 0 &&
                                                    primaryCategoryId == categoryId) {
                                                  primaryCategoryId = '';
                                                }
                                              }
                                            });
                                          },
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${service['name'] ?? 'Service'}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 125,
                                          child: DropdownButtonFormField<String>(
                                            value: levels[sid] ?? 'good',
                                            decoration: InputDecoration(
                                              isDense: true,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'basic',
                                                child: Text('Basic'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'good',
                                                child: Text('Good'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'expert',
                                                child: Text('Expert'),
                                              ),
                                            ],
                                            onChanged: active
                                                ? (value) {
                                                    setState(() {
                                                      levels[sid] =
                                                          value ?? 'good';
                                                    });
                                                  }
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }).toList(),
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
          icon: const Icon(Icons.save_rounded),
          label: Text(saving ? 'Saving...' : 'Save Changes'),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.footer,
  });

  final String title;
  final Widget child;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF7FBFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: wfLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: wfDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (footer != null)
                Text(
                  footer!,
                  style: const TextStyle(
                    color: wfMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}
