import 'package:venastudio/common.dart';

class InventoryHealthCard extends StatelessWidget {
  const InventoryHealthCard({
    super.key,
    required this.name,
    required this.quantity,
    required this.reorderLevel,
    this.subtitle = '',
  });

  final String name;
  final double quantity;
  final double reorderLevel;
  final String subtitle;

  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color line = Color(0xffCFEFF4);
  static const Color teal = Color(0xff43C5D8);
  static const Color danger = Color(0xffD94B4B);
  static const Color amber = Color(0xffF4A62A);
  static const Color success = Color(0xff13A76B);

  bool get low => quantity <= reorderLevel;
  Color get color => low ? danger : success;

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
            child: Icon(low ? Icons.warning_amber_rounded : Icons.inventory_2_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: dark, fontWeight: FontWeight.w900)),
              Text(
                subtitle.isEmpty ? 'Reorder at ${reorderLevel.toStringAsFixed(0)}' : subtitle,
                style: const TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ]),
          ),
          Text(
            quantity.toStringAsFixed(0),
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
