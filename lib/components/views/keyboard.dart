import 'package:venastudio/common.dart';

class TapToDismissKeyboard extends StatelessWidget {
  final Widget child;

  const TapToDismissKeyboard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final focus = FocusManager.instance.primaryFocus;
        if (focus != null && !focus.hasPrimaryFocus) {
          focus.unfocus();
        }
      },
      child: child,
    );
  }
}
