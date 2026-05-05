import 'package:venastudio/common.dart';

class SecureScreen extends StatefulWidget {
  final ValueChanged<String> onConfirm;
  final String placeholder;

  const SecureScreen({
    super.key,
    required this.onConfirm,
    required this.placeholder,
  });

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  String input = "";
  bool isLoading = false;
  final TextEditingController _controller = TextEditingController();

  static const Color neon = Color(0xff00EAF5);
  static const Color dark = Color(0xff05080A);
  static const Color textWhite = Color(0xffF6FBFF);
  static const Color muted = Color(0xff9CB6C1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateInput(String value) {
    if (input.length >= 6 || isLoading) return;

    setState(() {
      input += value;
      _controller.text = '•' * input.length;
    });

    HapticFeedback.lightImpact();
  }

  void _removeLastDigit() {
    if (input.isEmpty || isLoading) return;

    setState(() {
      input = input.substring(0, input.length - 1);
      _controller.text = '•' * input.length;
    });

    HapticFeedback.mediumImpact();
  }

  void _clearInput() {
    if (isLoading) return;

    setState(() {
      input = "";
      _controller.clear();
    });

    HapticFeedback.heavyImpact();
  }

  void _onConfirm() async {
    if (input.isEmpty || isLoading) return;

    setState(() => isLoading = true);

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() => isLoading = false);

    widget.onConfirm(input);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: dark,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.55, -0.35),
            radius: 1.25,
            colors: [Color(0xff10333B), Color(0xff07161C), Color(0xff020304)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 20,
                vertical: 20,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _securePanel(desktop: isDesktop),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _securePanel({required bool desktop}) {
    return Container(
      padding: EdgeInsets.all(desktop ? 34 : 22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(desktop ? 34 : 26),
        border: Border.all(color: neon.withOpacity(0.55), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: neon.withOpacity(0.26),
            blurRadius: 38,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _lockIcon(),
          const SizedBox(height: 18),
          const Text(
            'Secure Access',
            style: TextStyle(
              color: textWhite,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.placeholder,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _pinBoxes(),
          const SizedBox(height: 28),
          NumericKeyboard(
            onKeyboardTap: _updateInput,
            rightButtonFn: _removeLastDigit,
            rightButtonLongPressFn: _clearInput,
            desktop: desktop,
            rightIcon: const Icon(
              Icons.backspace_outlined,
              color: neon,
              size: 25,
            ),
          ),
          const SizedBox(height: 26),
          _confirmButton(),
        ],
      ),
    );
  }

  Widget _lockIcon() {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: neon.withOpacity(0.08),
        border: Border.all(color: neon.withOpacity(0.45)),
        boxShadow: [BoxShadow(color: neon.withOpacity(0.3), blurRadius: 22)],
      ),
      child: const Icon(Icons.lock_outline_rounded, color: neon, size: 30),
    );
  }

  Widget _pinBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        final filled = index < input.length;
        final active = index == input.length && input.length < 6;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 62,
          width: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(filled ? 0.075 : 0.035),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: filled || active ? neon : neon.withOpacity(0.22),
              width: filled || active ? 1.6 : 1,
            ),
            boxShadow: filled || active
                ? [BoxShadow(color: neon.withOpacity(0.42), blurRadius: 18)]
                : [],
          ),
          child: Text(
            filled ? '•' : '',
            style: const TextStyle(
              color: neon,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      }),
    );
  }

  Widget _confirmButton() {
    final canConfirm = input.isNotEmpty;

    return InkWell(
      onTap: canConfirm && !isLoading ? _onConfirm : null,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: canConfirm
              ? const LinearGradient(
                  colors: [Color(0xff00DDEB), Color(0xff00AFC8)],
                )
              : null,
          color: canConfirm ? null : Colors.white.withOpacity(0.055),
          border: Border.all(color: canConfirm ? neon : neon.withOpacity(0.25)),
          boxShadow: canConfirm
              ? [
                  BoxShadow(
                    color: neon.withOpacity(0.55),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 21,
                  width: 21,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'CONFIRM',
                  style: TextStyle(
                    color: canConfirm ? Colors.white : muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                  ),
                ),
        ),
      ),
    );
  }
}
