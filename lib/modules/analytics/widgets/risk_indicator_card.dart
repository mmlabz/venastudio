import 'package:venastudio/common.dart';

class RiskIndicatorCard extends StatelessWidget {
  const RiskIndicatorCard({
    super.key,
    required this.risk,
  });

  final RiskIndicator risk;

  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color line = Color(0xffCFEFF4);
  static const Color teal = Color(0xff43C5D8);
  static const Color danger = Color(0xffD94B4B);
  static const Color amber = Color(0xffF4A62A);
  static const Color success = Color(0xff13A76B);

  Color get color {
    final level = risk.level.toLowerCase();
    if (level.contains('high') || level.contains('critical')) return danger;
    if (level.contains('medium')) return amber;
    if (level.contains('low')) return teal;
    return success;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(.12),
            child: Icon(Icons.shield_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(risk.title, style: const TextStyle(color: dark, fontWeight: FontWeight.w900)),
              Text(risk.message, style: const TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
            ]),
          ),
          Text(
            risk.level,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
