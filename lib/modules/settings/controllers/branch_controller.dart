import 'package:venastudio/common.dart';

final branchesServicesProvider =
    StateNotifierProvider<BranchesServiceNotifier, AsyncValue<List<Map>>>((
      ref,
    ) {
      final authService = ref.watch(authenticationServiceProvider);
      return BranchesServiceNotifier(authService: authService.value);
    });

class BranchesServiceNotifier extends StateNotifier<AsyncValue<List<Map>>> {
  BranchesServiceNotifier({required this.authService})
    : super(const AsyncLoading()) {
    if (authService != null) init();
  }

  final AuthData? authService;
  final _apiService = ApiProvider();

  Future<void> init() async {
    final user = authService!.user;
    final body = {
      'id': '',
      'industry': user.industry,
      'shop': user.shop,
      'type': user.type,
      'store': '',
      'usertype': '',
    };
    final dynamic response = await _apiService.post(
      '/fetch_shops.php',
      body: body,
    );
    final agt = List<Map>.from((response as List).map((e) => e));
    state = AsyncData(agt);
  }

  Future<void> update(Map<dynamic, dynamic> branch) async {
    final user = authService!.user;
    final body = {...branch, 'shop': user.shop};
    await _apiService.post('/create_branch.php', body: body);
  }
}
