import 'package:venastudio/common.dart';

class WelcomeRedirectPage extends StatefulWidget {
  const WelcomeRedirectPage({super.key});

  @override
  State<WelcomeRedirectPage> createState() => _WelcomeRedirectPageState();
}

class _WelcomeRedirectPageState extends State<WelcomeRedirectPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.go('/customer_screen?isAgent=true');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
