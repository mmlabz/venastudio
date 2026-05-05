import 'package:venastudio/common.dart';

final agentsServicesProvider =
    StateNotifierProvider<AgentsServiceNotifier, AsyncValue<List<Agent>>>((
      ref,
    ) {
      final authService = ref.watch(authenticationServiceProvider);
      return AgentsServiceNotifier(authService: authService);
    });

class AgentsServiceNotifier extends StateNotifier<AsyncValue<List<Agent>>> {
  AgentsServiceNotifier({required this.authService})
    : super(const AsyncLoading()) {
    if (authService is! AsyncLoading) init();
  }

  final AsyncValue<AuthData> authService;
  final _apiService = ApiProvider();
  Agent? checkoutAgent;

  ServiceUser? get _user {
    final activeAgent = LocalStorage.nosql.activeAgent;

    if (activeAgent != null) {
      return ServiceUser.fromMap(activeAgent);
    }

    return authService.valueOrNull?.user ?? LocalStorage.nosql.user;
  }

  Future<void> init() async {
    try {
      final user = _user;

      final body = {
        'id': '${user?.id ?? ''}',
        'industry': user?.industry,
        'shop': user?.shop,
        'type': user?.type,
        'store': user?.storeName ?? '',
        'usertype': '',
      };

      final dynamic response = await _apiService.post(
        '/fetch_employees.php',
        body: body,
      );

      final agt = List<Agent>.from(
        (response as List).map((e) => Agent.fromJson(e)),
      );

      state = AsyncData(agt);
    } catch (e) {
      state = AsyncError(e.toString(), StackTrace.current);
    }
  }

  Future<void> update({required Agent agent, String? shop}) async {
    final user = _user;
    if (user == null) return;

    final body = {
      'shop': user.shop,
      'archived': agent.archived ? '1' : '0',
      'roles': agent.type,
      'id': '${agent.id}',
      'name': agent.name,
      'email': agent.email,
      'phone': agent.phone,
      'commission': agent.commission.toStringAsFixed(1),
      'pin': '${agent.pin}',
      'national': '${agent.userID}',
      if (shop != null) 'selected_shop': shop,
    };

    await _apiService.post('/update_agent.php', body: body);
  }

  Future<void> add({required Agent agent, required String shop}) async {
    final user = _user;
    if (user == null) return;

    final body = {
      'shop': user.shop,
      'selected_shop': shop,
      'roles': agent.type,
      'name': agent.name,
      'email': agent.email,
      'phone': agent.phone,
      'commission': '${agent.commission}',
      'pin': '${agent.pin}',
      'national': '${agent.userID}',
    };

    await _apiService.post('/create_staff.php', body: body);
  }
}
