import 'package:venastudio/common.dart';

class ForecastCard extends StatelessWidget {
  const ForecastCard({
    super.key,
    required this.forecast,
    this.money = false,
  });

  final Forecast forecast;
  final bool money;

  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color line = Color(0xffCFEFF4);
  static const Color teal = Color(0xff43C5D8);
  static const Color danger = Color(0xffD94B4B);
  static const Color amber = Color(0xffF4A62A);
  static const Color success = Color(0xff13A76B);

  Color get color {
    final t = forecast.trend.toLowerCase();
    if (t.contains('up') || t.contains('growth')) return success;
    if (t.contains('down') || t.contains('drop')) return danger;
    return teal;
  }

  IconData get icon {
    final t = forecast.trend.toLowerCase();
    if (t.contains('up') || t.contains('growth')) return Icons.trending_up_rounded;
    if (t.contains('down') || t.contains('drop')) return Icons.trending_down_rounded;
    return Icons.trending_flat_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final value = money ? forecast.value.money : forecast.value.toStringAsFixed(0);

    return Container(
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
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(forecast.title, style: const TextStyle(color: dark, fontWeight: FontWeight.w900)),
              Text(
                forecast.period.isEmpty ? forecast.description : forecast.period,
                style: const TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
              ),
              if (forecast.confidence > 0)
                Text(
                  'Confidence ${forecast.confidence.toStringAsFixed(0)}%',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
            ]),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 17),
          ),
        ],
      ),
    );
  }
}
