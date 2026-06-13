import 'package:venastudio/common.dart';

final commissionServicesProvider =
    StateNotifierProvider<CommissionServiceNotifier, AsyncValue<List<Map>>>((
      ref,
    ) {
      final authService = ref.watch(authenticationServiceProvider);
      return CommissionServiceNotifier(authService: authService.value);
    });

class CommissionServiceNotifier extends StateNotifier<AsyncValue<List<Map>>> {
  CommissionServiceNotifier({required this.authService})
    : super(const AsyncLoading()) {
    if (authService != null) init();
  }

  final AuthData? authService;
  final _apiService = ApiProvider();
  List<Map> pureData = [];
  (DateTime start, DateTime end)? currentRange;
  String title = 'All Commissions';

  Future<void> init({(DateTime start, DateTime end)? range}) async {
    final activeAgent = LocalStorage.nosql.activeAgent;

    final ServiceUser? user = activeAgent != null
        ? ServiceUser.fromMap(activeAgent)
        : authService?.user;

    if (user == null) return;
    if (range != null) {
      currentRange = range;
      state = const AsyncLoading();
    } else {
      currentRange ??= (DateTime.now(), DateTime.now());
    }

    // The backend understands `Employee`, but some accounts come back as `user`.
    // For commission requests, always post both as the normalized backend role so
    // employee-equivalent users do not receive the all-commissions/admin response.
    final commissionUserType = normalizeUserType(user.type);

    final body = {
      'id': '${user.id}',
      'industry': user.industry,
      'shop': user.shop,
      'type': commissionUserType,
      'store': '',
      'usertype': commissionUserType,
      if (range != null) ...{'start': sDate(range.$1), 'end': sDate(range.$2)},
    };
    final dynamic response = await _apiService.post(
      '/fetch_commission.php',
      body: body,
    );
    final comms = List<Map>.from((response as List).map((e) => e as Map));
    pureData = comms;
    title = 'All Commissions';
    state = AsyncData(comms);
  }


  Future<List<Map<String, dynamic>>> fetchCommissionServices(Map commission) async {
    final activeAgent = LocalStorage.nosql.activeAgent;

    final ServiceUser? user = activeAgent != null
        ? ServiceUser.fromMap(activeAgent)
        : authService?.user;

    if (user == null) return [];

    final range = currentRange ?? (DateTime.now(), DateTime.now());
    final employeeId = commission['employee_id'] ?? commission['employeeId'] ?? commission['agentid'] ?? commission['id'];

    final body = {
      'id': '$employeeId',
      'employee_id': '$employeeId',
      'industry': user.industry,
      'shop': user.shop,
      'type': normalizeUserType(user.type),
      'start': sDate(range.$1),
      'end': sDate(range.$2),
      'start_date': sDate(range.$1),
      'end_date': sDate(range.$2),
    };

    final dynamic response = await _apiService.post(
      '/fetch_commission_services.php',
      body: body,
    );

    return List<Map<String, dynamic>>.from(
      (response as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  void filter(String shop) {
    title = shop;
    if (shop == 'All Shops') {
      state = AsyncData(pureData);
      return;
    }
    state = AsyncData(
      pureData.where((element) => element['shop'] == shop).toList(),
    );
  }
}
