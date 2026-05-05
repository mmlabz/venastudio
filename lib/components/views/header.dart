import 'package:venastudio/common.dart';

class Header extends ConsumerWidget {
  const Header({super.key, this.title, this.action, this.onBack});

  final String? title;
  final Widget? action;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeServicesProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        context.backIcon(ref, onBack ?? context.pop),
        if (title != null)
          Text(
            title!,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.textIconPrimaryColor,
            ),
          ),
        if (action != null) action! else const SizedBox(width: 30),
      ],
    );
  }
}
