import 'package:flutter_svg/svg.dart';
import 'package:venastudio/common.dart';

extension PlaceHolderOnContext on BuildContext {
  Future<void> loading(Color barrierColor) {
    return showDialog<void>(
      barrierDismissible: false,
      barrierColor: barrierColor.withOpacity(0.7),
      context: this,
      builder: (_) {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void showToast(String message, {required Color textColor, bool? error}) {
    final toaster = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: (error ?? false) ? Colors.red : Colors.green,
      showCloseIcon: true,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      content: Text(
        message,
        style: TextStyle(color: textColor, fontSize: 16),
        textAlign: TextAlign.start,
      ),
    );
    ScaffoldMessenger.of(this).showSnackBar(toaster);
  }
}

Widget emptyState(WidgetRef ref, {String? text, VoidCallback? onRefresh}) {
  final theme = ref.watch(themeServicesProvider);
  final isDark = theme.secondaryBackGround.computeLuminance() < 0.5;
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          isDark
              ? 'assets/images/empty_light.svg'
              : 'assets/images/empty_dark.svg',
          width: 150,
        ),
        if (text != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textIconPrimaryColor),
            ),
          ),
        if (onRefresh != null)
          IconButton(
            onPressed: onRefresh,
            icon: Icon(
              Icons.refresh_rounded,
              color: theme.textIconPrimaryColor,
            ),
          ),
      ],
    ),
  );
}

class SelectItem extends StatelessWidget {
  const SelectItem({super.key, required this.items});
  final List<String> items;

  static Future<String?> show(BuildContext context, List<String> items) {
    return showDialog<String>(
      context: context,
      builder: (_) {
        return SelectItem(items: items);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Material(
          borderRadius: BorderRadius.circular(10),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(items.length, (index) {
                final item = items[index];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop(item);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(item),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
