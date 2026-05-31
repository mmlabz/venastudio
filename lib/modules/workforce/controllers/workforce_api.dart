import 'package:venastudio/common.dart';

class WfCtx {
  const WfCtx(
      {required this.companyId,
      required this.storeId,
      this.userId = '',
      this.userType = ''});
  final String companyId;
  final String storeId;
  final String userId;
  final String userType;
}

class WorkforceApi {
  WorkforceApi();
  final ApiProvider _api = ApiProvider();

  ServiceUser? currentUser(WidgetRef ref) {
    final active = LocalStorage.nosql.activeAgent;
    if (active != null) return ServiceUser.fromMap(active);
    return ref.read(authenticationServiceProvider).valueOrNull?.user ??
        LocalStorage.nosql.user;
  }

  WfCtx ctx(WidgetRef ref) {
    final user = currentUser(ref);
    return WfCtx(
      companyId: '${user?.shop ?? ''}',
      storeId: '${user?.storeName ?? ''}',
      userId: '${user?.id ?? ''}',
      userType: '${user?.type ?? ''}',
    );
  }

  Map<String, String> payload(WidgetRef ref, [Map<String, dynamic>? extra]) {
    final c = ctx(ref);
    return {
      'company_id': c.companyId,
      'store_id': c.storeId,
      'store': c.storeId,
      ...?extra?.map((k, v) => MapEntry(k, '$v')),
    };
  }

  Future<Map<String, dynamic>> post(String path, WidgetRef ref,
      [Map<String, dynamic>? body]) async {
    final res = await _api.post(path, body: payload(ref, body));
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'success': false, 'message': '$res'};
  }

  List<Map<String, dynamic>> listFrom(Map<String, dynamic> res, String key) {
    final raw = res[key];
    if (raw is List)
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> teams(WidgetRef ref) async =>
      listFrom(await post('/workforce/teams.php', ref), 'teams');
  Future<List<Map<String, dynamic>>> shifts(WidgetRef ref) async =>
      listFrom(await post('/workforce/shifts.php', ref), 'shifts');
  Future<List<Map<String, dynamic>>> attendance(WidgetRef ref,
          {String? start, String? end}) async =>
      listFrom(
          await post('/workforce/attendance.php', ref,
              {'start': start ?? '', 'end': end ?? ''}),
          'attendance');
  Future<List<Map<String, dynamic>>> queue(WidgetRef ref,
          {String? date}) async =>
      listFrom(await post('/workforce/queue.php', ref, {'date': date ?? ''}),
          'queue');
  Future<List<Map<String, dynamic>>> timeRequests(
    WidgetRef ref, {
    String status = '',
    String requestType = '',
  }) async =>
      listFrom(
        await post('/workforce/time_requests.php', ref, {
          'status': status,
          'request_type': requestType,
        }),
        'requests',
      );

  Future<Map<String, dynamic>> timeRequestAction(
    WidgetRef ref, {
    required String requestId,
    required String action,
    String note = '',
  }) {
    final c = ctx(ref);
    return post('/workforce/time_request_action.php', ref, {
      'request_id': requestId,
      'action': action,
      'reviewed_by': c.userId,
      'user_id': c.userId,
      'admin_note': note,
      'rejection_reason': note,
    });
  }
  Future<List<Map<String, dynamic>>> skills(WidgetRef ref) async =>
      listFrom(await post('/workforce/skills.php', ref), 'skills');
  Future<List<Map<String, dynamic>>> stations(WidgetRef ref) async =>
      listFrom(await post('/workforce/stations.php', ref), 'stations');
  Future<List<Map<String, dynamic>>> recipes(WidgetRef ref) async =>
      listFrom(await post('/workforce/service_recipes.php', ref), 'recipes');
  Future<List<Map<String, dynamic>>> allowedIps(WidgetRef ref) async =>
      listFrom(await post('/workforce/allowed_ips.php', ref), 'ips');

  Future<Map<String, dynamic>> dashboard(WidgetRef ref) =>
      post('/workforce/dashboard.php', ref, {'date': _today()});
  Future<Map<String, dynamic>> settings(WidgetRef ref) =>
      post('/workforce/settings.php', ref);

  Future<List<Map<String, dynamic>>> employees(WidgetRef ref) async {
    final user = currentUser(ref);
    final res = await _api.post('/fetch_employees.php', body: {
      'id': '${user?.id ?? ''}',
      'industry': '${user?.industry ?? ''}',
      'shop': '${user?.shop ?? ''}',
      'type': '${user?.type ?? ''}',
      'store': '${user?.storeName ?? ''}',
      'usertype': '',
    });
    if (res is List)
      return res
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    return <Map<String, dynamic>>[];
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<List<Map<String, dynamic>>> staffAssignments(WidgetRef ref) async {
    final c = ctx(ref);

    final res = await post(
      '/workforce/staff_assignments.php',
      ref,
      {
        'company_id': c.companyId,
        'store_id': c.storeId,
      },
    );

    final raw = res['assignments'] ?? res['data'] ?? [];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return [];
  }
  Future<List<Map<String, dynamic>>> get(
    String path,
    WidgetRef ref,
  ) async {
    final c = ctx(ref);

    final res = await _api.post(
      path,
      body: {
        'company_id': c.companyId,
        'store_id': c.storeId,
      },
    );

    final raw = res['data'] ??
        res['rows'] ??
        res['items'] ??
        res['employees'] ??
        res['staff'] ??
        res['categories'] ??
        res['service_categories'] ??
        res['services'] ??
        res['groups'] ??
        res['product_groups'] ??
        [];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return [];
  }
  Future<List<Map<String, dynamic>>> pendingReturns(WidgetRef ref) async {
    final res = await post('/workforce/frontoffice_pending_returns.php', ref);
    final raw = res['returns'] ?? res['data'] ?? [];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> confirmReturn(
    WidgetRef ref, {
    required int returnRequestId,
    String notes = '',
  }) {
    final c = ctx(ref);

    return post('/workforce/confirm_returned_items.php', ref, {
      'return_request_id': returnRequestId,
      'confirmed_by': c.userId,
      'user_id': c.userId,
      'notes': notes,
    });
  }

}
