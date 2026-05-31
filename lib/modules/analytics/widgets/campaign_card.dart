import 'package:venastudio/common.dart';

class CampaignCard extends StatelessWidget {
  const CampaignCard({
    super.key,
    required this.name,
    required this.revenue,
    required this.customers,
    required this.discount,
    required this.conversionRate,
  });

  final String name;
  final double revenue;
  final int customers;
  final double discount;
  final double conversionRate;

  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color line = Color(0xffCFEFF4);
  static const Color teal = Color(0xff43C5D8);
  static const Color success = Color(0xff13A76B);
  static const Color danger = Color(0xffD94B4B);

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
            backgroundColor: teal.withOpacity(.12),
            child: const Icon(Icons.campaign_rounded, color: teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: dark, fontWeight: FontWeight.w900)),
              Text(
                '$customers customers • Conversion ${conversionRate.toStringAsFixed(1)}%',
                style: const TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
              ),
              Text(
                'Discount cost ${discount.money}',
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ]),
          ),
          Text(
            revenue.money,
            style: const TextStyle(color: success, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
