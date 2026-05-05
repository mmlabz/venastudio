import 'package:venastudio/common.dart';

final expenseServicesProvider =
    StateNotifierProvider<ExpenseServiceNotifier, AsyncValue<Map>>((ref) {
      final authService = ref.watch(authenticationServiceProvider);
      return ExpenseServiceNotifier(authService: authService.value);
    });

class ExpenseServiceNotifier extends StateNotifier<AsyncValue<Map>> {
  ExpenseServiceNotifier({required this.authService})
    : super(const AsyncLoading()) {
    if (authService != null) init();
  }

  final AuthData? authService;
  final _apiService = ApiProvider();

  ServiceUser? get _user {
    final activeAgent = LocalStorage.nosql.activeAgent;

    if (activeAgent != null) {
      return ServiceUser.fromMap(activeAgent);
    }

    return authService?.user;
  }

  Future<void> init({(DateTime start, DateTime end)? range}) async {
    final user = _user;
    if (user == null) return;

    if (range != null) {
      state = const AsyncLoading();
    }

    final body = {
      'store': user.storeId ?? '',
      'shop': user.shop,
      'utype': user.type,
      'start': sDate(range?.$1 ?? DateTime.now()),
      'end': sDate(range?.$2 ?? DateTime.now()),
    };

    final dynamic response = await _apiService.post(
      '/cash_register.php',
      body: body,
    );

    state = AsyncData(response);
  }

  Future<void> add({
    required ({
      String reason,
      String type,
      String amount,
      String category,
      String store,
      String prevAmount,
      String id,
    })
    details,
    bool isUpdate = false,
  }) async {
    final user = _user;
    if (user == null) return;

    final body = isUpdate
        ? {
            'id': details.id,
            'original_amount': details.prevAmount,
            'amount': details.amount,
            'type': details.type,
            'category': details.category,
            'description': details.reason,
            'user_id': user.id.toString(),
            'store': details.store,
            'shop': user.shop,
          }
        : {
            'amount': details.amount,
            'type': details.type,
            'category': details.category,
            'description': details.reason,
            'user_id': user.id.toString(),
            'store': details.store,
            'shop': user.shop,
          };

    await _apiService.post(
      isUpdate ? '/cash_register_update.php' : '/cash_register_adjust.php',
      body: body,
    );
  }
}

final expenseCategoriesProvider = FutureProvider((ref) async {
  final activeAgent = LocalStorage.nosql.activeAgent;

  final user = activeAgent != null
      ? ServiceUser.fromMap(activeAgent)
      : ref.read(authenticationServiceProvider).value?.user;

  final dynamic response = await ApiProvider().post(
    '/fetch_category_expense.php',
    body: {'shop': user?.shop},
  );

  return List<Map>.from((response as List).map((e) => e as Map));
});
