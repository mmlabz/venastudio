import 'package:venastudio/common.dart';

class FinanceKpiCard extends StatelessWidget {
  const FinanceKpiCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.subtitle = '',
  });

  final String label;
  final double amount;
  final String subtitle;
  final IconData icon;
  final Color color;

  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color line = Color(0xffCFEFF4);

  @override
  Widget build(BuildContext context) {
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
              Text(label, style: const TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12)),
              Text(amount.money, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
              if (subtitle.isNotEmpty)
                Text(subtitle, style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
    );
  }
}
