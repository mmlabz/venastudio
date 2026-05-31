import 'package:venastudio/common.dart';

class AnalyticsPeriodBar extends ConsumerWidget {
  const AnalyticsPeriodBar({
    super.key,
    this.onChanged,
  });

  final Future<void> Function()? onChanged;

  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color line = Color(0xffCFEFF4);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(analyticsFiltersProvider);

    final options = <AnalyticsFilters>[
      AnalyticsFilters.today(),
      AnalyticsFilters.yesterday(),
      AnalyticsFilters.thisWeek(),
      AnalyticsFilters.last7Days(),
      AnalyticsFilters.thisMonth(),
      AnalyticsFilters.lastMonth(),
      AnalyticsFilters.last90Days(),
      AnalyticsFilters.thisYear(),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Analytics Period',
                  style: TextStyle(
                    color: dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _pickCustomRange(context, ref, filters),
                icon: const Icon(Icons.date_range_rounded, size: 18),
                label: const Text('Custom'),
                style: TextButton.styleFrom(
                  foregroundColor: teal,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          Text(
            '${filters.label}: ${filters.displayRange}',
            style: const TextStyle(
              color: muted,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((option) {
                final selected = option.label == filters.label;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selected,
                    label: Text(option.label),
                    selectedColor: teal.withOpacity(.18),
                    backgroundColor: const Color(0xffF7FCFD),
                    side: BorderSide(color: selected ? teal : line),
                    labelStyle: TextStyle(
                      color: selected ? dark : muted,
                      fontWeight: FontWeight.w900,
                    ),
                    onSelected: (_) => _setFilter(ref, filters, option),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setFilter(
    WidgetRef ref,
    AnalyticsFilters current,
    AnalyticsFilters next,
  ) async {
    ref.read(analyticsFiltersProvider.notifier).state = next.copyWith(
      storeId: current.storeId,
      employeeId: current.employeeId,
    );

    if (onChanged != null) {
      await onChanged!();
    }
  }

  Future<void> _pickCustomRange(
    BuildContext context,
    WidgetRef ref,
    AnalyticsFilters current,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: current.startDate,
        end: current.endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: teal,
                  secondary: teal,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    await _setFilter(
      ref,
      current,
      AnalyticsFilters.custom(
        startDate: picked.start,
        endDate: picked.end,
      ),
    );
  }
}
