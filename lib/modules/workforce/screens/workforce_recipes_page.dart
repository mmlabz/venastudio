import 'dart:convert';
import 'package:venastudio/common.dart';
import '../controllers/workforce_api.dart';
import '../widgets/workforce_ui.dart';

class WorkforceRecipesPage extends ConsumerStatefulWidget {
  const WorkforceRecipesPage({super.key});
  @override
  ConsumerState<WorkforceRecipesPage> createState() => _WorkforceRecipesPageState();
}

class _WorkforceRecipesPageState extends ConsumerState<WorkforceRecipesPage> {
  final api = WorkforceApi();
  final search = TextEditingController();
  bool loading = true;
  bool serviceView = true;
  List<Map<String, dynamic>> serviceRows = [];
  List<Map<String, dynamic>> productRows = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> groups = [];

  @override
  void initState() { super.initState(); load(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final serviceResponse = await api.post('/workforce/service_recipes.php', ref, {});
      final productResponse = await api.post('/workforce/recipe_products.php', ref, {});
      final catRows = await api.get('/workforce/service_categories.php', ref);
      final serviceList = await api.get('/workforce/services.php', ref);
      final groupRows = await api.get('/workforce/product_groups.php', ref);
      final rawServices = serviceResponse['services'] ?? serviceResponse['data'] ?? [];
      final rawProducts = productResponse['products'] ?? productResponse['data'] ?? [];
      serviceRows = rawServices is List ? rawServices.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
      productRows = rawProducts is List ? rawProducts.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
      categories = catRows; services = serviceList; groups = groupRows;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => loading = false);
  }

  List<Map<String, dynamic>> get filteredServices {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return serviceRows;
    return serviceRows.where((r) => '${r['service_name'] ?? ''} ${r['category_name'] ?? ''} ${r['product_summary'] ?? ''}'.toLowerCase().contains(q)).toList();
  }

  List<Map<String, dynamic>> get filteredProducts {
    final q = search.text.trim().toLowerCase();
    if (q.isEmpty) return productRows;
    return productRows.where((r) => '${r['product_group_name'] ?? ''} ${r['service_summary'] ?? ''}'.toLowerCase().contains(q)).toList();
  }

  Map<String, List<Map<String, dynamic>>> groupedServices() {
    final m = <String, List<Map<String, dynamic>>>{};
    for (final r in filteredServices) {
      final c = '${r['category_name'] ?? 'Uncategorised'}';
      m.putIfAbsent(c, () => []).add(r);
    }
    return m;
  }

  Future<void> openBulk() async {
    final ok = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => _BulkRecipeDialog(api: api, ref_: ref, categories: categories, services: services, groups: groups));
    if (ok == true) load();
  }

  Future<void> openEdit(Map<String, dynamic> service) async {
    final ok = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => _EditServiceRecipeDialog(api: api, ref_: ref, service: service, groups: groups));
    if (ok == true) load();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupedServices();
    final totalRecipes = serviceRows.fold<int>(0, (s, r) => s + (int.tryParse('${r['recipe_count'] ?? 0}') ?? 0));
    final covered = serviceRows.where((r) => (int.tryParse('${r['recipe_count'] ?? 0}') ?? 0) > 0).length;
    final missing = serviceRows.length - covered;
    return WfShell(
      title: 'Service Recipes',
      actions: [Padding(padding: const EdgeInsets.only(right: 12), child: WfPrimaryButton(label: 'Bulk Create', icon: Icons.add_rounded, onTap: openBulk, compact: true))],
      child: loading ? const Center(child: CircularProgressIndicator(color: wfTeal)) : Column(children: [
        GridView.count(crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.9, children: [
          _StatTile(label: 'Recipes', value: '$totalRecipes', icon: Icons.inventory_2_rounded, color: wfTeal),
          _StatTile(label: 'Services Covered', value: '$covered', icon: Icons.check_circle_rounded, color: wfSuccess),
          _StatTile(label: 'Missing Recipes', value: '$missing', icon: Icons.warning_amber_rounded, color: wfAmber),
          _StatTile(label: 'Product Groups', value: '${productRows.length}', icon: Icons.category_rounded, color: wfDark),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: search, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: serviceView ? 'Search service, category or product' : 'Search product group or service', prefixIcon: const Icon(Icons.search_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
          const SizedBox(width: 10),
          SegmentedButton<bool>(segments: const [ButtonSegment(value: true, label: Text('Services'), icon: Icon(Icons.spa_rounded)), ButtonSegment(value: false, label: Text('Products'), icon: Icon(Icons.inventory_2_rounded))], selected: {serviceView}, onSelectionChanged: (v) => setState(() => serviceView = v.first)),
        ]),
        const SizedBox(height: 14),
        Expanded(child: serviceView ? (grouped.isEmpty ? WfEmpty(icon: Icons.inventory_2_rounded, title: 'No service recipes', message: 'Create recipes by linking services to product groups.', action: WfPrimaryButton(label: 'Bulk Create', icon: Icons.add_rounded, onTap: openBulk)) : RefreshIndicator(color: wfTeal, onRefresh: load, child: ListView(children: grouped.entries.map((e) => _ServiceCategorySection(categoryName: e.key, rows: e.value, onEdit: openEdit)).toList()))) : (filteredProducts.isEmpty ? WfEmpty(icon: Icons.inventory_2_rounded, title: 'No product recipe mappings', message: 'Product groups will appear here after recipes are created.', action: WfPrimaryButton(label: 'Bulk Create', icon: Icons.add_rounded, onTap: openBulk)) : RefreshIndicator(color: wfTeal, onRefresh: load, child: ListView.separated(itemCount: filteredProducts.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) => _ProductRecipeCard(row: filteredProducts[i])))))
      ]),
    );
  }
}

class _StatTile extends StatelessWidget { const _StatTile({required this.label, required this.value, required this.icon, required this.color}); final String label, value; final IconData icon; final Color color; @override Widget build(BuildContext context) => WfCard(child: Row(children: [WfIconBox(icon: icon, color: color), const SizedBox(width: 12), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900, fontSize: 20)), Text(label, style: const TextStyle(color: wfMuted, fontWeight: FontWeight.w800, fontSize: 12))]))])); }

class _ServiceCategorySection extends StatelessWidget { const _ServiceCategorySection({required this.categoryName, required this.rows, required this.onEdit}); final String categoryName; final List<Map<String, dynamic>> rows; final void Function(Map<String, dynamic>) onEdit; @override Widget build(BuildContext context) { final covered = rows.where((r) => (int.tryParse('${r['recipe_count'] ?? 0}') ?? 0) > 0).length; return Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: wfLine)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const WfIconBox(icon: Icons.spa_rounded, color: wfTeal), const SizedBox(width: 12), Expanded(child: Text(categoryName, style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900, fontSize: 18))), WfChip(label: '$covered/${rows.length} covered', color: wfSuccess)]), const SizedBox(height: 12), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: rows.length, gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 420, mainAxisExtent: 148, crossAxisSpacing: 10, mainAxisSpacing: 10), itemBuilder: (_, i) => _ServiceRecipeCard(row: rows[i], onEdit: () => onEdit(rows[i])))])); } }

class _ServiceRecipeCard extends StatelessWidget { const _ServiceRecipeCard({required this.row, required this.onEdit}); final Map<String, dynamic> row; final VoidCallback onEdit; List<Map<String, dynamic>> products() { final raw = row['products']; if (raw is List) return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(); final t = '${row['products_json'] ?? ''}'; if (t.isEmpty) return []; try { final d = jsonDecode(t); if (d is List) return d.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(); } catch (_) {} return []; } @override Widget build(BuildContext context) { final items = products(); final missing = items.isEmpty; return InkWell(onTap: onEdit, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xffF7FBFC), borderRadius: BorderRadius.circular(18), border: Border.all(color: missing ? wfAmber.withOpacity(.5) : wfLine)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [WfIconBox(icon: missing ? Icons.warning_amber_rounded : Icons.inventory_2_rounded, color: missing ? wfAmber : wfTeal), const SizedBox(width: 10), Expanded(child: Text('${row['service_name'] ?? 'Service'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900, fontSize: 15))), IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, color: wfMuted))]), const SizedBox(height: 8), if (missing) const Text('No recipe attached', style: TextStyle(color: wfMuted, fontWeight: FontWeight.w800)) else Wrap(spacing: 6, runSpacing: 6, children: items.take(4).map((p) => WfChip(label: '${p['product_group_name'] ?? 'Product'} • Qty ${p['required_quantity'] ?? 1}', color: '${p['product_type'] ?? ''}' == 'returnable' ? wfAmber : '${p['product_type'] ?? ''}' == 'semi_consumable' ? wfSuccess : wfTeal)).toList()), if (items.length > 4) ...[const SizedBox(height: 6), Text('+${items.length - 4} more product groups', style: const TextStyle(color: wfMuted, fontWeight: FontWeight.w800, fontSize: 12))]]))); } }

class _ProductRecipeCard extends StatelessWidget { const _ProductRecipeCard({required this.row}); final Map<String, dynamic> row; @override Widget build(BuildContext context) { final c = int.tryParse('${row['service_count'] ?? 0}') ?? 0; final s = '${row['service_summary'] ?? ''}'; final type = '${row['product_type'] ?? 'consumable'}'; return WfCard(child: Row(children: [WfIconBox(icon: Icons.inventory_2_rounded, color: type == 'returnable' ? wfAmber : type == 'semi_consumable' ? wfSuccess : wfTeal), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${row['product_group_name'] ?? 'Product Group'}', style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text('$type • Used by $c services', style: const TextStyle(color: wfMuted, fontWeight: FontWeight.w800, fontSize: 12)), if (s.isNotEmpty) ...[const SizedBox(height: 8), Text(s, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: wfDark, fontWeight: FontWeight.w700))]]))])); } }

class _BulkRecipeDialog extends StatefulWidget { const _BulkRecipeDialog({required this.api, required this.ref_, required this.categories, required this.services, required this.groups}); final WorkforceApi api; final WidgetRef ref_; final List<Map<String, dynamic>> categories, services, groups; @override State<_BulkRecipeDialog> createState() => _BulkRecipeDialogState(); }
class _BulkRecipeDialogState extends State<_BulkRecipeDialog> { final serviceSearch = TextEditingController(); final qty = TextEditingController(text: '1'); final selectedCategories = <String>{}; final excludedServices = <String>{}; final selectedGroups = <String>{}; bool required = true, saving = false; @override void dispose() { serviceSearch.dispose(); qty.dispose(); super.dispose(); } List<Map<String, dynamic>> get selectedCategoryServices { final q = serviceSearch.text.trim().toLowerCase(); return widget.services.where((s) { final c = '${s['category'] ?? s['service_type_id'] ?? ''}'; final n = '${s['name'] ?? ''}'.toLowerCase(); return selectedCategories.contains(c) && (q.isEmpty || n.contains(q)); }).toList(); } int get includedServiceCount => selectedCategoryServices.where((s) => !excludedServices.contains('${s['id']}')).length; Future<void> save() async { if (selectedCategories.isEmpty || includedServiceCount <= 0 || selectedGroups.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select categories, services and product groups'))); return; } setState(() => saving = true); try { await widget.api.post('/workforce/bulk_save_service_recipes.php', widget.ref_, {'service_type_ids': selectedCategories.join(','), 'excluded_service_ids': excludedServices.join(','), 'product_group_ids': selectedGroups.join(','), 'required_quantity': qty.text.trim(), 'is_required': required ? '1' : '0'}); if (mounted) Navigator.pop(context, true); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } if (mounted) setState(() => saving = false); }
  @override Widget build(BuildContext context) { final svs = selectedCategoryServices; return AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)), title: const Text('Bulk Create Service Recipes', style: TextStyle(color: wfDark, fontWeight: FontWeight.w900)), content: SizedBox(width: 1080, height: 680, child: Row(children: [Expanded(child: _Panel(title: '1. Categories', footer: '${selectedCategories.length} selected', child: ListView.builder(itemCount: widget.categories.length, itemBuilder: (_, i) { final it = widget.categories[i]; final id = '${it['id']}'; final count = widget.services.where((s) => '${s['category'] ?? s['service_type_id'] ?? ''}' == id).length; return CheckboxListTile(value: selectedCategories.contains(id), dense: true, activeColor: wfTeal, onChanged: (v) => setState(() { if (v == true) selectedCategories.add(id); else { selectedCategories.remove(id); for (final s in widget.services.where((s) => '${s['category'] ?? s['service_type_id'] ?? ''}' == id)) { excludedServices.remove('${s['id']}'); } } }), title: Text('${it['name'] ?? 'Category'}'), subtitle: Text('$count services')); }))), const SizedBox(width: 12), Expanded(child: _Panel(title: '2. Services', footer: '$includedServiceCount included', child: Column(children: [TextField(controller: serviceSearch, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: 'Search selected services', prefixIcon: const Icon(Icons.search_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))), const SizedBox(height: 8), Expanded(child: selectedCategories.isEmpty ? const Center(child: Text('Select a category to show services.', textAlign: TextAlign.center, style: TextStyle(color: wfMuted, fontWeight: FontWeight.w800))) : ListView.builder(itemCount: svs.length, itemBuilder: (_, i) { final it = svs[i]; final id = '${it['id']}'; return CheckboxListTile(value: !excludedServices.contains(id), dense: true, activeColor: wfTeal, onChanged: (v) => setState(() => v == true ? excludedServices.remove(id) : excludedServices.add(id)), title: Text('${it['name'] ?? 'Service'}', maxLines: 1, overflow: TextOverflow.ellipsis)); }))]))), const SizedBox(width: 12), Expanded(child: _Panel(title: '3. Product Groups', footer: '${selectedGroups.length} selected', child: Column(children: [Expanded(child: ListView.builder(itemCount: widget.groups.length, itemBuilder: (_, i) { final it = widget.groups[i]; final id = '${it['id']}'; return CheckboxListTile(value: selectedGroups.contains(id), dense: true, activeColor: wfTeal, onChanged: (v) => setState(() => v == true ? selectedGroups.add(id) : selectedGroups.remove(id)), title: Text('${it['name'] ?? 'Group'}'), subtitle: Text('${it['category_type'] ?? 'consumable'}')); })), const Divider(), WfTextField(controller: qty, label: 'Required Quantity', keyboardType: TextInputType.number), SwitchListTile(value: required, activeColor: wfTeal, onChanged: (v) => setState(() => required = v), title: const Text('Required before assignment'))])))])), actions: [TextButton(onPressed: saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton.icon(onPressed: saving ? null : save, icon: const Icon(Icons.save_rounded), label: Text(saving ? 'Saving...' : 'Create Recipes'))]); }}

class _EditServiceRecipeDialog extends StatefulWidget { const _EditServiceRecipeDialog({required this.api, required this.ref_, required this.service, required this.groups}); final WorkforceApi api; final WidgetRef ref_; final Map<String, dynamic> service; final List<Map<String, dynamic>> groups; @override State<_EditServiceRecipeDialog> createState() => _EditServiceRecipeDialogState(); }
class _EditServiceRecipeDialogState extends State<_EditServiceRecipeDialog> { bool loading = true, saving = false; List<Map<String, dynamic>> existing = []; final selectedGroups = <String>{}; final qtyByGroup = <String, TextEditingController>{}; final requiredByGroup = <String, bool>{}; int get serviceId => int.tryParse('${widget.service['service_id'] ?? 0}') ?? 0; @override void initState() { super.initState(); load(); } @override void dispose() { for (final c in qtyByGroup.values) { c.dispose(); } super.dispose(); } Future<void> load() async { setState(() => loading = true); try { final res = await widget.api.post('/workforce/service_recipe_detail.php', widget.ref_, {'service_id': '$serviceId'}); final raw = res['recipes'] ?? res['data'] ?? []; existing = raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : []; for (final g in widget.groups) { final id = '${g['id']}'; qtyByGroup[id] ??= TextEditingController(text: '1'); requiredByGroup[id] = true; } for (final it in existing) { final id = '${it['product_group_id'] ?? it['group_id'] ?? ''}'; if (id.isEmpty || id == '0') continue; selectedGroups.add(id); qtyByGroup[id] ??= TextEditingController(); qtyByGroup[id]!.text = '${it['required_quantity'] ?? 1}'; requiredByGroup[id] = '${it['is_required'] ?? 1}' == '1'; } } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } if (mounted) setState(() => loading = false); } Future<void> save() async { setState(() => saving = true); try { final payload = selectedGroups.map((id) => {'product_group_id': id, 'required_quantity': qtyByGroup[id]?.text.trim().isEmpty == true ? '1' : (qtyByGroup[id]?.text.trim() ?? '1'), 'is_required': requiredByGroup[id] == true ? '1' : '0'}).toList(); await widget.api.post('/workforce/update_service_recipe.php', widget.ref_, {'service_id': '$serviceId', 'recipes_json': jsonEncode(payload)}); if (mounted) Navigator.pop(context, true); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } if (mounted) setState(() => saving = false); }
  @override Widget build(BuildContext context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)), title: Text('Edit Recipe — ${widget.service['service_name'] ?? 'Service'}', style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900)), content: SizedBox(width: 760, height: 620, child: loading ? const Center(child: CircularProgressIndicator(color: wfTeal)) : Column(children: [WfCard(child: Row(children: [const WfIconBox(icon: Icons.spa_rounded, color: wfTeal), const SizedBox(width: 12), Expanded(child: Text('${widget.service['category_name'] ?? ''}', style: const TextStyle(color: wfMuted, fontWeight: FontWeight.w800))), WfChip(label: '${selectedGroups.length} groups', color: wfSuccess)])), const SizedBox(height: 10), Expanded(child: ListView.separated(itemCount: widget.groups.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) { final g = widget.groups[i]; final id = '${g['id']}'; final sel = selectedGroups.contains(id); qtyByGroup[id] ??= TextEditingController(text: '1'); requiredByGroup[id] ??= true; return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: sel ? const Color(0xffF7FBFC) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: sel ? wfTeal.withOpacity(.45) : wfLine)), child: Row(children: [Checkbox(value: sel, activeColor: wfTeal, onChanged: (v) => setState(() => v == true ? selectedGroups.add(id) : selectedGroups.remove(id))), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${g['name'] ?? 'Product Group'}', style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900)), Text('${g['category_type'] ?? 'consumable'}', style: const TextStyle(color: wfMuted, fontWeight: FontWeight.w700, fontSize: 12))])), SizedBox(width: 90, child: TextField(controller: qtyByGroup[id], enabled: sel, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Qty', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))), const SizedBox(width: 10), Column(children: [const Text('Required', style: TextStyle(color: wfMuted, fontSize: 11, fontWeight: FontWeight.w700)), Switch(value: requiredByGroup[id] == true, activeColor: wfTeal, onChanged: sel ? (v) => setState(() => requiredByGroup[id] = v) : null)])])); }))])), actions: [TextButton(onPressed: saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton.icon(onPressed: saving ? null : save, icon: const Icon(Icons.save_rounded), label: Text(saving ? 'Saving...' : 'Save Recipe'))]); }

class _Panel extends StatelessWidget { const _Panel({required this.title, required this.child, this.footer}); final String title; final Widget child; final String? footer; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xffF7FBFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: wfLine)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(title, style: const TextStyle(color: wfDark, fontWeight: FontWeight.w900))), if (footer != null) Text(footer!, style: const TextStyle(color: wfMuted, fontSize: 12, fontWeight: FontWeight.w800))]), const SizedBox(height: 10), Expanded(child: child)])); }
