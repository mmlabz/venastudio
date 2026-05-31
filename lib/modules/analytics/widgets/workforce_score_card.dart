import 'package:venastudio/common.dart';

class WorkforceScoreCard extends StatelessWidget {
  const WorkforceScoreCard({
    super.key,
    required this.name,
    required this.primaryMetric,
    required this.secondaryMetric,
    required this.score,
    this.icon = Icons.badge_rounded,
  });

  final String name;
  final String primaryMetric;
  final String secondaryMetric;
  final double score;
  final IconData icon;

  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color line = Color(0xffCFEFF4);
  static const Color teal = Color(0xff43C5D8);
  static const Color danger = Color(0xffD94B4B);
  static const Color amber = Color(0xffF4A62A);
  static const Color success = Color(0xff13A76B);

  Color get color {
    if (score >= 80) return success;
    if (score >= 60) return teal;
    if (score >= 40) return amber;
    return danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: dark, fontWeight: FontWeight.w900)),
                Text(primaryMetric, style: const TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
                Text(secondaryMetric, style: const TextStyle(color: muted, fontSize: 11)),
              ],
            ),
          ),
          Text(
            score.toStringAsFixed(0),
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
