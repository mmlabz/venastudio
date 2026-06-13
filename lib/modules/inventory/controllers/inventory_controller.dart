import 'dart:convert';

import 'package:venastudio/common.dart';
import '../models/inventory_models.dart';

final inventoryServicesProvider =
    StateNotifierProvider<InventoryNotifier, AsyncValue<InventoryStateData>>((
  ref,
) {
  final authService = ref.watch(authenticationServiceProvider);
  return InventoryNotifier(authService: authService);
});

class InventoryNotifier extends StateNotifier<AsyncValue<InventoryStateData>> {
  InventoryNotifier({required this.authService}) : super(const AsyncLoading()) {
    final now = DateTime.now();
    selectedStart = DateTime(now.year, now.month, now.day);
    selectedEnd = DateTime(now.year, now.month, now.day);
    init();
  }

  final AsyncValue<AuthData> authService;
  final _api = ApiProvider();

  DateTime selectedStart = DateTime.now();
  DateTime selectedEnd = DateTime.now();

  List<InventoryProduct> _cachedProducts = [];
  List<InventoryEmployee> _cachedEmployees = [];

  Map<String, dynamic>? get _activeAgent => LocalStorage.nosql.activeAgent;

  ServiceUser? get _loginUser {
    return authService.valueOrNull?.user ?? LocalStorage.nosql.user;
  }

  int get companyId {
    final fromAgent = int.tryParse(_activeAgent?['shop']?.toString() ?? '');
    if (fromAgent != null && fromAgent > 0) return fromAgent;

    final fromCurrentCompany = int.tryParse(
      LocalStorage.nosql.currentCompany?.companyId ?? '',
    );
    if (fromCurrentCompany != null && fromCurrentCompany > 0) {
      return fromCurrentCompany;
    }

    return int.tryParse(_loginUser?.shop ?? '0') ?? 0;
  }

  int get storeId {
    final fromAgent = int.tryParse(_activeAgent?['storeId']?.toString() ?? '');
    if (fromAgent != null && fromAgent > 0) return fromAgent;

    final fromUser = int.tryParse(_loginUser?.storeId ?? '0') ?? 0;
    if (fromUser > 0 && fromUser != companyId) return fromUser;

    return 0;
  }

  int get employeeId {
    final fromAgent = int.tryParse(_activeAgent?['id']?.toString() ?? '');
    if (fromAgent != null && fromAgent > 0) return fromAgent;

    return _loginUser?.id ?? 0;
  }

  String get userType {
    final fromAgent = _activeAgent?['type']?.toString();
    if (fromAgent != null && fromAgent.trim().isNotEmpty) {
      return normalizeUserType(fromAgent);
    }

    return normalizeUserType(_loginUser?.type);
  }

  bool get hasActiveBranchSession {
    return companyId > 0 && storeId > 0 && employeeId > 0;
  }

  bool get isEmployee => isEmployeeType(userType);

  bool get canOperate {
    return userType == FRONTOFFICE_TYPE_NAME ||
        userType == SUPERADMIN_TYPE_NAME;
  }

  Map<String, String> get _baseBody {
    return {
      'company_id': '$companyId',
      'store_id': '$storeId',
    };
  }

  Map<String, String> get _periodBody {
    return {
      'start_date': _apiDate(selectedStart),
      'end_date': _apiDate(selectedEnd),
    };
  }

  String get selectedPeriodLabel {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (_sameDate(selectedStart, todayDate) &&
        _sameDate(selectedEnd, todayDate)) {
      return 'Today';
    }

    if (_sameDate(selectedStart, selectedEnd)) {
      return _humanDate(selectedStart);
    }

    return '${_humanDate(selectedStart)} - ${_humanDate(selectedEnd)}';
  }

  Future<void> init() async {
    if (companyId <= 0) {
      state = AsyncError('Missing company session', StackTrace.current);
      return;
    }

    if (storeId <= 0 || employeeId <= 0) {
      state = AsyncError(
        'Missing inventory session values. Enter staff PIN first.',
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    try {
      final data = await _loadAll(forceStaticReload: true);
      if (mounted) state = AsyncData(data);
    } catch (e, st) {
      if (mounted) state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    if (companyId <= 0 || storeId <= 0 || employeeId <= 0) {
      await init();
      return;
    }

    try {
      final oldData = state.valueOrNull;

      if (oldData == null) {
        state = const AsyncLoading();
      }

      final data = await _loadAll(forceStaticReload: false);
      if (mounted) state = AsyncData(data);
    } catch (e, st) {
      if (mounted) state = AsyncError(e, st);
    }
  }

  Future<void> changePeriod({
    required DateTime start,
    required DateTime end,
  }) async {
    selectedStart = DateTime(start.year, start.month, start.day);
    selectedEnd = DateTime(end.year, end.month, end.day);

    await refresh();
  }

  Future<void> resetToToday() async {
    final now = DateTime.now();
    selectedStart = DateTime(now.year, now.month, now.day);
    selectedEnd = DateTime(now.year, now.month, now.day);

    await refresh();
  }

  Future<InventoryStateData> _loadAll({
    required bool forceStaticReload,
  }) async {
    if (isEmployee) {
      final results = await Future.wait([
        fetchIssues(issuedTo: employeeId),
        fetchReturns(returnedBy: employeeId),
      ]);

      return InventoryStateData(
        issues: results[0] as List<InventoryIssue>,
        returns: results[1] as List<InventoryReturnRecord>,
      );
    }

    if (_cachedProducts.isEmpty || forceStaticReload) {
      _cachedProducts = await fetchProducts();
    }

    if (_cachedEmployees.isEmpty || forceStaticReload) {
      _cachedEmployees = await fetchEmployees();
    }

    final results = await Future.wait([
      fetchIssues(),
      fetchRequests(),
      fetchReturns(),
    ]);

    return InventoryStateData(
      products: _cachedProducts,
      issues: results[0] as List<InventoryIssue>,
      requests: results[1] as List<InventoryRequest>,
      returns: results[2] as List<InventoryReturnRecord>,
      employees: _cachedEmployees,
    );
  }

  Future<List<InventoryProduct>> fetchProducts([String search = '']) async {
    final dynamic res = await _api.post(
      '/vena_stock/get_available_products.php',
      body: {
        ..._baseBody,
        'search': search,
      },
    );

    _assertOk(res);

    return List<Map<dynamic, dynamic>>.from(
      res['data'] ?? [],
    ).map(InventoryProduct.fromMap).toList();
  }

  Future<List<InventoryRequest>> fetchRequests() async {
    final dynamic res = await _api.post(
      '/vena_stock/get_requests.php',
      body: {
        ..._baseBody,
        ..._periodBody,
      },
    );

    _assertOk(res);

    return List<Map<dynamic, dynamic>>.from(
      res['data'] ?? [],
    ).map(InventoryRequest.fromMap).toList();
  }

  Future<List<InventoryIssue>> fetchIssues({int? issuedTo}) async {
    final dynamic res = await _api.post(
      '/vena_stock/get_issued_products.php',
      body: {
        ..._baseBody,
        ..._periodBody,
        if ((issuedTo ?? 0) > 0) 'issued_to': '${issuedTo!}',
      },
    );

    _assertOk(res);

    return List<Map<dynamic, dynamic>>.from(
      res['data'] ?? [],
    ).map(InventoryIssue.fromMap).toList();
  }

  Future<List<InventoryReturnRecord>> fetchReturns({int? returnedBy}) async {
    final dynamic res = await _api.post(
      '/vena_stock/get_returned_products.php',
      body: {
        ..._baseBody,
        ..._periodBody,
        if ((returnedBy ?? 0) > 0) 'returned_by': '${returnedBy!}',
      },
    );

    _assertOk(res);

    return List<Map<dynamic, dynamic>>.from(
      res['data'] ?? [],
    ).map(InventoryReturnRecord.fromMap).toList();
  }

  Future<List<InventoryEmployee>> fetchEmployees() async {
    final dynamic res = await _api.post(
      '/vena_stock/get_inventory_employees.php',
      body: _baseBody,
    );

    _assertOk(res);

    return List<Map<dynamic, dynamic>>.from(
      res['data'] ?? [],
    ).map(InventoryEmployee.fromMap).toList();
  }

  Future<void> createRequest({
    required InventoryProduct product,
    required double qty,
    String notes = '',
  }) async {
    if (!canOperate) {
      throw 'You are not allowed to request inventory items';
    }

    final dynamic res = await _api.post(
      '/vena_stock/create_stock_request.php',
      body: {
        ..._baseBody,
        'requested_by': '$employeeId',
        'notes': notes,
        'items': jsonEncode([
          {
            'product_id': product.id,
            'qty_requested': qty,
            'notes': notes,
          },
        ]),
      },
    );

    _assertOk(res);
    await refresh();
  }

  Future<void> issueProduct({
    required InventoryProduct product,
    required int issuedTo,
    required double qty,
    String notes = '',
  }) async {
    if (!canOperate) {
      throw 'You are not allowed to issue inventory items';
    }

    final dynamic res = await _api.post(
      '/vena_stock/create_issue.php',
      body: {
        ..._baseBody,
        'issued_by': '$employeeId',
        'issued_to': '$issuedTo',
        'notes': notes,
        'items': jsonEncode([
          {
            'product_id': product.id,
            'qty_issued': qty,
            'tracking_type': product.trackingType,
            'notes': notes,
          },
        ]),
      },
    );

    _assertOk(res);
    await refresh();
  }

  Future<void> returnIssue({
    required InventoryIssue issue,
    required double qty,
    required String conditionStatus,
    String notes = '',
  }) async {
    if (!canOperate) {
      throw 'You are not allowed to process returns';
    }

    final dynamic res = await _api.post(
      '/vena_stock/create_return.php',
      body: {
        ..._baseBody,
        'issue_id': '${issue.issueId}',
        'returned_by': '${issue.issuedTo}',
        'received_by': '$employeeId',
        'notes': notes,
        'items': jsonEncode([
          {
            'product_id': issue.productId,
            'qty_returned': qty,
            'condition_status': conditionStatus,
            'notes': notes,
          },
        ]),
      },
    );

    _assertOk(res);
    await refresh();
  }

  void clearStaticCache() {
    _cachedProducts = [];
    _cachedEmployees = [];
  }

  void _assertOk(dynamic res) {
    if (res is! Map) {
      throw 'Invalid inventory response';
    }

    final ok = res['success'] == true || res['status'] == 1;

    if (!ok) {
      throw res['message']?.toString() ?? 'Inventory action failed';
    }
  }

  String _apiDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }

  String _humanDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();

    return '$d/$m/$y';
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
