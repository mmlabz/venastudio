class CustomerHealth {
  const CustomerHealth({
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.healthScore,
    required this.returnProbability,
    required this.churnProbability,
    required this.lifetimeValue,
    required this.revenueAtRisk,
    required this.lastVisit,
    required this.averageVisitInterval,
    required this.favoriteService,
    required this.favoriteBeautician,
    required this.status,
    required this.recommendation,
    required this.daysSinceLastVisit,
    required this.visits,
    required this.raw,
  });

  final String customerId;
  final String customerName;
  final String phone;
  final double healthScore;
  final double returnProbability;
  final double churnProbability;
  final double lifetimeValue;
  final double revenueAtRisk;
  final String lastVisit;
  final double averageVisitInterval;
  final String favoriteService;
  final String favoriteBeautician;
  final String status;
  final String recommendation;
  final int daysSinceLastVisit;
  final int visits;
  final Map<String, dynamic> raw;

  factory CustomerHealth.fromMap(Map<String, dynamic> map) {
    final returnScore = _toDouble(
      map['return_score'] ?? map['return_probability'] ?? map['health_score'],
    );

    final totalSpent = _toDouble(
      map['total_spent'] ?? map['lifetime_value'] ?? map['revenue_at_risk'],
    );

    final risk = '${map['churn_risk'] ?? ''}';
    final prediction = '${map['prediction'] ?? ''}';

    final status = prediction.trim().isNotEmpty
        ? prediction
        : '${map['status'] ?? _statusFromScore(returnScore)}';

    return CustomerHealth(
      customerId: '${map['customer_id'] ?? map['client_id'] ?? map['id'] ?? ''}',
      customerName:
          '${map['customer_name'] ?? map['client_name'] ?? map['name'] ?? map['phone'] ?? map['customer_phone'] ?? 'Customer'}',
      phone: '${map['phone'] ?? map['customer_phone'] ?? ''}',
      healthScore: returnScore,
      returnProbability: returnScore,
      churnProbability: _toDouble(map['churn_probability'] ??
          (returnScore <= 100 ? (100 - returnScore) : 0)),
      lifetimeValue: totalSpent,
      revenueAtRisk: _toDouble(map['revenue_at_risk'] ??
          (risk.toLowerCase().contains('high') ? totalSpent : 0)),
      lastVisit: '${map['last_visit'] ?? ''}',
      averageVisitInterval: _toDouble(map['average_visit_interval']),
      favoriteService: '${map['favorite_service'] ?? ''}',
      favoriteBeautician: '${map['favorite_beautician'] ?? ''}',
      status: status,
      recommendation:
          '${map['recommendation'] ?? _recommendationFromScore(returnScore)}',
      daysSinceLastVisit: _toInt(map['days_since_last_visit']),
      visits: _toInt(map['visits']),
      raw: map,
    );
  }

  bool get isAtRisk {
    final s = status.toLowerCase();
    return healthScore < 60 ||
        s.contains('risk') ||
        s.contains('follow') ||
        s.contains('churn');
  }

  bool get isChurnLikely =>
      healthScore < 40 || status.toLowerCase().contains('churn');

  static String _statusFromScore(double score) {
    if (score >= 80) return 'Very likely to return';
    if (score >= 60) return 'Likely to return';
    if (score >= 40) return 'Needs follow-up';
    return 'At risk of churn';
  }

  static String _recommendationFromScore(double score) {
    if (score >= 75) return 'Keep nurturing';
    if (score >= 60) return 'Send soft reminder';
    if (score >= 40) return 'Send win-back offer';
    return 'Call or WhatsApp urgently';
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
