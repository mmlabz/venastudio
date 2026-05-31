import 'package:venastudio/common.dart';

class RetentionGauge extends StatelessWidget {
  const RetentionGauge({
    super.key,
    required this.value,
    this.label = 'Retention',
  });

  final double value;
  final String label;

  static const Color teal = Color(0xff43C5D8);
  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color danger = Color(0xffD94B4B);
  static const Color amber = Color(0xffF4A62A);
  static const Color success = Color(0xff13A76B);

  Color get color {
    if (value >= 70) return success;
    if (value >= 50) return teal;
    if (value >= 35) return amber;
    return danger;
  }

  @override
  Widget build(BuildContext context) {
    final normalized = (value.clamp(0, 100)) / 100;

    return Column(
      children: [
        SizedBox(
          height: 132,
          width: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 132,
                width: 132,
                child: CircularProgressIndicator(
                  value: normalized,
                  strokeWidth: 13,
                  backgroundColor: color.withOpacity(.12),
                  color: color,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${value.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 23,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
