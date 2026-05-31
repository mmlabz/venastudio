import 'package:venastudio/common.dart';

class BusinessHealthCard extends StatelessWidget {
  const BusinessHealthCard({
    super.key,
    required this.score,
    required this.status,
    required this.factors,
  });

  final double score;
  final String status;
  final Map<String, dynamic> factors;

  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color line = Color(0xffCFEFF4);
  static const Color teal = Color(0xff43C5D8);
  static const Color danger = Color(0xffD94B4B);
  static const Color amber = Color(0xffF4A62A);
  static const Color success = Color(0xff13A76B);

  Color get color {
    if (score >= 80) return success;
    if (score >= 65) return teal;
    if (score >= 50) return amber;
    return danger;
  }

  @override
  Widget build(BuildContext context) {
    final normalized = (score.clamp(0, 100)) / 100;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 116,
            width: 116,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: normalized,
                  strokeWidth: 12,
                  color: color,
                  backgroundColor: color.withOpacity(.12),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score.toStringAsFixed(0),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                    const Text(
                      'Score',
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Weighted from sales, retention, cash, inventory, workforce and profitability.',
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: factors.entries.take(6).map((e) {
                  return MetricChip(
                    label: '${e.key}',
                    value: '${e.value}',
                    color: color,
                  );
                }).toList(),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
