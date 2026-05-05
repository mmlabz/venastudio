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
  String title = 'All Commissions';

  Future<void> init({(DateTime start, DateTime end)? range}) async {
    final activeAgent = LocalStorage.nosql.activeAgent;

    final ServiceUser? user = activeAgent != null
        ? ServiceUser.fromMap(activeAgent)
        : authService?.user;

    if (user == null) return;
    if (range != null) {
      state = const AsyncLoading();
    }

    final body = {
      'id': '${user.id}',
      'industry': user.industry,
      'shop': user.shop,
      'type': user.type,
      'store': '',
      'usertype': '',
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
