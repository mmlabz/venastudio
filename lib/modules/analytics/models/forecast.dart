class Forecast {
  const Forecast({
    required this.title,
    required this.value,
    required this.confidence,
    required this.trend,
    required this.period,
    required this.description,
    required this.raw,
  });

  final String title;
  final double value;
  final double confidence;
  final String trend;
  final String period;
  final String description;
  final Map<String, dynamic> raw;

  factory Forecast.fromMap(Map<String, dynamic> map) {
    return Forecast(
      title: '${map['title'] ?? map['metric'] ?? 'Forecast'}',
      value: _toDouble(map['value']),
      confidence: _toDouble(map['confidence']),
      trend: '${map['trend'] ?? 'stable'}',
      period: '${map['period'] ?? ''}',
      description: '${map['description'] ?? ''}',
      raw: map,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
