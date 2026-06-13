import 'dart:convert';

import 'package:venastudio/common.dart';

// final completedOrderServicesProvider = StateNotifierProvider.autoDispose<
//   CompletedOrderServiceNotifier,
//   AsyncValue<List<Map>>
// >((ref) {
//   final authService = ref.watch(authenticationServiceProvider);
//   return CompletedOrderServiceNotifier(authService: authService.value);
// });

// class CompletedOrderServiceNotifier
//     extends StateNotifier<AsyncValue<List<Map>>> {
//   CompletedOrderServiceNotifier({required this.authService})
//     : super(const AsyncLoading()) {
//     if (authService != null) init();
//   }

//   final AuthData? authService;
//   final _apiService = ApiProvider();

//   Future<void> init({(DateTime start, DateTime end)? range}) async {
//     if (state is! AsyncLoading) {
//       state = const AsyncLoading();
//     }
//     final user = authService!.user;
//     final body = {
//       'id': '',
//       'industry': user.industry,
//       'shop': user.shop,
//       'type': completedUserType,
//       'store': user.storeName,
//       'usertype': completedUserType,
//       'service_type': 'addon',
//       'start': sDate(range?.$1 ?? DateTime.now()),
//       'end': sDate(range?.$2 ?? DateTime.now()),
//       'start_date': sDate(range?.$1 ?? DateTime.now()),
//       'end_date': sDate(range?.$2 ?? DateTime.now()),
//     };
//     final dynamic response = await _apiService.post(
//       '/fetch_cash_orders.php',
//       body: body,
//     );
//     final agt = List<Map>.from((response as List).map((e) => e));
//     state = AsyncData(agt);
//   }

//   Future<void> assignAgent({
//     required Agent agent,
//     required String billno,
//     required num orderid,
//   }) async {
//     final user = authService!.user;
//     final body = {
//       'user': '',
//       'order': billno,
//       'agent': agent.name,
//       'id': '${agent.id}',
//       'shop': user.shop,
//     };
//     final res = await _apiService.post('/assign_order.php', body: body);
//     final neworder = jsonDecode(res['data']) as Map;
//     final oldorders = state.value ?? [];
//     oldorders.removeWhere((x) => x['id'] == orderid);
//     final toupdate = [neworder, ...oldorders];
//     state = AsyncData(toupdate);
//   }
// }

final completedOrderServicesProvider =
    StateNotifierProvider.autoDispose<
      CompletedOrderServiceNotifier,
      AsyncValue<List<Map>>
    >((ref) {
      final authService = ref.watch(authenticationServiceProvider);
      return CompletedOrderServiceNotifier(authService: authService.value);
    });

class CompletedOrderServiceNotifier
    extends StateNotifier<AsyncValue<List<Map>>> {
  CompletedOrderServiceNotifier({required this.authService})
    : super(const AsyncLoading()) {
    if (authService != null) init();
  }

  final AuthData? authService;
  final _apiService = ApiProvider();

  Future<void> init({(DateTime start, DateTime end)? range}) async {
    if (state is! AsyncLoading) {
      state = const AsyncLoading();
    }
    final activeAgent = LocalStorage.nosql.activeAgent;
    final user = activeAgent != null ? ServiceUser.fromMap(activeAgent) : authService!.user;
    final completedUserType = normalizeUserType(user.type);
    final body = {
      'id': '${user.id}',
      'industry': user.industry,
      'shop': user.shop,
      'type': completedUserType,
      'store': user.storeName,
      'usertype': completedUserType,
      'service_type': 'addon',
      'start': sDate(range?.$1 ?? DateTime.now()),
      'end': sDate(range?.$2 ?? DateTime.now()),
      'start_date': sDate(range?.$1 ?? DateTime.now()),
      'end_date': sDate(range?.$2 ?? DateTime.now()),
    };
    final dynamic response = await _apiService.post(
      '/fetch_cash_orders.php',
      body: body,
    );
    final agt = List<Map>.from((response as List).map((e) => e));
    state = AsyncData(agt);
  }

  Future<void> assignAgent({
    required Agent agent,
    required String billno,
    required num orderid,
  }) async {
    final user = authService!.user;
    final body = {
      'user': '',
      'order': billno,
      'agent': agent.name,
      'id': '${agent.id}',
      'shop': user.shop,
    };
    final res = await _apiService.post('/assign_order.php', body: body);
    final neworder = jsonDecode(res['data']) as Map;
    final oldorders = state.value ?? [];
    oldorders.removeWhere((x) => x['id'] == orderid);
    final toupdate = [neworder, ...oldorders];
    state = AsyncData(toupdate);
  }

  Future<void> assignAgentSingle({
    required Agent agent,
    required String billno,
    required num orderid,
    required String cartid,
    (DateTime start, DateTime end)? range,
  }) async {
    final body = {
      'state': 'single',
      'cart_id': cartid,
      'agent': agent.name,
      'id': '${agent.id}',
      'order': billno,
      'user': '',
    };
    await _apiService.post('/assign_single.php', body: body);
    init(range: range);

    // final res = await _apiService.post('/assign_single.php', body: body);
    // final neworder = jsonDecode(res['data']) as Map;
    // final oldorders = state.value ?? [];
    // oldorders.removeWhere((x) => x['id'] == orderid);
    // final toupdate = [neworder, ...oldorders];
    // state = AsyncData(toupdate);
  }
}
