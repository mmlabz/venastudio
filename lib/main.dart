import 'dart:io';
import 'package:venastudio/common.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage().initialize();
  // if (Platform.isAndroid || Platform.isIOS) {
  //   OneSignal.initialize('3e759c9e-1198-4f74-8afa-4a8e123e2b92');
  // }
  if (Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.normal,
        windowButtonVisibility: true,
      );
      await windowManager.setMinimumSize(const Size(500, 600));
      await windowManager.show();
      await windowManager.setPreventClose(true);
      await windowManager.setSkipTaskbar(false);
    });
  }
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'venastudio',
      restorationScopeId: 'venastudio',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      builder: (context, child) {
        return InactivityWrapper(child: child ?? const SizedBox.shrink());
      },
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}
