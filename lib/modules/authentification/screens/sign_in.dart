import 'dart:ui';
import 'package:venastudio/common.dart';

class SigninPage extends ConsumerStatefulWidget {
  const SigninPage({super.key});

  @override
  ConsumerState<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends ConsumerState<SigninPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool obscureText = true;
  bool isLoading = false;
  bool rememberMe = true;

  static const Color neon = Color(0xff00E5FF);
  static const Color neonDark = Color(0xff00B7C9);
  static const Color errorSoft = Color(0xffFF6B6B);
  static const Color darkBg = Color(0xff020507);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeServicesProvider);

    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.86),
                    Colors.black.withOpacity(0.58),
                    Colors.black.withOpacity(0.45),
                  ],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.16),
                    Colors.black.withOpacity(0.30),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: -170,
            right: -120,
            child: _GlowOrb(size: 430, color: neon.withOpacity(0.13)),
          ),

          Positioned(
            bottom: -210,
            left: -170,
            child: _GlowOrb(size: 500, color: neon.withOpacity(0.10)),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isDesktop = constraints.maxWidth >= 950;

                if (!isDesktop) {
                  return _MobileLayout();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 72,
                    vertical: 42,
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 43, child: _BrandPanel()),
                      const SizedBox(width: 70),
                      Expanded(
                        flex: 57,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: _LoginCard(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _MobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LogoBox(size: 86),
            const SizedBox(height: 18),
            _BrandWordmark(centered: true, size: 20, spacing: 4.8),
            const SizedBox(height: 8),
            _Tagline(centered: true),
            const SizedBox(height: 22),
            const _SystemCapabilities(compact: true),
            const SizedBox(height: 24),
            _LoginCard(),
          ],
        ),
      ),
    );
  }

  Widget _BrandPanel() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // ✅ CENTER EVERYTHING
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LogoBox(size: 118),

          const SizedBox(height: 24),

          _BrandWordmark(
            centered: true, // ✅ already supported in your code
            size: 27,
            spacing: 8,
          ),

          const SizedBox(height: 10),

          _Tagline(centered: true),

          const SizedBox(height: 42),

          RichText(
            textAlign: TextAlign.center, // ✅ IMPORTANT
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Smart studio control\n',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                TextSpan(
                  text: 'for ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 30,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: 'beauty brands',
                  style: TextStyle(
                    color: neon,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    // shadows: [
                    //   Shadow(color: neon.withOpacity(0.70), blurRadius: 22),
                    // ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          const _SystemCapabilities(),
        ],
      ),
    );
  }

  Widget _LoginCard() {
    final bool compact = MediaQuery.of(context).size.width < 600;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? double.infinity : 438),
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 20 : 28,
              vertical: compact ? 22 : 26,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.038),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.085),
                  Colors.white.withOpacity(0.030),
                  Colors.black.withOpacity(0.24),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: neon.withOpacity(0.16),
                  blurRadius: 25,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.55),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WELCOME BACK',
                    style: TextStyle(
                      color: neon,
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.1,
                      fontFamily: 'Orbitron',
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    'Sign in',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 25 : 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Access your Vena Studio',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.58),
                      fontSize: compact ? 12 : 13,
                    ),
                  ),

                  SizedBox(height: compact ? 19 : 22),

                  _inputField(
                    controller: emailController,
                    label: 'Email',
                    hintText: 'email address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty ||
                          !value.contains('@')) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  _inputField(
                    controller: passwordController,
                    label: 'Password',
                    hintText: 'password',
                    icon: Icons.lock_outline,
                    obscureText: obscureText,
                    suffixIcon: IconButton(
                      splashRadius: 18,
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white.withOpacity(0.68),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => obscureText = !obscureText);
                      },
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty ||
                          value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() => rememberMe = !rememberMe);
                        },
                        child: Container(
                          height: 17,
                          width: 17,
                          decoration: BoxDecoration(
                            color: rememberMe ? neon : Colors.transparent,
                            border: Border.all(
                              color: rememberMe
                                  ? neon
                                  : Colors.white.withOpacity(0.35),
                            ),
                            boxShadow: rememberMe
                                ? [
                                    BoxShadow(
                                      color: neon.withOpacity(0.30),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : [],
                          ),
                          child: rememberMe
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.black,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Remember',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.66),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => context.go('/forgot_password'),
                        child: Text(
                          'Forgot?',
                          style: TextStyle(
                            color: neon,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _signinButton(compact: compact),

                  const SizedBox(height: 14),

                  _buildSignupOption(compact: compact),
                ],
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.10),
                      Colors.white.withOpacity(0.025),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            child: IgnorePointer(
              child: Container(
                height: 1,
                width: compact ? 120 : 165,
                color: Colors.white.withOpacity(0.42),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 1,
                width: compact ? 110 : 150,
                color: neon.withOpacity(0.36),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _LogoBox({required double size}) {
    return Container(
      height: size,
      width: size,
      padding: EdgeInsets.all(size * 0.055),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        // border: Border.all(color: neon.withOpacity(0.28), width: 1),
        // boxShadow: [
        //   BoxShadow(
        //     color: neon.withOpacity(0.22),
        //     blurRadius: 6,
        //     spreadRadius: 1,
        //   ),
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.55),
        //     blurRadius: 20,
        //     offset: const Offset(0, 12),
        //   ),
        // ],
      ),
      child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
    );
  }

  Widget _BrandWordmark({
    bool centered = false,
    double size = 28,
    double spacing = 8,
  }) {
    return Row(
      mainAxisAlignment: centered
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Text(
          'VENA',
          style: TextStyle(
            color: neon,
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: spacing,
            fontFamily: 'Orbitron',
            shadows: [Shadow(color: neon.withOpacity(0.60), blurRadius: 17)],
          ),
        ),
        SizedBox(width: size * 0.48),
        Text(
          'STUDIO',
          style: TextStyle(
            color: Colors.white,
            fontSize: size,
            fontWeight: FontWeight.w900,
            letterSpacing: spacing,
            fontFamily: 'Orbitron',
          ),
        ),
      ],
    );
  }

  Widget _Tagline({bool centered = false}) {
    return Text(
      'BEAUTY. AUTOMATED.',
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        color: Colors.white.withOpacity(0.62),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 3,
        fontFamily: 'Orbitron',
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.88),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          validator: validator,
          cursorColor: neon,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.34)),
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.78)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withOpacity(0.038),
            errorStyle: TextStyle(
              color: errorSoft.withOpacity(0.92),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 13,
              horizontal: 16,
            ),
            border: _inputBorder(Colors.white.withOpacity(0.16), 1),
            enabledBorder: _inputBorder(Colors.white.withOpacity(0.16), 1),
            focusedBorder: _inputBorder(neon.withOpacity(0.95), 1.4),
            errorBorder: _inputBorder(errorSoft.withOpacity(0.72), 1.1),
            focusedErrorBorder: _inputBorder(errorSoft.withOpacity(0.82), 1.2),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _inputBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _signinButton({required bool compact}) {
    return GestureDetector(
      onTap: isLoading ? null : signIn,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        height: compact ? 48 : 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? [neon.withOpacity(0.55), neonDark.withOpacity(0.55)]
                : const [neon, neonDark],
          ),
          boxShadow: [
            BoxShadow(
              color: neon.withOpacity(0.32),
              blurRadius: 22,
              spreadRadius: 1,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2.8,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 15),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSignupOption({required bool compact}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don’t have an account?",
          style: TextStyle(
            color: Colors.white.withOpacity(0.62),
            fontSize: compact ? 12 : 13,
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.only(left: 8),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => context.go('/sign_up'),
          child: Text(
            "Sign up",
            style: TextStyle(
              color: neon,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ),
      ],
    );
  }

  void signIn() {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    ref
        .read(authenticationServiceProvider.notifier)
        .newLogin(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        )
        .then((_) {
          if (mounted) setState(() => isLoading = false);
        })
        .onError((error, stackTrace) {
          if (mounted) setState(() => isLoading = false);

          if (GoRouter.of(context).canPop()) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }

          String errorMessage = "Unable to login. Please try again.";

          if (error is UnauthorisedException) {
            errorMessage = "Invalid email or password";
          } else if (error is FetchDataException) {
            errorMessage = error.toString();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: errorSoft,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        });
  }
}

class _SystemCapabilities extends StatelessWidget {
  final bool compact;

  const _SystemCapabilities({this.compact = false});

  static const Color neon = Color(0xff00E5FF);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: const [
          _CapBox(label: 'CONTROL'),
          _CapBox(label: 'INTELLIGENCE'),
          _CapBox(label: 'REVENUE'),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.055),
            Colors.white.withOpacity(0.015),
            Colors.black.withOpacity(0.10),
          ],
        ),
        boxShadow: [BoxShadow(color: neon.withOpacity(0.08), blurRadius: 18)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _CapItem(label: 'CONTROL'),
          _HudDivider(),
          _CapItem(label: 'INTELLIGENCE'),
          _HudDivider(),
          _CapItem(label: 'REVENUE'),
        ],
      ),
    );
  }
}

class _CapItem extends StatelessWidget {
  final String label;

  const _CapItem({required this.label});

  static const Color neon = Color(0xff00E5FF);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 2,
          fontWeight: FontWeight.w900,
          color: Colors.white.withOpacity(0.86),
          fontFamily: 'Orbitron',
          shadows: [Shadow(color: neon.withOpacity(0.42), blurRadius: 10)],
        ),
      ),
    );
  }
}

class _CapBox extends StatelessWidget {
  final String label;

  const _CapBox({required this.label});

  static const Color neon = Color(0xff00E5FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border.all(color: Colors.white.withOpacity(0.16), width: 1),
        boxShadow: [BoxShadow(color: neon.withOpacity(0.07), blurRadius: 12)],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w900,
          color: Colors.white.withOpacity(0.86),
          fontFamily: 'Orbitron',
        ),
      ),
    );
  }
}

class _HudDivider extends StatelessWidget {
  const _HudDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      width: 1,
      color: Colors.white.withOpacity(0.22),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.35,
              spreadRadius: size * 0.08,
            ),
          ],
        ),
      ),
    );
  }
}
