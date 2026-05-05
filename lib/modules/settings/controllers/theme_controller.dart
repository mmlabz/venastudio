import 'dart:convert';
import 'package:venastudio/common.dart';

final themeServicesProvider =
    StateNotifierProvider<ThemeServiceNotifier, ThemeConfig>((ref) {
      return ThemeServiceNotifier(ref: ref);
    });

class ThemeServiceNotifier extends StateNotifier<ThemeConfig> {
  final StateNotifierProviderRef<ThemeServiceNotifier, ThemeConfig> ref;

  static const _storageKey = 'custom_theme_config';

  bool _useCustomTheme = false;
  bool get useCustomTheme => _useCustomTheme;

  ThemeServiceNotifier({required this.ref}) : super(ThemeConfig.dark()) {
    _loadTheme(); // 👈 Load from storage on startup
  }

  void _markAsCustom() {
    _useCustomTheme = true;
    saveTheme(); // Save when marked custom
  }

  // THEME SETTERS (all mark as custom + save)
  void setPrimaryBackground(Color color) {
    _markAsCustom();
    state = state.copyWith(primaryBackGround: color);
  }

  void setSecondaryBackground(Color color) {
    _markAsCustom();
    state = state.copyWith(secondaryBackGround: color);
  }

  void setActiveBackground(Color color) {
    _markAsCustom();
    state = state.copyWith(activeBackGround: color);
  }

  void setInactiveBackground(Color color) {
    _markAsCustom();
    state = state.copyWith(inactiveBackGround: color);
  }

  void setActiveTextIconColor(Color color) {
    _markAsCustom();
    state = state.copyWith(activeTextIconColor: color);
  }

  void setInactiveTextIconColor(Color color) {
    _markAsCustom();
    state = state.copyWith(inactiveTextIconColor: color);
  }

  void setTextIconPrimaryColor(Color color) {
    _markAsCustom();
    state = state.copyWith(textIconPrimaryColor: color);
  }

  void setTextIconSecondaryColor(Color color) {
    _markAsCustom();
    state = state.copyWith(textIconSecondaryColor: color);
  }

  void setSearchTextIconColor(Color color) {
    _markAsCustom();
    state = state.copyWith(searchTextIconColor: color);
  }

  void setCardGradientStart(Color color) {
    _markAsCustom();
    state = state.copyWith(cardGradientStart: color);
  }

  void setCardGradientEnd(Color color) {
    _markAsCustom();
    state = state.copyWith(cardGradientEnd: color);
  }

  void setCardShadowColor(Color color) {
    _markAsCustom();
    state = state.copyWith(cardShadowColor: color);
  }

  void setCheckboxBorderColor(Color color) {
    _markAsCustom();
    state = state.copyWith(checkboxBorderColor: color);
  }

  void setDatePickerColor(Color color) {
    _markAsCustom();
    state = state.copyWith(datePickerColor: color);
  }

  void setDatePickerPrimaryColor(Color color) {
    _markAsCustom();
    state = state.copyWith(datePickerPrimaryColor: color);
  }

  void setDatePickerBackgroundColor(Color color) {
    _markAsCustom();
    state = state.copyWith(datePickerBackgroundColor: color);
  }

  void setDatePickerDialogBackgroundColor(Color color) {
    _markAsCustom();
    state = state.copyWith(datePickerDialogBackgroundColor: color);
  }

  void setDefaultColor(Color color) {
    _markAsCustom();
    state = state.copyWith(defultColor: color);
  }

  void setSuccessColor(Color color) {
    _markAsCustom();
    state = state.copyWith(successColor: color);
  }

  void setDeleteColor(Color color) {
    _markAsCustom();
    state = state.copyWith(deleteColor: color);
  }

  void setFullCustomTheme(ThemeConfig customConfig) {
    _useCustomTheme = true;
    state = customConfig;
    saveTheme();
  }

  void resetTheme() {
    _useCustomTheme = false;
    state = ThemeConfig.dark();
    saveTheme(); // Save reset
  }

  void toggleTheme() {
    _useCustomTheme = false;
    final isDark =
        state.primaryBackGround == ThemeConfig.dark().primaryBackGround;
    state = isDark ? ThemeConfig.light() : ThemeConfig.dark();
    saveTheme(); // Save toggled theme
  }

  /// ✅ Save theme to local storage
  Future<void> saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(state.toJson());
    await prefs.setString(_storageKey, jsonString);
  }

  /// ✅ Load theme from local storage
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      try {
        final jsonMap = jsonDecode(jsonString);
        state = ThemeConfig.fromJson(jsonMap);
        _useCustomTheme = true;
      } catch (_) {
        // Fallback on failure
        state = ThemeConfig.dark();
        _useCustomTheme = false;
      }
    }
  }
}
