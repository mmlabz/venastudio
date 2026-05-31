class AnalyticsFilters {
  const AnalyticsFilters({
    required this.startDate,
    required this.endDate,
    required this.label,
    this.storeId = '',
    this.employeeId = '',
  });

  final DateTime startDate;
  final DateTime endDate;
  final String label;
  final String storeId;
  final String employeeId;

  factory AnalyticsFilters.today() {
    final now = DateTime.now();
    return AnalyticsFilters(
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day),
      label: 'Today',
    );
  }

  factory AnalyticsFilters.yesterday() {
    final now = DateTime.now().subtract(const Duration(days: 1));
    return AnalyticsFilters(
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day),
      label: 'Yesterday',
    );
  }

  factory AnalyticsFilters.thisWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: now.weekday - 1));
    return AnalyticsFilters(
      startDate: start,
      endDate: today,
      label: 'This Week',
    );
  }

  factory AnalyticsFilters.last7Days() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return AnalyticsFilters(
      startDate: today.subtract(const Duration(days: 6)),
      endDate: today,
      label: 'Last 7 Days',
    );
  }

  factory AnalyticsFilters.thisMonth() {
    final now = DateTime.now();
    return AnalyticsFilters(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month, now.day),
      label: 'This Month',
    );
  }

  factory AnalyticsFilters.lastMonth() {
    final now = DateTime.now();
    final firstThisMonth = DateTime(now.year, now.month, 1);
    final lastMonthEnd = firstThisMonth.subtract(const Duration(days: 1));

    return AnalyticsFilters(
      startDate: DateTime(lastMonthEnd.year, lastMonthEnd.month, 1),
      endDate: lastMonthEnd,
      label: 'Last Month',
    );
  }

  factory AnalyticsFilters.last90Days() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return AnalyticsFilters(
      startDate: today.subtract(const Duration(days: 89)),
      endDate: today,
      label: 'Last 90 Days',
    );
  }

  factory AnalyticsFilters.thisYear() {
    final now = DateTime.now();

    return AnalyticsFilters(
      startDate: DateTime(now.year, 1, 1),
      endDate: DateTime(now.year, now.month, now.day),
      label: 'This Year',
    );
  }

  factory AnalyticsFilters.custom({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return AnalyticsFilters(
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      endDate: DateTime(endDate.year, endDate.month, endDate.day),
      label: 'Custom',
    );
  }

  AnalyticsFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? label,
    String? storeId,
    String? employeeId,
  }) {
    return AnalyticsFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      label: label ?? this.label,
      storeId: storeId ?? this.storeId,
      employeeId: employeeId ?? this.employeeId,
    );
  }

  String get start => _date(startDate);
  String get end => _date(endDate);
  String get displayRange => '${_human(startDate)} → ${_human(endDate)}';

  Map<String, String> toBody({
    String companyId = '',
    String store = '',
    String userId = '',
    String userType = '',
  }) {
    final resolvedStore = storeId.isEmpty ? store : storeId;

    return {
      'company_id': companyId,
      'shop': companyId,
      'store_id': resolvedStore,
      'store': resolvedStore,
      'employee_id': employeeId,
      'user_id': userId,
      'user_type': userType,

      // Main backend keys.
      'from_date': start,
      'to_date': end,

      // Compatibility keys for older PHP files.
      'start_date': start,
      'end_date': end,
      'date_from': start,
      'date_to': end,
      'from': start,
      'to': end,
      'start': start,
      'end': end,

      'period_label': label,
    };
  }

  static String _date(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _human(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }
}
