import 'dart:convert';

import 'package:venastudio/common.dart';

import 'smart_service_assignment.dart';

class SmartAssignmentBridge {
  const SmartAssignmentBridge._();

  /// Open the smart assignment dialog whenever any control layer is ON.
  /// Stock, Attendance, and Queue are independent controls.
  ///
  /// Previously this opened only when stock tracking was ON, which meant
  /// checkout could still show the raw agent picker when Queue was ON.
  /// That allowed busy staff to look selectable in the UI.
  static bool enabled(SettingsConfig settings) =>
      settings.trackStock || settings.trackAttendance || settings.trackQueue;

  static bool trackStock(SettingsConfig settings) {
    return settings.trackStock;
  }

  static bool enforceAttendance(SettingsConfig settings) {
    return settings.trackAttendance;
  }

  static bool enforceQueue(SettingsConfig settings) {
    return settings.trackQueue;
  }

  static Savis savisFromDynamic(
    dynamic raw, {
    String fallbackName = 'Service',
    num fallbackAmount = 0,
  }) {
    if (raw is Savis) return raw;

    int id = 0;
    String name = fallbackName;
    num amount = fallbackAmount;
    num quantity = 1;
    String type = 'Service';

    if (raw is Map) {
      id = int.tryParse(
            '${raw['service_id'] ?? raw['serviceId'] ?? raw['savis_id'] ?? raw['savisId'] ?? raw['cart_service_id'] ?? raw['cartServiceId'] ?? raw['id'] ?? raw['cartid'] ?? 0}',
          ) ??
          0;
      name =
          '${raw['service_name'] ?? raw['serviceName'] ?? raw['name'] ?? raw['savis_name'] ?? raw['title'] ?? fallbackName}';
      amount = num.tryParse(
            '${raw['amount'] ?? raw['price'] ?? raw['total'] ?? fallbackAmount}',
          ) ??
          fallbackAmount;
      quantity = num.tryParse('${raw['quantity'] ?? raw['items'] ?? 1}') ?? 1;
      type = '${raw['type'] ?? 'Service'}';
    } else {
      try {
        id =
            int.tryParse('${raw.serviceId ?? raw.service_id ?? raw.id ?? 0}') ??
                0;
      } catch (_) {}
      try {
        name =
            '${raw.serviceName ?? raw.service_name ?? raw.name ?? fallbackName}';
      } catch (_) {}
      try {
        amount = num.tryParse('${raw.amount ?? raw.price ?? fallbackAmount}') ??
            fallbackAmount;
      } catch (_) {}
      try {
        quantity = num.tryParse('${raw.quantity ?? raw.items ?? 1}') ?? 1;
      } catch (_) {}
      try {
        type = '${raw.type ?? 'Service'}';
      } catch (_) {}
    }

    return Savis(
      id: id,
      name: name,
      amount: amount,
      hours: 0,
      minutes: 0,
      quantity: quantity,
      type: type,
      discount: '0',
    );
  }

  static Future<SmartServiceAssignmentResult?> pickResult(
    BuildContext context, {
    required SettingsConfig settings,
    required List<Agent> agents,
    required dynamic serviceLike,
    String orderNo = '',
    String cartId = '',
    bool existingOrderMode = true,
  }) async {
    final activeAgents = agents.where((a) => !a.archived).toList();
    final savis = savisFromDynamic(serviceLike);

    if (enabled(settings) && savis.id > 0) {
      return SmartServiceAssignmentDialog.show(
        context,
        savis: savis,
        fallbackAgents: activeAgents,
        orderNo: orderNo,
        cartId: cartId,
        existingOrderMode: existingOrderMode,
        trackStock: trackStock(settings),
        enforceAttendance: enforceAttendance(settings),
        enforceQueue: enforceQueue(settings),
      );
    }

    final agent = await PickAgent.show(context, activeAgents);
    if (agent == null) return null;

    return SmartServiceAssignmentResult(
      savis: savis,
      agent: agent,
      payload: const {},
    );
  }

  static Future<Agent?> pickAgent(
    BuildContext context, {
    required SettingsConfig settings,
    required List<Agent> agents,
    required dynamic serviceLike,
    String orderNo = '',
    String cartId = '',
    bool existingOrderMode = true,
  }) async {
    final result = await pickResult(
      context,
      settings: settings,
      agents: agents,
      serviceLike: serviceLike,
      orderNo: orderNo,
      cartId: cartId,
      existingOrderMode: existingOrderMode,
    );

    return result?.agent;
  }

  static MapEntry<String, Map<String, String>> entry(dynamic value) {
    String serviceId = '';
    String agentName = '';
    String agentId = '';
    String smartAssignment = '';

    try {
      serviceId = '${value.savis.id}';
    } catch (_) {}

    try {
      agentName = '${value.agent.name}';
      agentId = '${value.agent.id}';
    } catch (_) {}

    try {
      final cartMap = value.toCartMap();
      if (cartMap is Map) {
        agentName = '${cartMap['agentName'] ?? agentName}';
        agentId = '${cartMap['agentId'] ?? agentId}';
        smartAssignment = '${cartMap['smartAssignment'] ?? ''}';
      }
    } catch (_) {}

    if (serviceId.isEmpty) {
      throw Exception('Unable to identify service being assigned');
    }

    if (agentId.isEmpty || agentName.isEmpty) {
      throw Exception('Unable to identify selected beautician');
    }

    return MapEntry(serviceId, {
      'agentName': agentName,
      'agentId': agentId,
      if (smartAssignment.isNotEmpty) 'smartAssignment': smartAssignment,
    });
  }
}

class SmartServiceAssignmentDialog extends ConsumerStatefulWidget {
  const SmartServiceAssignmentDialog({
    super.key,
    required this.savis,
    required this.fallbackAgents,
    this.orderNo = '',
    this.cartId = '',
    this.existingOrderMode = false,
    this.trackStock = false,
    this.enforceAttendance = false,
    this.enforceQueue = false,
  });

  final Savis savis;
  final List<Agent> fallbackAgents;
  final String orderNo;
  final String cartId;
  final bool existingOrderMode;
  final bool trackStock;
  final bool enforceAttendance;
  final bool enforceQueue;

  static Future<SmartServiceAssignmentResult?> show(
    BuildContext context, {
    required Savis savis,
    required List<Agent> fallbackAgents,
    String orderNo = '',
    String cartId = '',
    bool existingOrderMode = false,
    bool trackStock = false,
    bool enforceAttendance = false,
    bool enforceQueue = false,
  }) {
    return showDialog<SmartServiceAssignmentResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SmartServiceAssignmentDialog(
        savis: savis,
        fallbackAgents: fallbackAgents,
        orderNo: orderNo,
        cartId: cartId,
        existingOrderMode: existingOrderMode,
        trackStock: trackStock,
        enforceAttendance: enforceAttendance,
        enforceQueue: enforceQueue,
      ),
    );
  }

  @override
  ConsumerState<SmartServiceAssignmentDialog> createState() =>
      _SmartServiceAssignmentDialogState();
}

class _SmartServiceAssignmentDialogState
    extends ConsumerState<SmartServiceAssignmentDialog> {
  final api = ApiProvider();

  bool loading = true;
  bool loadingProducts = false;
  bool savingSkip = false;

  List<Map<String, dynamic>> candidates = [];
  List<Map<String, dynamic>> recipeProducts = [];
  Map<String, dynamic>? selectedCandidate;

  final selectedProductIds = <String, String>{};
  final qtyControllers = <String, TextEditingController>{};
  final conditionControllers = <String, TextEditingController>{};

  int get serviceId => int.tryParse('${widget.savis.id}') ?? 0;
  String get serviceName => widget.savis.name;

  ServiceUser? get user {
    final activeAgent = LocalStorage.nosql.activeAgent;
    if (activeAgent != null) return ServiceUser.fromMap(activeAgent);
    return ref.read(authenticationServiceProvider).valueOrNull?.user ??
        LocalStorage.nosql.user;
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    for (final c in qtyControllers.values) {
      c.dispose();
    }
    for (final c in conditionControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> baseBody([Map<String, dynamic>? extra]) {
    final u = user;
    return {
      'company_id': '${u?.shop ?? ''}',
      'shop': '${u?.shop ?? ''}',
      'store_id': '${u?.storeName ?? ''}',
      'store': '${u?.storeName ?? ''}',
      'user_id': '${u?.id ?? ''}',
      ...?extra?.map((key, value) => MapEntry(key, '$value')),
    };
  }

  Agent agentFromCandidate(Map<String, dynamic> row) {
    final id = num.tryParse('${row['id'] ?? row['employee_id'] ?? 0}') ?? 0;

    return Agent(
      id: id,
      name:
          '${row['name'] ?? row['employee_name'] ?? row['staff_name'] ?? 'Staff'}',
      email: '${row['email'] ?? row['employee_email'] ?? ''}',
      phone: '${row['phone'] ?? row['employee_phone'] ?? ''}',
      archived: false,
      pin: num.tryParse('${row['pin'] ?? 0}') ?? 0,
      commission: num.tryParse('${row['commission'] ?? 0}') ?? 0,
      shop: num.tryParse('${row['company_id'] ?? user?.shop ?? 0}') ?? 0,
      userID: num.tryParse('${row['user_id'] ?? 0}') ?? 0,
      type: '${row['user_role'] ?? row['type'] ?? 'user'}',
      store:
          '${row['store_id'] ?? row['employee_store_id'] ?? row['store'] ?? user?.storeName ?? ''}',
    );
  }

  bool _truthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final v = '$value'.toLowerCase().trim();

    return v == '1' ||
        v == 'true' ||
        v == 'yes' ||
        v == 'y' ||
        v == 'checked_in' ||
        v == 'available' ||
        v == 'eligible' ||
        v == 'skilled';
  }

  bool _checkedIn(Map<String, dynamic> c) {
    return _truthy(c['checked_in']) ||
        '${c['attendance_status'] ?? ''}'.toLowerCase().trim() ==
            'checked_in';
  }

  bool _hasSkill(Map<String, dynamic> c) {
    return _truthy(c['exact_skill']) ||
        _truthy(c['has_skill']) ||
        _truthy(c['category_skill']);
  }

  bool _isAvailable(Map<String, dynamic> c) {
    final availability = '${c['availability_status'] ?? ''}'.toLowerCase();
    return availability == 'available' ||
        availability == 'online' ||
        _truthy(c['available_for_assignment']);
  }

  String _candidateName(Map<String, dynamic> c) {
    return '${c['name'] ?? c['employee_name'] ?? c['staff_name'] ?? 'Staff'}';
  }

  Map<String, dynamic> _normalizeCandidate(Map<String, dynamic> c) {
    final row = Map<String, dynamic>.from(c);

    row['id'] = row['id'] ?? row['employee_id'];
    row['name'] = row['name'] ?? row['employee_name'] ?? row['staff_name'];
    row['phone'] = row['phone'] ?? row['employee_phone'];
    row['email'] = row['email'] ?? row['employee_email'];
    row['store_id'] =
        row['store_id'] ?? row['employee_store_id'] ?? row['employee_store'];
    row['checked_in'] = _checkedIn(row) ? 1 : 0;
    row['has_skill'] = _hasSkill(row) ? 1 : 0;

    final canAssign = _truthy(row['can_assign']) ||
        _truthy(row['eligible']) ||
        _truthy(row['available_for_assignment']);

    row['can_assign'] = canAssign ? 1 : 0;
    row['eligible'] = canAssign ? 1 : 0;
    row['available_for_assignment'] = canAssign ? 1 : 0;

    if ('${row['disabled_reason'] ?? ''}'.trim().isEmpty &&
        '${row['ineligible_reason'] ?? ''}'.trim().isNotEmpty) {
      row['disabled_reason'] = row['ineligible_reason'];
    }

    return row;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  String _humanTime(dynamic value) {
    final raw = '$value'.trim();
    if (raw.isEmpty || raw == 'null') return '';

    DateTime? dt = DateTime.tryParse(raw);
    if (dt == null && raw.contains(' ')) {
      dt = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    }

    if (dt == null) return raw;

    var hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;

    return '$hour:$minute $suffix';
  }

  bool canAssignCandidate(Map<String, dynamic>? candidate) {
    if (candidate == null) return false;

    return _truthy(candidate['can_assign']) ||
        _truthy(candidate['eligible']) ||
        _truthy(candidate['available_for_assignment']);
  }

  bool canSkipCandidate(Map<String, dynamic> candidate) {
    return _truthy(candidate['can_skip']);
  }

  Map<String, dynamic>? _firstAssignableCandidate() {
    for (final c in candidates) {
      if (canAssignCandidate(c)) return c;
    }
    return null;
  }

  String candidateStatus(Map<String, dynamic> c) {
    final message =
        '${c['disabled_message'] ?? c['eligibility_message'] ?? ''}'.trim();
    final label =
        '${c['disabled_label'] ?? c['badge'] ?? c['ineligible_reason'] ?? ''}'
            .trim();

    if (canAssignCandidate(c)) {
      final queue = '${c['queue_position'] ?? ''}'.trim();
      if (queue.isNotEmpty && queue != 'null' && queue != '0') {
        return '#$queue in queue and ready for assignment';
      }
      return 'Ready for assignment';
    }

    if (message.isNotEmpty && message != 'null') return message;
    if (label.isNotEmpty && label != 'null') return label;

    if (_hasSkill(c) && widget.enforceAttendance && !_checkedIn(c)) {
      return 'Waiting for check-in';
    }

    return 'Not eligible';
  }

  Color queueBadgeColor(Map<String, dynamic> c) {
    final queue = int.tryParse('${c['queue_position'] ?? 999}') ?? 999;
    if (queue == 1 && canAssignCandidate(c)) return const Color(0xff19B37A);
    if (queue > 1 && queue < 999) return const Color(0xffF4A62A);
    return candidateColor(c);
  }

  Color candidateColor(Map<String, dynamic> c) {
    final skilled = _hasSkill(c);
    final checkedIn = _checkedIn(c);
    final disabledReason = '${c['disabled_reason'] ?? ''}'.toLowerCase();

    if (canAssignCandidate(c)) return const Color(0xff00BFD8);
    if (disabledReason == 'busy') return const Color(0xffF07070);
    if (disabledReason == 'not_checked_in' || (skilled && !checkedIn)) {
      return const Color(0xffF4A62A);
    }
    if (disabledReason == 'not_skilled' || !skilled) {
      return const Color(0xff8E44AD);
    }
    return const Color(0xff6B8794);
  }

  bool get hasInsufficientStock {
    for (final item in recipeProducts) {
      final key = _recipeKey(item);
      final selectedId = selectedProductIds[key] ?? '';
      final qtyNeeded = _toDouble(
          qtyControllers[key]?.text.trim().isEmpty == true
              ? item['required_quantity']
              : qtyControllers[key]?.text.trim());

      final products = item['products'] is List
          ? (item['products'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      if ('${item['is_required'] ?? 1}' == '1' && selectedId.isEmpty) {
        return true;
      }

      if (selectedId.isEmpty) continue;

      final selected = products.firstWhere(
        (p) => '${p['id']}' == selectedId,
        orElse: () => <String, dynamic>{},
      );

      final available = _toDouble(selected['available_qty'] ?? selected['qty']);
      if (qtyNeeded > available) return true;
    }
    return false;
  }

  bool get canSubmitAssignment {
    return canAssignCandidate(selectedCandidate) && !hasInsufficientStock;
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      debugPrint(
        'Attendance=${widget.enforceAttendance} Queue=${widget.enforceQueue}',
      );
      final res = await api.post(
        '/workforce/smart_assignment_candidates.php',
        body: baseBody({
          'service_id': serviceId,
          'order_no': widget.orderNo,
          'cart_id': widget.cartId,
          'enforce_attendance': widget.enforceAttendance ? '1' : '0',
          'enforce_queue': widget.enforceQueue ? '1' : '0',
        }),
      );

      List<dynamic> raw = [];

      if (res is Map) {
        final data = res['data'];

        final available = res['available'] ??
            res['candidates'] ??
            (data is Map ? data['available'] ?? data['candidates'] : null);

        final unavailable = res['unavailable'] ??
            res['disabled'] ??
            (data is Map ? data['unavailable'] ?? data['disabled'] : null);

        final items = res['items'] ?? (data is Map ? data['items'] : null);

        if (available is List || unavailable is List) {
          raw = [
            if (available is List) ...available,
            if (unavailable is List) ...unavailable,
          ];
        } else if (items is List) {
          raw = items;
        } else if (data is List) {
          raw = data;
        }
      }

      candidates = raw
          .whereType<Map>()
          .map((e) => _normalizeCandidate(Map<String, dynamic>.from(e)))
          .toList();

      if (candidates.isEmpty) {
        candidates = widget.fallbackAgents
            .where((a) => !a.archived)
            .map((a) => _normalizeCandidate({
                  'id': a.id,
                  'name': a.name,
                  'phone': a.phone,
                  'company_id': a.shop,
                  'store_id': a.store ?? '',
                  'is_fallback': 1,
                  'queue_position': 999,
                  'availability_status': 'unknown',
                  'busy_status': 'unknown',
                  'checked_in': 0,
                  'has_skill': 0,
                  'disabled_reason': 'fallback',
                  'disabled_message':
                      'Fallback agent list. Smart assignment rules did not return this staff member.',
                  'skill_level': 'unverified',
                }))
            .toList();
      }

      selectedCandidate = _firstAssignableCandidate();
      if (widget.trackStock) {
        await loadRecipeProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> loadRecipeProducts() async {
    setState(() => loadingProducts = true);
    try {
      final res = await api.post(
        '/workforce/service_assignment_recipe_options.php',
        body: baseBody({'service_id': serviceId}),
      );
      final raw = res is Map ? (res['products'] ?? res['data'] ?? []) : [];
      if (raw is List) {
        recipeProducts = raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      for (final item in recipeProducts) {
        final key = _recipeKey(item);
        qtyControllers[key] ??= TextEditingController(
          text: '${item['required_quantity'] ?? 1}',
        );
        conditionControllers[key] ??= TextEditingController(text: 'good');
        if ((item['products'] is List) &&
            (item['products'] as List).isNotEmpty) {
          final first = (item['products'] as List).first;
          if (first is Map) selectedProductIds[key] = '${first['id']}';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
    if (mounted) setState(() => loadingProducts = false);
  }

  String _recipeKey(Map<String, dynamic> item) {
    return '${item['recipe_id'] ?? item['product_group_id'] ?? item['group_id']}';
  }

  Future<void> skipCandidate(Map<String, dynamic> candidate) async {
    final reason = await _SkipReasonDialog.show(context);
    if (reason == null || reason.trim().isEmpty) return;

    setState(() => savingSkip = true);
    try {
      await api.post(
        '/workforce/smart_assignment_skip.php',
        body: baseBody({
          'service_id': serviceId,
          'order_no': widget.orderNo,
          'cart_id': widget.cartId,
          'employee_id': '${candidate['id'] ?? candidate['employee_id']}',
          'reason': reason.trim(),
        }),
      );
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
    if (mounted) setState(() => savingSkip = false);
  }

  List<Map<String, dynamic>> selectedProductPayload() {
    final out = <Map<String, dynamic>>[];

    for (final item in recipeProducts) {
      final key = _recipeKey(item);
      final selectedProductId = selectedProductIds[key] ?? '';
      final required = '${item['is_required'] ?? 1}' == '1';

      if (required && selectedProductId.isEmpty) {
        throw Exception(
          'Select product for ${item['product_group_name'] ?? 'recipe item'}',
        );
      }

      if (selectedProductId.isEmpty) continue;

      out.add({
        'recipe_id': '${item['recipe_id'] ?? ''}',
        'product_group_id':
            '${item['product_group_id'] ?? item['group_id'] ?? ''}',
        'product_group_name': '${item['product_group_name'] ?? ''}',
        'product_id': selectedProductId,
        'quantity': qtyControllers[key]?.text.trim().isEmpty == true
            ? '1'
            : (qtyControllers[key]?.text.trim() ?? '1'),
        'product_type':
            '${item['product_type'] ?? item['category_type'] ?? 'consumable'}',
        'condition_issued':
            conditionControllers[key]?.text.trim().isEmpty == true
                ? 'good'
                : (conditionControllers[key]?.text.trim() ?? 'good'),
        'is_required': required ? '1' : '0',
      });
    }
    return out;
  }

  void assign() {
    final candidate = selectedCandidate;

    if (candidate == null || !canAssignCandidate(candidate)) {
      final reason = candidate == null
          ? 'Select an eligible beautician first'
          : candidateStatus(candidate);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reason)),
      );
      return;
    }

    if (hasInsufficientStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('One or more products have insufficient stock')),
      );
      return;
    }

    try {
      final products = selectedProductPayload();
      final agent = agentFromCandidate(candidate);
      final payload = {
        'service_id': '$serviceId',
        'service_name': serviceName,
        'cart_service_id': '${widget.savis.id}',
        'employee_id': '${agent.id}',
        'employee_name': agent.name,
        'track_stock': widget.trackStock ? '1' : '0',
        'enforce_attendance': widget.enforceAttendance ? '1' : '0',
        'enforce_queue': widget.enforceQueue ? '1' : '0',
        'queue_position': '${candidate['queue_position'] ?? ''}',
        'checked_in': '${candidate['checked_in'] ?? ''}',
        'availability_status': '${candidate['availability_status'] ?? ''}',
        'busy_status': '${candidate['busy_status'] ?? ''}',
        'products': products,
        'products_json': jsonEncode(products),
        'order_no': widget.orderNo,
        'cart_id': widget.cartId,
        'existing_order_mode': widget.existingOrderMode ? '1' : '0',
      };

      Navigator.pop(
        context,
        SmartServiceAssignmentResult(
          savis: widget.savis,
          agent: agent,
          payload: payload,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = <String>[
      if (widget.trackStock) 'Stock',
      if (widget.enforceAttendance) 'Attendance',
      if (widget.enforceQueue) 'Queue',
    ];
    final modeText = mode.isEmpty ? 'Assignment' : mode.join(' + ');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      title: Text(
        'Assign $serviceName',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 1040,
        height: 680,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : widget.trackStock
                ? Row(
                    children: [
                      Expanded(child: _candidatePanel(modeText)),
                      const SizedBox(width: 12),
                      Expanded(child: _stockPanel()),
                    ],
                  )
                : _candidatePanel(modeText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: canSubmitAssignment ? assign : null,
          icon: Icon(widget.trackStock
              ? Icons.inventory_2_rounded
              : Icons.person_add_alt_1_rounded),
          label: Text(widget.trackStock && recipeProducts.isNotEmpty
              ? 'Issue Items & Assign Service'
              : 'Assign Service'),
        ),
      ],
    );
  }

  Widget _candidatePanel(String mode) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF7FBFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffCFEFF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Beauticians • $mode',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Only checked-in, available and skilled beauticians can be assigned.',
            style: TextStyle(
              color: Color(0xff6B8794),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: candidates.isEmpty
                ? const Center(child: Text('No beauticians found'))
                : ListView.separated(
                    itemCount: candidates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final c = candidates[index];

                      final id = '${c['id'] ?? c['employee_id']}';
                      final selected = selectedCandidate != null &&
                          '${selectedCandidate!['id'] ?? selectedCandidate!['employee_id']}' ==
                              id;

                      final checkedIn = _checkedIn(c);
                      final hasSkill = _hasSkill(c);
                      final categorySkill = _truthy(c['category_skill']);
                      final canAssign = canAssignCandidate(c);
                      final canSkip = canSkipCandidate(c);

                      final availability =
                          '${c['availability_status'] ?? 'offline'}'
                              .toLowerCase();
                      final busy = availability == 'busy' ||
                          '${c['busy_status'] ?? ''}'.toLowerCase() == 'busy';
                      final isAvailable = _isAvailable(c);

                      final color = candidateColor(c);
                      final queue = '${c['queue_position'] ?? index + 1}';

                      final checkinTime = '${c['checkin_time'] ?? ''}'.trim();
                      final prettyCheckin = _humanTime(checkinTime);

                      final attendanceText = checkedIn
                          ? (widget.enforceQueue && prettyCheckin.isNotEmpty
                              ? 'Arrived $prettyCheckin'
                              : 'Checked in')
                          : widget.enforceAttendance
                              ? 'Not checked in — blocked'
                              : 'Not checked in';

                      final availabilityText =
                          widget.enforceAttendance && !checkedIn
                              ? 'Unavailable until check-in'
                              : busy
                                  ? 'Busy'
                                  : isAvailable
                                      ? 'Available'
                                      : 'Unavailable';

                      final skillText = hasSkill
                          ? '${c['skill_level'] ?? 'Skilled'}'
                          : categorySkill
                              ? 'Category skill only'
                              : 'Missing service skill';

                      return InkWell(
                        onTap: canAssign
                            ? () => setState(() => selectedCandidate = c)
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        child: Opacity(
                          opacity: canAssign || hasSkill ? 1 : .65,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white
                                  : canAssign
                                      ? Colors.white.withOpacity(.88)
                                      : const Color(0xffFFFDFD),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xff00BFD8)
                                    : color.withOpacity(.55),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: queueBadgeColor(c).withOpacity(.16),
                                  child: Text(
                                    queue == '999' ? '#999' : '#$queue',
                                    style: TextStyle(
                                      color: queueBadgeColor(c),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _candidateName(c),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          if (selected)
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              size: 18,
                                              color: Color(0xff00BFD8),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '$attendanceText • $availabilityText • $skillText',
                                        style: const TextStyle(
                                          color: Color(0xff6B8794),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        candidateStatus(c),
                                        style: TextStyle(
                                          color: canAssign
                                              ? const Color(0xff19B37A)
                                              : color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.enforceQueue)
                                  TextButton(
                                    onPressed: savingSkip || !canSkip
                                        ? null
                                        : () => skipCandidate(c),
                                    child: const Text('Skip'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _recipeStockWarning(Map<String, dynamic> item) {
    final key = _recipeKey(item);
    final selectedId = selectedProductIds[key] ?? '';
    if (selectedId.isEmpty && '${item['is_required'] ?? 1}' == '1') {
      return 'Select a product to issue';
    }

    final products = item['products'] is List
        ? (item['products'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    final selected = products.firstWhere(
      (p) => '${p['id']}' == selectedId,
      orElse: () => <String, dynamic>{},
    );

    if (selected.isEmpty) return '';

    final available = _toDouble(selected['available_qty'] ?? selected['qty']);
    final needed = _toDouble(qtyControllers[key]?.text.trim().isEmpty == true
        ? item['required_quantity']
        : qtyControllers[key]?.text.trim());

    if (needed > available) {
      return 'Insufficient stock: required ${needed.toStringAsFixed(2)}, available ${available.toStringAsFixed(2)}';
    }

    return '';
  }

  Widget _productIssueSummary() {
    if (recipeProducts.isEmpty) return const SizedBox.shrink();

    var totalGroups = 0;
    var insufficient = 0;

    for (final item in recipeProducts) {
      totalGroups++;
      final warning = _recipeStockWarning(item).toLowerCase();
      if (warning.isNotEmpty && !warning.contains('select')) {
        insufficient++;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: insufficient > 0
            ? const Color(0xffFFF3E7)
            : const Color(0xffECFFF7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: insufficient > 0
              ? const Color(0xffF4A62A)
              : const Color(0xff19B37A),
        ),
      ),
      child: Text(
        insufficient > 0
            ? '$insufficient stock issue(s) need attention before sending.'
            : '$totalGroups product group(s) ready. Assignment will be sent as pending receipt.',
        style: TextStyle(
          color: insufficient > 0
              ? const Color(0xffB36B00)
              : const Color(0xff087A50),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _stockPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF7FBFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffCFEFF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Products to Issue',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          _productIssueSummary(),
          const SizedBox(height: 8),
          Expanded(
            child: loadingProducts
                ? const Center(child: CircularProgressIndicator())
                : recipeProducts.isEmpty
                    ? const Center(
                        child: Text(
                          'No recipe products found for this service.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: recipeProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final item = recipeProducts[index];
                          final key = _recipeKey(item);
                          final products = item['products'] is List
                              ? (item['products'] as List)
                                  .whereType<Map>()
                                  .map((e) => Map<String, dynamic>.from(e))
                                  .toList()
                              : <Map<String, dynamic>>[];

                          qtyControllers[key] ??= TextEditingController(
                            text: '${item['required_quantity'] ?? 1}',
                          );
                          conditionControllers[key] ??=
                              TextEditingController(text: 'good');

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xffCFEFF4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item['product_group_name'] ?? 'Product Group'}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  '${item['product_type'] ?? 'consumable'} • Required Qty ${item['required_quantity'] ?? 1}',
                                  style: const TextStyle(
                                    color: Color(0xff6B8794),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: selectedProductIds[key],
                                  decoration: InputDecoration(
                                    labelText: 'Specific product to issue',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  items: products.map((p) {
                                    final available = _toDouble(
                                        p['available_qty'] ?? p['qty']);
                                    return DropdownMenuItem(
                                      value: '${p['id']}',
                                      child: Text(
                                        '${p['name'] ?? p['product_name'] ?? 'Product'} • Avail ${available.toStringAsFixed(2)}',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() =>
                                        selectedProductIds[key] = value ?? '');
                                  },
                                ),
                                if (_recipeStockWarning(item).isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _recipeStockWarning(item),
                                    style: const TextStyle(
                                      color: Color(0xffF07070),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: qtyControllers[key],
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Qty',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: conditionControllers[key],
                                        decoration: InputDecoration(
                                          labelText: 'Condition issued',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SkipReasonDialog extends StatefulWidget {
  const _SkipReasonDialog();

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const _SkipReasonDialog(),
    );
  }

  @override
  State<_SkipReasonDialog> createState() => _SkipReasonDialogState();
}

class _SkipReasonDialogState extends State<_SkipReasonDialog> {
  final reason = TextEditingController();

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Reason for skipping'),
      content: TextField(
        controller: reason,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Example: Customer requested another beautician',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, reason.text.trim()),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
