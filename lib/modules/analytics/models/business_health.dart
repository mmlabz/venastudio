class BusinessHealth {
  const BusinessHealth({
    required this.score,
    required this.status,
    required this.summary,
    required this.factors,
    required this.raw,
  });

  final double score;
  final String status;
  final String summary;
  final Map<String, dynamic> factors;
  final Map<String, dynamic> raw;

  factory BusinessHealth.fromMap(Map<String, dynamic> map) {
    final data = Map<String, dynamic>.from(map['data'] ?? map);
    final score = _toDouble(data['score']);

    return BusinessHealth(
      score: score,
      status: '${data['status'] ?? _status(score)}',
      summary: '${data['summary'] ?? _summary(score)}',
      factors: data['factors'] is Map
          ? Map<String, dynamic>.from(data['factors'])
          : <String, dynamic>{},
      raw: data,
    );
  }

  static String _status(double score) {
    if (score >= 85) return 'Excellent';
    if (score >= 75) return 'Strong';
    if (score >= 60) return 'Stable';
    if (score >= 45) return 'Warning';
    return 'Critical';
  }

  static String _summary(double score) {
    if (score >= 75) return 'Business health is strong.';
    if (score >= 60) return 'Business is stable but needs monitoring.';
    if (score >= 45) return 'Business needs urgent operational attention.';
    return 'Critical issues require immediate action.';
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
