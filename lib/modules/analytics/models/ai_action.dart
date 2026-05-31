class AiAction {
  const AiAction({
    required this.title,
    required this.message,
    required this.priority,
    required this.category,
    required this.recommendedAction,
    required this.estimatedImpact,
    required this.raw,
  });

  final String title;
  final String message;
  final String priority;
  final String category;
  final String recommendedAction;
  final double estimatedImpact;
  final Map<String, dynamic> raw;

  factory AiAction.fromMap(Map<String, dynamic> map) {
    return AiAction(
      title: '${map['title'] ?? 'Action'}',
      message: '${map['message'] ?? ''}',
      priority: '${map['priority'] ?? 'Medium'}',
      category: '${map['category'] ?? 'General'}',
      recommendedAction: '${map['recommended_action'] ?? map['action'] ?? ''}',
      estimatedImpact: _toDouble(map['estimated_impact']),
      raw: map,
    );
  }

  bool get isHighPriority {
    final p = priority.toLowerCase();
    return p.contains('high') || p.contains('urgent') || p.contains('critical');
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
