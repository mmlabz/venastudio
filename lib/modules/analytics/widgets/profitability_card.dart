import 'package:venastudio/common.dart';

class ProfitabilityCard extends StatelessWidget {
  const ProfitabilityCard({
    super.key,
    required this.serviceName,
    required this.revenue,
    required this.materialCost,
    required this.commissionCost,
    required this.discountCost,
  });

  final String serviceName;
  final double revenue;
  final double materialCost;
  final double commissionCost;
  final double discountCost;

  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color line = Color(0xffCFEFF4);
  static const Color teal = Color(0xff43C5D8);
  static const Color danger = Color(0xffD94B4B);
  static const Color amber = Color(0xffF4A62A);
  static const Color success = Color(0xff13A76B);

  double get grossProfit => revenue - materialCost - commissionCost - discountCost;
  double get margin => revenue <= 0 ? 0 : (grossProfit / revenue) * 100;

  Color get marginColor {
    if (margin >= 55) return success;
    if (margin >= 35) return teal;
    if (margin >= 20) return amber;
    return danger;
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
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: marginColor.withOpacity(.12),
                child: Icon(Icons.sell_rounded, color: marginColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  serviceName,
                  style: const TextStyle(
                    color: dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '${margin.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: marginColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          _row('Revenue', revenue.money, success),
          _row('Materials', materialCost.money, danger),
          _row('Commission', commissionCost.money, amber),
          _row('Discounts', discountCost.money, danger),
          const Divider(height: 18),
          _row('Gross Profit', grossProfit.money, marginColor, bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: muted,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
              fontSize: bold ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
