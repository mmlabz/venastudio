import 'package:venastudio/common.dart';

extension ServiceBookContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  MediaQueryData get mq => MediaQuery.of(this);
  Size get sz => MediaQuery.sizeOf(this);
  EdgeInsets get pd => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);
  double get height => mq.size.height;
  double get width => mq.size.width;
  bool get isdarkmode => theme.brightness == Brightness.dark;

  Widget backIcon(WidgetRef ref, VoidCallback onTap) {
    final themeColor = ref.watch(themeServicesProvider).textIconPrimaryColor;
    return IconButton(
      onPressed: onTap,
      icon: Icon(Icons.arrow_back_ios_new_rounded, color: themeColor),
    );
  }

  Widget bacEmpty(WidgetRef ref) {
    final themeColor = ref.watch(themeServicesProvider).textIconPrimaryColor;
    return IconButton(
      onPressed: null,
      icon: Icon(Icons.arrow_back_ios_new_rounded, color: themeColor),
    );
  }
}

enum SrceenType {
  mobile,
  desktop;

  bool get isMobile => this == SrceenType.mobile;
  bool get isDesktop => this == SrceenType.desktop;

  static double mobileWidth = 599;
  static double mainMaxWidth = 500;

  static SrceenType type(Size size) {
    return size.width < mobileWidth ? SrceenType.mobile : SrceenType.desktop;
  }
}

double getMaxWidth(double width) {
  return width > SrceenType.mainMaxWidth ? SrceenType.mainMaxWidth : width;
}

String? phoneValidation(String? value) {
  if (value?.length != 10) return 'Invalid phone number';
  if (value?[0] != '0') return 'Invalid phone number';
  return null;
}

String? codeValidation(String? value) {
  if (value?.length != 10) return 'Invalid code number';
  return null;
}
