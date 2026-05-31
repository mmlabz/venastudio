import 'package:venastudio/common.dart';
import 'package:venastudio/modules/inventory/controllers/inventory_controller.dart';

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red : Colors.black87,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

class CustomerAgentScreen extends ConsumerStatefulWidget {
  final bool isAgent;

  const CustomerAgentScreen({super.key, required this.isAgent});

  @override
  ConsumerState<CustomerAgentScreen> createState() =>
      _CustomerAgentScreenState();
}

class _CustomerAgentScreenState extends ConsumerState<CustomerAgentScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String input = '';
  bool _isAgent = false;
  bool isLoading = false;

  static const Color neon = Color(0xff00EAF5);
  static const Color dark = Color(0xff05080A);
  static const Color textWhite = Color(0xffF6FBFF);
  static const Color muted = Color(0xff9CB6C1);

  @override
  void initState() {
    super.initState();
    _isAgent = widget.isAgent;

    final phone = ref.read(cartServiceProvider).phone;
    if (!_isAgent && phone != null && phone.isNotEmpty) {
      input = phone;
      _controller.text = phone;
    }

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int get maxLength => _isAgent ? 6 : 10;
  bool get canConfirm => input.length == maxLength;

  String get displayTitle => _isAgent ? 'Enter PIN' : 'Customer Phone';

  String get displaySubtitle => _isAgent
      ? 'Type or use keypad to enter your 6-digit PIN'
      : 'Type or use keypad to enter customer phone number';

  Future<void> _signOut() async {
    try {
      LocalStorage.nosql.activeAgent = null;
      LocalStorage.nosql.screenLock = false;

      await ref.read(authenticationServiceProvider.notifier).logout();

      if (!mounted) return;

      context.go('/sign_in');
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, 'Unable to sign out', error: true);
    }
  }

  void _syncInput(String value) {
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = clean.length > maxLength
        ? clean.substring(0, maxLength)
        : clean;

    setState(() {
      input = limited;
      _controller.text = limited;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: limited.length),
      );
    });
  }

  void _updateInput(String value) {
    if (input.length >= maxLength || isLoading) return;

    final newValue = input + value;

    setState(() {
      input = newValue;
      _controller.text = newValue;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: newValue.length),
      );
    });

    HapticFeedback.lightImpact();
  }

  void _removeLastDigit() {
    if (input.isEmpty || isLoading) return;

    final newValue = input.substring(0, input.length - 1);

    setState(() {
      input = newValue;
      _controller.text = newValue;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: newValue.length),
      );
    });

    HapticFeedback.mediumImpact();
  }

  void _clearInput() {
    if (isLoading) return;

    setState(() {
      input = '';
      _controller.clear();
    });

    _focusNode.requestFocus();
    HapticFeedback.heavyImpact();
  }

  Future<void> _onConfirm() async {
    if (!canConfirm || isLoading) return;

    setState(() => isLoading = true);

    if (_isAgent) {
      try {
        var agentsAsyncValue = ref.read(agentsServicesProvider);

        if (agentsAsyncValue is AsyncLoading) {
          await ref.read(agentsServicesProvider.notifier).init();
          if (!mounted) return;
          agentsAsyncValue = ref.read(agentsServicesProvider);
        }

        final agents = agentsAsyncValue.value ?? <Agent>[];

        final agentUsing = agents
            .where((a) => a.pin.toString().trim() == input.trim())
            .firstOrNull;

        if (agentUsing == null) {
          showAppSnack(context, 'Wrong pin', error: true);

          if (!mounted) return;

          setState(() {
            isLoading = false;
            input = '';
            _controller.clear();
          });

          _focusNode.requestFocus();
          return;
        }

        if (agentUsing.archived) {
          showAppSnack(context, 'Agent is archived', error: true);

          if (!mounted) return;

          setState(() {
            isLoading = false;
            input = '';
            _controller.clear();
          });

          _focusNode.requestFocus();
          return;
        }

        final baseUser = LocalStorage.nosql.user;

        ref.read(cartServiceProvider.notifier).mainAgent = agentUsing;

        LocalStorage.nosql.activeAgent = {
          'id': agentUsing.id,
          'name': agentUsing.name,
          'email': agentUsing.email,
          'phone': agentUsing.phone,
          'pin': agentUsing.pin.toString(),
          'type': agentUsing.type,

          // STORE / BRANCH
          'storeName': agentUsing.store,
          'storeId': agentUsing.shop?.toString(),

          // COMPANY
          'shop': baseUser?.shop,

          'industry': baseUser?.industry,
          'merchant': baseUser?.merchant,
          'paybill': baseUser?.paybill,
          'pay_url': baseUser?.payUrl,
          'subscription_status': baseUser?.subscriptionStatus,
        };

        debugPrint('ACTIVE AGENT SAVED => ${LocalStorage.nosql.activeAgent}');

        LocalStorage.nosql.screenLock = false;

        ref.invalidate(inventoryServicesProvider);

        if (!mounted) return;

        setState(() => isLoading = false);
        context.go('/');
      } catch (_) {
        if (!mounted) return;

        showAppSnack(context, 'Unable to verify PIN', error: true);

        setState(() {
          isLoading = false;
          input = '';
          _controller.clear();
        });

        _focusNode.requestFocus();
      }

      return;
    }

    ref.read(cartServiceProvider.notifier).clientPhone = input;

    if (!mounted) return;

    setState(() => isLoading = false);
    context.go('/');
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
            center: Alignment(0.48, -0.28),
            radius: 1.15,
            colors: [Color(0xff0A2B31), Color(0xff061217), Color(0xff010203)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              if (isDesktop)
                Positioned.fill(
                  child: CustomPaint(painter: _VenaBackgroundPainter()),
                ),

              Positioned(
                top: 8,
                right: 10,
                child: Tooltip(
                  message: 'Sign out',
                  child: IconButton(
                    onPressed: isLoading ? null : _signOut,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: neon,
                      size: 26,
                    ),
                  ),
                ),
              ),

              isDesktop ? _desktopLayout() : _mobileLayout(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopLayout() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(70, 38, 30, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Center(child: _brandBlock(center: false)),
                const SizedBox(height: 54),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isAgent
                      ? 'Enter your 6-digit PIN to continue'
                      : 'Enter customer phone number to continue',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                _inputPreview(maxWidth: _isAgent ? 400 : 410),
                const SizedBox(height: 34),
                _securityBox(),
                const Spacer(),
                const Text(
                  '© 2026 Vena Studio. All rights reserved.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Transform.translate(
              offset: const Offset(-28, 0),
              child: _pinPanel(desktop: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              _brandBlock(center: true),
              const SizedBox(height: 24),
              Text(
                displayTitle,
                style: const TextStyle(
                  color: textWhite,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                displaySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _inputPreview(maxWidth: double.infinity),
              const SizedBox(height: 18),
              _pinPanel(desktop: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pinPanel({required bool desktop}) {
    return Container(
      width: desktop ? 420 : double.infinity,
      padding: EdgeInsets.all(desktop ? 22 : 18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(desktop ? 32 : 24),
        border: Border.all(color: neon.withOpacity(0.72), width: 1.15),
        boxShadow: [
          BoxShadow(
            color: neon.withOpacity(0.10),
            blurRadius: 18,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _lockIcon(),
          const SizedBox(height: 10),
          Text(
            displayTitle,
            style: const TextStyle(
              color: textWhite,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displaySubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 90,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: LinearGradient(
                colors: [neon.withOpacity(0.12), neon, neon.withOpacity(0.12)],
              ),
            ),
          ),
          const SizedBox(height: 18),
          NumericKeyboard(
            onKeyboardTap: _updateInput,
            rightButtonFn: _removeLastDigit,
            rightButtonLongPressFn: _clearInput,
            desktop: desktop,
            rightIcon: const Icon(
              Icons.backspace_outlined,
              color: neon,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          _confirmButton(),
        ],
      ),
    );
  }

  Widget _brandBlock({required bool center}) {
    return SizedBox(
      width: center ? double.infinity : 430,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: center ? 86 : 94,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 14),
          const Text(
            'V E N A   S T U D I O',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textWhite,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 7,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'S E R V I C E   R E D E F I N E D',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: neon,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockIcon() {
    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: neon.withOpacity(0.08),
        border: Border.all(color: neon.withOpacity(0.45)),
      ),
      child: Icon(
        _isAgent ? Icons.lock_outline_rounded : Icons.phone_iphone_rounded,
        color: neon,
        size: 24,
      ),
    );
  }

  Widget _inputPreview({required double maxWidth}) {
    if (!_isAgent) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          height: 56,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: !isLoading,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(maxLength),
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textWhite,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '07XXXXXXXX',
              hintStyle: TextStyle(color: muted.withOpacity(0.55)),
              filled: true,
              fillColor: Colors.black.withOpacity(0.24),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: canConfirm ? neon : neon.withOpacity(0.25),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: neon, width: 1.6),
              ),
            ),
            onChanged: _syncInput,
            onSubmitted: (_) {
              if (canConfirm && !isLoading) _onConfirm();
            },
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !isLoading,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(maxLength),
                ],
                onChanged: _syncInput,
                onSubmitted: (_) {
                  if (canConfirm && !isLoading) _onConfirm();
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(maxLength, (index) {
                final filled = index < input.length;
                final active = index == input.length && !canConfirm;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 52,
                  width: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(filled ? 0.30 : 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: filled || active ? neon : neon.withOpacity(0.25),
                      width: filled || active ? 1.5 : 1,
                    ),
                    boxShadow: filled || active
                        ? [
                            BoxShadow(
                              color: neon.withOpacity(0.22),
                              blurRadius: 9,
                            ),
                          ]
                        : const [],
                  ),
                  child: Text(
                    filled ? '•' : '',
                    style: const TextStyle(
                      color: neon,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _securityBox() {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: neon.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: neon.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: neon.withOpacity(0.38)),
            ),
            child: const Icon(Icons.shield_outlined, color: neon, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Your security is our priority.\nKeep your PIN confidential.',
              style: TextStyle(
                color: textWhite,
                height: 1.4,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmButton() {
    final text = canConfirm
        ? 'CONFIRM'
        : _isAgent
        ? 'DIAL PIN'
        : 'DIAL PHONE';

    return InkWell(
      onTap: canConfirm && !isLoading ? _onConfirm : null,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: canConfirm
              ? const LinearGradient(
                  colors: [
                    Color(0xff043A40),
                    Color(0xff00BFD8),
                    Color(0xff043A40),
                  ],
                )
              : null,
          color: canConfirm ? null : Colors.black.withOpacity(0.22),
          border: Border.all(color: canConfirm ? neon : neon.withOpacity(0.25)),
          boxShadow: canConfirm
              ? [
                  BoxShadow(
                    color: neon.withOpacity(0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : const [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        color: canConfirm ? Colors.white : muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                      ),
                    ),
                    if (canConfirm) ...[
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _VenaBackgroundPainter extends CustomPainter {
  static const Color neon = Color(0xff00EAF5);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.22, -size.height * 0.10)
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.20,
        size.width * 0.20,
        size.height * 0.82,
        size.width * 0.35,
        size.height * 1.20,
      );

    final glowPaint = Paint()
      ..color = neon.withOpacity(0.07)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    final linePaint = Paint()
      ..color = neon.withOpacity(0.36)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

typedef KeyboardTapCallback = void Function(String text);

class NumericKeyboard extends StatelessWidget {
  final TextStyle textStyle;
  final Widget? rightIcon;
  final Function()? rightButtonFn;
  final Function()? rightButtonLongPressFn;
  final KeyboardTapCallback onKeyboardTap;
  final bool desktop;

  const NumericKeyboard({
    super.key,
    required this.onKeyboardTap,
    this.textStyle = const TextStyle(color: Colors.white),
    this.rightButtonFn,
    this.rightButtonLongPressFn,
    this.rightIcon,
    this.desktop = false,
  });

  static const Color neon = Color(0xff00EAF5);
  static const Color textWhite = Color(0xffF6FBFF);
  static const Color muted = Color(0xff9CB6C1);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final buttonWidth = desktop
        ? 94.0
        : screenWidth < 380
        ? 74.0
        : 88.0;
    final buttonHeight = desktop
        ? 62.0
        : screenWidth < 380
        ? 60.0
        : 68.0;

    const spacing = 10.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(['1', '2', '3'], buttonWidth, buttonHeight, spacing),
        const SizedBox(height: 8),
        _row(['4', '5', '6'], buttonWidth, buttonHeight, spacing),
        const SizedBox(height: 8),
        _row(['7', '8', '9'], buttonWidth, buttonHeight, spacing),
        const SizedBox(height: 8),
        _row(['bio', '0', 'del'], buttonWidth, buttonHeight, spacing),
      ],
    );
  }

  Widget _row(
    List<String> values,
    double width,
    double height,
    double spacing,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: values.map((value) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: value == 'bio'
              ? _iconBox(
                  width,
                  height,
                  const Icon(Icons.fingerprint_rounded, color: neon, size: 28),
                )
              : value == 'del'
              ? _iconBox(
                  width,
                  height,
                  rightIcon ??
                      const Icon(
                        Icons.backspace_outlined,
                        color: neon,
                        size: 24,
                      ),
                  onTap: rightButtonFn,
                  onLongPress: rightButtonLongPressFn,
                )
              : _numberBox(value, width, height),
        );
      }).toList(),
    );
  }

  Widget _numberBox(String value, double width, double height) {
    return InkWell(
      onTap: () => onKeyboardTap(value),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: width,
        height: height,
        decoration: _keyDecoration(strong: false),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: textStyle.copyWith(
                color: textWhite,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (value != '1') ...[
              const SizedBox(height: 1),
              Text(
                _letters(value),
                style: const TextStyle(
                  color: muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconBox(
    double width,
    double height,
    Widget icon, {
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: width,
        height: height,
        decoration: _keyDecoration(strong: true),
        child: Center(child: icon),
      ),
    );
  }

  BoxDecoration _keyDecoration({required bool strong}) {
    return BoxDecoration(
      color: Colors.black.withOpacity(strong ? 0.28 : 0.22),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: strong ? neon.withOpacity(0.58) : neon.withOpacity(0.34),
      ),
    );
  }

  String _letters(String value) {
    switch (value) {
      case '2':
        return 'ABC';
      case '3':
        return 'DEF';
      case '4':
        return 'GHI';
      case '5':
        return 'JKL';
      case '6':
        return 'MNO';
      case '7':
        return 'PQRS';
      case '8':
        return 'TUV';
      case '9':
        return 'WXYZ';
      case '0':
        return '+';
      default:
        return '';
    }
  }
}
