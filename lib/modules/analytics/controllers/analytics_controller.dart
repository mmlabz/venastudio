import 'package:venastudio/common.dart';

ServiceUser? analyticsCurrentUser(Ref ref) {
  final activeAgent = LocalStorage.nosql.activeAgent;

  if (activeAgent != null) {
    return ServiceUser.fromMap(activeAgent);
  }

  return ref.read(authenticationServiceProvider).valueOrNull?.user ??
      LocalStorage.nosql.user;
}

final analyticsFiltersProvider =
    StateProvider<AnalyticsFilters>((ref) => AnalyticsFilters.thisMonth());

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

Map<String, String> analyticsBody(Ref ref) {
  final user = analyticsCurrentUser(ref);
  final filters = ref.read(analyticsFiltersProvider);

  return filters.toBody(
    companyId: '${user?.shop ?? ''}',
    store: '${user?.storeName ?? ''}',
    userId: '${user?.id ?? ''}',
    userType: '${user?.type ?? ''}',
  );
}

Map<String, dynamic> analyticsPayload(Map<String, dynamic> res) {
  final data = res['data'];
  if (data is Map) return Map<String, dynamic>.from(data);
  return Map<String, dynamic>.from(res);
}

List<Map<String, dynamic>> analyticsList(dynamic value) {
  if (value is! List) return [];
  return value
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

final analyticsDashboardProvider =
    StateNotifierProvider<AnalyticsDashboardNotifier,
        AsyncValue<AnalyticsSummary>>(
  (ref) => AnalyticsDashboardNotifier(ref)..load(),
);

class AnalyticsDashboardNotifier
    extends StateNotifier<AsyncValue<AnalyticsSummary>> {
  AnalyticsDashboardNotifier(this.ref) : super(const AsyncLoading()) {
    ref.listen<AnalyticsFilters>(analyticsFiltersProvider, (previous, next) {
      if (previous == null) return;
      load();
    });
  }

  final Ref ref;

  Future<void> load() async {
    final previous = state.valueOrNull;
    if (previous == null) {
      state = const AsyncLoading();
    }

    try {
      final service = ref.read(analyticsServiceProvider);
      final body = analyticsBody(ref);

      debugPrint('ANALYTICS DASHBOARD BODY: $body');

      final res = await service.dashboardSummary(body);
      state = AsyncData(AnalyticsSummary.fromMap(res));
    } catch (e, st) {
      if (previous != null) {
        state = AsyncData(previous);
        debugPrint('ANALYTICS DASHBOARD REFRESH ERROR: $e');
      } else {
        state = AsyncError(e, st);
      }
    }
  }
}

final customerPredictorProvider =
    StateNotifierProvider<CustomerPredictorNotifier,
        AsyncValue<List<CustomerHealth>>>(
  (ref) => CustomerPredictorNotifier(ref)..load(),
);

class CustomerPredictorNotifier
    extends StateNotifier<AsyncValue<List<CustomerHealth>>> {
  CustomerPredictorNotifier(this.ref) : super(const AsyncLoading()) {
    ref.listen<AnalyticsFilters>(analyticsFiltersProvider, (previous, next) {
      if (previous == null) return;
      load();
    });
  }

  final Ref ref;

  Future<void> load() async {
    try {
      final service = ref.read(analyticsServiceProvider);
      final body = analyticsBody(ref);

      debugPrint('CUSTOMER PREDICTOR BODY: $body');

      final res = await service.customerPredictor(body);
      final payload = analyticsPayload(res);

      final raw = payload['predictions'] ??
          payload['customers'] ??
          payload['predictor'] ??
          payload['data'] ??
          [];

      final rows =
          analyticsList(raw).map((e) => CustomerHealth.fromMap(e)).toList();

      state = AsyncData(rows);
    } catch (e) {
      debugPrint('CUSTOMER PREDICTOR ERROR: $e');
      // Predictor should never break the whole analytics dashboard.
      state = const AsyncData(<CustomerHealth>[]);
    }
  }
}

final genericAnalyticsProvider = StateNotifierProvider.family<
    GenericAnalyticsNotifier, AsyncValue<Map<String, dynamic>>, String>(
  (ref, type) => GenericAnalyticsNotifier(ref, type)..load(),
);

class GenericAnalyticsNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  GenericAnalyticsNotifier(this.ref, this.type) : super(const AsyncLoading()) {
    ref.listen<AnalyticsFilters>(analyticsFiltersProvider, (previous, next) {
      if (previous == null) return;
      load();
    });
  }

  final Ref ref;
  final String type;

  Future<void> load() async {
    final previous = state.valueOrNull;
    if (previous == null) {
      state = const AsyncLoading();
    }

    try {
      final service = ref.read(analyticsServiceProvider);
      final body = analyticsBody(ref);

      debugPrint('ANALYTICS $type BODY: $body');

      Map<String, dynamic> res;

      switch (type) {
        case 'sales':
          res = await service.salesAnalytics(body);
          break;
        case 'customers':
          res = await service.customerAnalytics(body);
          break;
        case 'retention':
          res = await service.retentionAnalytics(body);
          break;
        case 'workforce':
          res = await service.workforceAnalytics(body);
          break;
        case 'inventory':
          res = await service.inventoryAnalytics(body);
          break;
        case 'finance':
          res = await service.financeAnalytics(body);
          break;
        case 'profitability':
          res = await service.profitabilityAnalytics(body);
          break;
        case 'marketing':
          res = await service.marketingAnalytics(body);
          break;
        default:
          res = {};
      }

      state = AsyncData(analyticsPayload(res));
    } catch (e, st) {
      if (previous != null) {
        state = AsyncData(previous);
        debugPrint('ANALYTICS $type REFRESH ERROR: $e');
      } else {
        state = AsyncError(e, st);
      }
    }
  }
}
