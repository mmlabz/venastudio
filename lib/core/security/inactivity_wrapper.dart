import 'dart:async';
import 'package:venastudio/common.dart';

class InactivityWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const InactivityWrapper({super.key, required this.child});

  @override
  ConsumerState<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends ConsumerState<InactivityWrapper> {
  Timer? _timer;

  static const Duration timeout = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  void _resetTimer() {
    _timer?.cancel();

    _timer = Timer(timeout, () {
      final user = LocalStorage.nosql.user;
      if (user == null) return;
      if (LocalStorage.nosql.screenLock) return;

      // 🔥 CLEAR AGENT SESSION
      LocalStorage.nosql.activeAgent = null;

      // 🔒 LOCK SCREEN
      LocalStorage.nosql.screenLock = true;

      if (!mounted) return;

      ref.read(appRouterProvider).go('/customer_screen?isAgent=true');
    });
  }

  void _onActivity([PointerEvent? event]) {
    final agent = LocalStorage.nosql.activeAgent;
    final user = agent != null
        ? ServiceUser.fromMap(agent)
        : LocalStorage.nosql.user;
    if (user == null) return;
    if (LocalStorage.nosql.screenLock) return;

    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onActivity,
      onPointerMove: _onActivity,
      onPointerSignal: _onActivity,
      child: widget.child,
    );
  }
}
