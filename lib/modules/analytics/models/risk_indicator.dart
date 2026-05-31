class RiskIndicator {
  const RiskIndicator({
    required this.title,
    required this.level,
    required this.score,
    required this.message,
    required this.category,
    required this.raw,
  });

  final String title;
  final String level;
  final double score;
  final String message;
  final String category;
  final Map<String, dynamic> raw;

  factory RiskIndicator.fromMap(Map<String, dynamic> map) {
    return RiskIndicator(
      title: '${map['title'] ?? 'Risk'}',
      level: '${map['level'] ?? 'Medium'}',
      score: _toDouble(map['score']),
      message: '${map['message'] ?? ''}',
      category: '${map['category'] ?? ''}',
      raw: map,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
