import 'package:venastudio/common.dart';

class BusinessHealthBanner extends StatelessWidget {
  const BusinessHealthBanner({
    super.key,
    required this.health,
  });

  final BusinessHealth health;

  static const Color teal = Color(0xff43C5D8);
  static const Color danger = Color(0xffD94B4B);
  static const Color amber = Color(0xffF4A62A);
  static const Color success = Color(0xff13A76B);

  Color get color {
    if (health.score >= 80) return success;
    if (health.score >= 65) return teal;
    if (health.score >= 50) return amber;
    return danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(.72)]),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: Colors.white.withOpacity(.2),
            child: Text(
              health.score.toStringAsFixed(0),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                health.status,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
              ),
              const SizedBox(height: 4),
              Text(
                health.summary,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
