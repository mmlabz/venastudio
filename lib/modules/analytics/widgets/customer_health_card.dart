import 'package:venastudio/common.dart';

class CustomerHealthCard extends StatelessWidget {
  const CustomerHealthCard({
    super.key,
    required this.customer,
  });

  final CustomerHealth customer;

  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color line = Color(0xffCFEFF4);
  static const Color teal = Color(0xff43C5D8);
  static const Color danger = Color(0xffD94B4B);
  static const Color amber = Color(0xffF4A62A);
  static const Color success = Color(0xff13A76B);

  Color get statusColor {
    if (customer.healthScore >= 75) return success;
    if (customer.healthScore >= 60) return teal;
    if (customer.healthScore >= 40) return amber;
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: statusColor.withOpacity(.12),
            child: Text(
              customer.healthScore.toStringAsFixed(0),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.customerName,
                  style: const TextStyle(
                    color: dark,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${customer.status} • Return ${customer.returnProbability.toStringAsFixed(0)}% • Churn ${customer.churnProbability.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  customer.recommendation,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                customer.revenueAtRisk.money,
                style: TextStyle(
                  color: customer.revenueAtRisk > 0 ? danger : success,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Risk Value',
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
