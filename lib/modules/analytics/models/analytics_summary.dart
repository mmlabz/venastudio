class AnalyticsSummary {
  const AnalyticsSummary({
    required this.totalSales,
    required this.totalOrders,
    required this.totalCustomers,
    required this.averageOrderValue,
    required this.dailySales,
    required this.topServices,
    required this.retentionRate,
    required this.lowStockCount,
    required this.customersAtRisk,
    required this.predictedRevenue,
    required this.revenueAtRisk,
    required this.cashPosition,
    required this.expensesToday,
    required this.raw,
  });

  final double totalSales;
  final int totalOrders;
  final int totalCustomers;
  final double averageOrderValue;
  final List<Map<String, dynamic>> dailySales;
  final List<Map<String, dynamic>> topServices;
  final double retentionRate;
  final int lowStockCount;
  final int customersAtRisk;
  final double predictedRevenue;
  final double revenueAtRisk;
  final double cashPosition;
  final double expensesToday;
  final Map<String, dynamic> raw;

  double get salesToday => totalSales;
  double get salesMonth => totalSales;
  int get customersToday => totalCustomers;

  factory AnalyticsSummary.empty() {
    return const AnalyticsSummary(
      totalSales: 0,
      totalOrders: 0,
      totalCustomers: 0,
      averageOrderValue: 0,
      dailySales: [],
      topServices: [],
      retentionRate: 0,
      lowStockCount: 0,
      customersAtRisk: 0,
      predictedRevenue: 0,
      revenueAtRisk: 0,
      cashPosition: 0,
      expensesToday: 0,
      raw: {},
    );
  }

  factory AnalyticsSummary.fromMap(Map<String, dynamic> map) {
    final payload = _payload(map);
    final summary = Map<String, dynamic>.from(payload['summary'] ?? payload);

    final dailyRaw = payload['daily_sales'] ?? summary['daily_sales'] ?? [];

    final servicesRaw = payload['top_services'] ??
        summary['top_services'] ??
        payload['data']?['top_services'] ??
        [];

    return AnalyticsSummary(
      totalSales: _toDouble(
        summary['total_sales'] ??
            summary['sales_month'] ??
            summary['sales_today'],
      ),
      totalOrders: _toInt(summary['total_orders'] ?? summary['orders']),
      totalCustomers:
          _toInt(summary['total_customers'] ?? summary['customers_today']),
      averageOrderValue: _toDouble(
        summary['average_order_value'] ?? summary['avg_order_value'],
      ),
      dailySales: _listOfMaps(dailyRaw),
      topServices: _listOfMaps(servicesRaw),
      retentionRate: _toDouble(summary['retention_rate']),
      lowStockCount: _toInt(summary['low_stock_count']),
      customersAtRisk: _toInt(summary['customers_at_risk']),
      predictedRevenue: _toDouble(
        summary['predicted_revenue'] ??
            summary['total_sales'] ??
            summary['sales_month'],
      ),
      revenueAtRisk: _toDouble(summary['revenue_at_risk']),
      cashPosition: _toDouble(summary['cash_position']),
      expensesToday: _toDouble(summary['expenses_today']),
      raw: payload,
    );
  }

  static Map<String, dynamic> _payload(Map<String, dynamic> map) {
    final data = map['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return Map<String, dynamic>.from(map);
  }

  static List<Map<String, dynamic>> _listOfMaps(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
