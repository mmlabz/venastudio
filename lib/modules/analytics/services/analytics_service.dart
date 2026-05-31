import 'package:venastudio/common.dart';

class AnalyticsService {
  AnalyticsService({ApiProvider? api}) : _api = api ?? ApiProvider();

  final ApiProvider _api;

  Future<Map<String, dynamic>> dashboardSummary(Map<String, String> body) {
    return _post('/analytics/executive_overview.php', body);
  }

  Future<Map<String, dynamic>> salesAnalytics(Map<String, String> body) {
    return _post('/analytics/revenue_analytics.php', body);
  }

  Future<Map<String, dynamic>> customerAnalytics(Map<String, String> body) {
    return _post('/analytics/customer_analytics.php', body);
  }

  Future<Map<String, dynamic>> retentionAnalytics(Map<String, String> body) {
    return _post('/analytics/customer_analytics.php', body);
  }

  Future<Map<String, dynamic>> customerPredictor(Map<String, String> body) {
    return _post('/analytics/customer_return_predictor.php', body);
  }

  Future<Map<String, dynamic>> workforceAnalytics(Map<String, String> body) {
    return _post('/analytics/employee_analytics.php', body);
  }

  Future<Map<String, dynamic>> inventoryAnalytics(Map<String, String> body) {
    return _post('/analytics/inventory_analytics.php', body);
  }

  Future<Map<String, dynamic>> financeAnalytics(Map<String, String> body) {
    return _post('/analytics/revenue_analytics.php', body);
  }

  Future<Map<String, dynamic>> profitabilityAnalytics(
    Map<String, String> body,
  ) {
    return _post('/analytics/service_analytics.php', body);
  }

  Future<Map<String, dynamic>> marketingAnalytics(Map<String, String> body) {
    return _post('/analytics/customer_analytics.php', body);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, String> body,
  ) async {
    final res = await _api.post(path, body: body);
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'status': 'fail', 'data': res};
  }
}
