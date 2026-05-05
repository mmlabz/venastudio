import 'package:venastudio/common.dart';

class PasswordPAge extends ConsumerStatefulWidget {
  const PasswordPAge({super.key});

  @override
  ConsumerState<PasswordPAge> createState() => _PasswordPAgeState();
}

class _PasswordPAgeState extends ConsumerState<PasswordPAge> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      context.go('/customer_screen?isAgent=true');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
