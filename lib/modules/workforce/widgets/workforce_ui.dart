import 'package:venastudio/common.dart';

const Color wfBg = Color(0xffEEF9FB);
const Color wfSurface = Colors.white;
const Color wfTeal = Color(0xff00BFD8);
const Color wfTealDark = Color(0xff00A6BB);
const Color wfDark = Color(0xff07304A);
const Color wfMuted = Color(0xff6B8794);
const Color wfLine = Color(0xffD8F3F7);
const Color wfDanger = Color(0xffD94B4B);
const Color wfSuccess = Color(0xff13A76B);
const Color wfAmber = Color(0xffF39C12);

class WfShell extends StatelessWidget {
  const WfShell({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.padding = const EdgeInsets.all(16),
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: wfBg,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: wfBg,
        foregroundColor: wfDark,
        title: Text(
          title,
          style: const TextStyle(
            color: wfDark,
            fontWeight: FontWeight.w900,
            letterSpacing: -.3,
          ),
        ),
        actions: actions,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffEEF9FB), Color(0xffF8FDFF)],
          ),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class WfCard extends StatelessWidget {
  const WfCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: padding,
            decoration: BoxDecoration(
              color: wfSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: wfLine),
              boxShadow: [
                BoxShadow(
                  color: wfTeal.withOpacity(.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class WfGradientCard extends StatelessWidget {
  const WfGradientCard({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [wfTeal, wfTealDark],
            ),
            boxShadow: [
              BoxShadow(
                color: wfTeal.withOpacity(.22),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class WfIconBox extends StatelessWidget {
  const WfIconBox({super.key, required this.icon, this.color = wfTeal});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(.11),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

class WfPrimaryButton extends StatelessWidget {
  const WfPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: compact ? 16 : 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: wfTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 10 : 14,
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class WfGhostButton extends StatelessWidget {
  const WfGhostButton({super.key, required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: wfDark,
        side: const BorderSide(color: wfLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class WfEmpty extends StatelessWidget {
  const WfEmpty({super.key, required this.icon, required this.title, required this.message, this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: WfCard(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(color: wfTeal.withOpacity(.12), borderRadius: BorderRadius.circular(24)),
              child: Icon(icon, color: wfTeal, size: 34),
            ),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: wfDark, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: wfMuted, fontWeight: FontWeight.w700)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class WfTextField extends StatelessWidget {
  const WfTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: wfLine)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: wfLine)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: wfTeal, width: 1.4)),
      ),
    );
  }
}

class WfChip extends StatelessWidget {
  const WfChip({super.key, required this.label, this.color = wfTeal});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }
}

Future<bool?> wfConfirm(BuildContext context, String title, String message) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: wfDark)),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Proceed')),
      ],
    ),
  );
}

String wfDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String wfShortDate(String raw) {
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
}
