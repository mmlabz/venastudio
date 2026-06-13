import 'package:venastudio/common.dart';

final summaryServicesProvider =
    StateNotifierProvider<SummaryServiceNotifier, ServiceSummary>((ref) {
  final authService = ref.watch(authenticationServiceProvider);
  return SummaryServiceNotifier(authService: authService.value);
});

class SummaryServiceNotifier extends StateNotifier<ServiceSummary> {
  SummaryServiceNotifier({required this.authService})
      : super(ServiceSummary.loading()) {
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

  Future<void> init() async {
    await getFinanceSummary(isRefresh: true);
  }

  Future<void> getFinanceSummary({
    (DateTime start, DateTime end)? range,
    bool isRefresh = false,
  }) async {
    final user = _user;
    if (user == null) return;

    if (isRefresh || range != null) {
      state = state.copyWith(finance: const AsyncLoading());
    }

    final today = DateTime.now();
    final start = range?.$1 ?? today;
    final end = range?.$2 ?? today;
    final userType = _normalisedUserType(user.type);

    final body = {
      'company_id': user.shop ?? '',
      'shop': user.shop ?? '',
      'id': '${user.id}',
      'employee_id': '${user.id}',
      'type': userType,
      'usertype': userType,
      'store': user.storeName ?? '',
      'store_id': user.storeId ?? '',
      'industry': user.industry ?? '',
      'start': sDate(start),
      'end': sDate(end),
      'start_date': sDate(start),
      'end_date': sDate(end),
    };

    final dynamic response = await _apiService.post(
      '/finance/admin_summary.php',
      body: body,
    );

    state = state.copyWith(
      finance: AsyncData(
        AdminFinanceSummary.fromMap(
          response is Map ? Map<String, dynamic>.from(response) : {},
        ),
      ),
    );
  }

  String _normalisedUserType(String? type) {
    final text = (type ?? '').trim().toLowerCase();
    if (text == 'user') return 'employee';
    return text;
  }
}
