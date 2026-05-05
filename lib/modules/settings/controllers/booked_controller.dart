import 'dart:convert';

import 'package:venastudio/common.dart';

final bookedOrderServicesProvider =
    StateNotifierProvider.autoDispose<
      BookedOrderServiceNotifier,
      AsyncValue<List<Map>>
    >((ref) {
      final authService = ref.watch(authenticationServiceProvider);
      return BookedOrderServiceNotifier(authService: authService.value);
    });

class BookedOrderServiceNotifier extends StateNotifier<AsyncValue<List<Map>>> {
  BookedOrderServiceNotifier({required this.authService})
    : super(const AsyncLoading()) {
    if (authService != null) init();
  }

  final AuthData? authService;
  final _apiService = ApiProvider();

  Future<void> init({(DateTime start, DateTime end)? range}) async {
    if (range != null) {
      state = const AsyncLoading();
    }
    final user = authService!.user;
    final body = {
      'shop': user.shop,
      'type': user.type,
      'store': user.storeName,
      'usertype': user.type,
      'start': sDate(range?.$1 ?? DateTime.now()),
      'end': sDate(range?.$2 ?? DateTime.now()),
      'start_date': sDate(range?.$1 ?? DateTime.now()),
      'end_date': sDate(range?.$2 ?? DateTime.now()),
    };
    final dynamic response = await _apiService.post(
      '/fetch_bookings.php',
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
}
