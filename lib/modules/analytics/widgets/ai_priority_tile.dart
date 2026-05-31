import 'package:venastudio/common.dart';

class AiPriorityTile extends StatelessWidget {
  const AiPriorityTile({
    super.key,
    required this.action,
  });

  final AiAction action;

  static const Color dark = Color(0xff07304A);
  static const Color muted = Color(0xff668392);
  static const Color line = Color(0xffCFEFF4);
  static const Color teal = Color(0xff43C5D8);
  static const Color danger = Color(0xffD94B4B);
  static const Color amber = Color(0xffF4A62A);

  Color get color {
    if (action.isHighPriority) return danger;
    if (action.priority.toLowerCase().contains('medium')) return amber;
    return teal;
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
            child: Icon(Icons.bolt_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(action.title, style: const TextStyle(color: dark, fontWeight: FontWeight.w900)),
              Text(action.message, style: const TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
              if (action.recommendedAction.isNotEmpty)
                Text(
                  'Action: ${action.recommendedAction}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
                ),
            ]),
          ),
          if (action.estimatedImpact > 0)
            Text(
              action.estimatedImpact.money,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
        ],
      ),
    );
  }
}
