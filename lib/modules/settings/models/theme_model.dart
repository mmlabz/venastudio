import 'package:flutter/material.dart';

class ThemeConfig {
  final Brightness brightness;
  final Color primaryBackGround;
  final Color secondaryBackGround;
  final Color activeBackGround;
  final Color inactiveBackGround;
  final Color activeTextIconColor;
  final Color inactiveTextIconColor;
  final Color textIconPrimaryColor;
  final Color textIconSecondaryColor;
  final Color searchTextIconColor;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color cardShadowColor;
  final Color checkboxBorderColor;
  final Color datePickerColor;
  final Color datePickerPrimaryColor;
  final Color datePickerBackgroundColor;
  final Color datePickerDialogBackgroundColor;
  final Color defultColor;
  final Color successColor;
  final Color deleteColor;

  ThemeConfig({
    required this.brightness,
    required this.primaryBackGround,
    required this.secondaryBackGround,
    required this.activeBackGround,
    required this.inactiveBackGround,
    required this.activeTextIconColor,
    required this.inactiveTextIconColor,
    required this.textIconPrimaryColor,
    required this.textIconSecondaryColor,
    required this.searchTextIconColor,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.cardShadowColor,
    required this.checkboxBorderColor,
    required this.datePickerColor,
    required this.datePickerPrimaryColor,
    required this.datePickerBackgroundColor,
    required this.datePickerDialogBackgroundColor,
    required this.defultColor,
    required this.successColor,
    required this.deleteColor,
  });

  static ThemeConfig light() => ThemeConfig(
    brightness: Brightness.light,
    primaryBackGround: const Color(0xFF2832A4),
    secondaryBackGround: Colors.white,
    activeBackGround: const Color(0xFF00BFA5),
    inactiveBackGround: const Color(0xFFB0BEC5),
    activeTextIconColor: Colors.white,
    inactiveTextIconColor: Colors.white70,
    textIconPrimaryColor: Colors.black,
    textIconSecondaryColor: Colors.blueGrey,
    searchTextIconColor: Colors.white70,
    cardGradientStart: const Color(0xFF2832A4),
    cardGradientEnd: const Color(0xFF58A6FF),
    cardShadowColor: Colors.grey.shade200,
    checkboxBorderColor: const Color(0xFFB0BEC5),
    datePickerColor: const Color(0xFF2832A4),
    datePickerPrimaryColor: const Color(0xFF2832A4),
    datePickerBackgroundColor: Colors.white,
    datePickerDialogBackgroundColor: Colors.white,
    defultColor: Colors.black,
    successColor: const Color(0xFF00BFA5),
    deleteColor: const Color(0xFFC62828),
  );

  static ThemeConfig dark() => ThemeConfig(
    brightness: Brightness.dark,
    primaryBackGround: const Color(0xff1f2029),
    secondaryBackGround: const Color(0xff17181f),
    activeBackGround: Colors.deepOrangeAccent,
    inactiveBackGround: Colors.grey,
    activeTextIconColor: Colors.white,
    inactiveTextIconColor: Colors.white70,
    textIconPrimaryColor: Colors.white,
    textIconSecondaryColor: Colors.white54,
    searchTextIconColor: Colors.white70,
    cardGradientStart: const Color(0xff222831),
    cardGradientEnd: const Color(0xff393e46),
    cardShadowColor: Colors.black,
    checkboxBorderColor: const Color(0xFF757575),
    datePickerColor: const Color(0xff222831),
    datePickerPrimaryColor: const Color(0xFF6E7681),
    datePickerBackgroundColor: const Color(0xff1f2029),
    datePickerDialogBackgroundColor: const Color(0xff17181f),
    defultColor: Colors.black,
    successColor: const Color(0xFF81C784),
    deleteColor: const Color(0xFFEF5350),
  );

  ThemeConfig copyWith({
    Brightness? brightness,
    Color? primaryBackGround,
    Color? secondaryBackGround,
    Color? activeBackGround,
    Color? inactiveBackGround,
    Color? activeTextIconColor,
    Color? inactiveTextIconColor,
    Color? textIconPrimaryColor,
    Color? textIconSecondaryColor,
    Color? searchTextIconColor,
    Color? cardGradientStart,
    Color? cardGradientEnd,
    Color? cardShadowColor,
    Color? checkboxBorderColor,
    Color? datePickerColor,
    Color? datePickerPrimaryColor,
    Color? datePickerBackgroundColor,
    Color? datePickerDialogBackgroundColor,
    Color? defultColor,
    Color? successColor,
    Color? deleteColor,
  }) {
    return ThemeConfig(
      brightness: brightness ?? this.brightness,
      primaryBackGround: primaryBackGround ?? this.primaryBackGround,
      secondaryBackGround: secondaryBackGround ?? this.secondaryBackGround,
      activeBackGround: activeBackGround ?? this.activeBackGround,
      inactiveBackGround: inactiveBackGround ?? this.inactiveBackGround,
      activeTextIconColor: activeTextIconColor ?? this.activeTextIconColor,
      inactiveTextIconColor:
          inactiveTextIconColor ?? this.inactiveTextIconColor,
      textIconPrimaryColor: textIconPrimaryColor ?? this.textIconPrimaryColor,
      textIconSecondaryColor:
          textIconSecondaryColor ?? this.textIconSecondaryColor,
      searchTextIconColor: searchTextIconColor ?? this.searchTextIconColor,
      cardGradientStart: cardGradientStart ?? this.cardGradientStart,
      cardGradientEnd: cardGradientEnd ?? this.cardGradientEnd,
      cardShadowColor: cardShadowColor ?? this.cardShadowColor,
      checkboxBorderColor: checkboxBorderColor ?? this.checkboxBorderColor,
      datePickerColor: datePickerColor ?? this.datePickerColor,
      datePickerPrimaryColor:
          datePickerPrimaryColor ?? this.datePickerPrimaryColor,
      datePickerBackgroundColor:
          datePickerBackgroundColor ?? this.datePickerBackgroundColor,
      datePickerDialogBackgroundColor:
          datePickerDialogBackgroundColor ??
          this.datePickerDialogBackgroundColor,
      defultColor: defultColor ?? this.defultColor,
      successColor: successColor ?? this.successColor,
      deleteColor: deleteColor ?? this.deleteColor,
    );
  }

  Map<String, dynamic> toJson() => {
    'brightness': brightness.toString(),
    'primaryBackGround': primaryBackGround,
    'secondaryBackGround': secondaryBackGround,
    'activeBackGround': activeBackGround,
    'inactiveBackGround': inactiveBackGround,
    'activeTextIconColor': activeTextIconColor,
    'inactiveTextIconColor': inactiveTextIconColor,
    'textIconPrimaryColor': textIconPrimaryColor,
    'textIconSecondaryColor': textIconSecondaryColor,
    'searchTextIconColor': searchTextIconColor,
    'cardGradientStart': cardGradientStart,
    'cardGradientEnd': cardGradientEnd,
    'cardShadowColor': cardShadowColor,
    'checkboxBorderColor': checkboxBorderColor,
    'datePickerColor': datePickerColor,
    'datePickerPrimaryColor': datePickerPrimaryColor,
    'datePickerBackgroundColor': datePickerBackgroundColor,
    'datePickerDialogBackgroundColor': datePickerDialogBackgroundColor,
    'defultColor': defultColor,
    'successColor': successColor,
    'deleteColor': deleteColor,
  };

  factory ThemeConfig.fromJson(Map<String, dynamic> json) => ThemeConfig(
    brightness:
        json['brightness'] == 'Brightness.dark'
            ? Brightness.dark
            : Brightness.light,
    primaryBackGround: Color(json['primaryBackGround']),
    secondaryBackGround: Color(json['secondaryBackGround']),
    activeBackGround: Color(json['activeBackGround']),
    inactiveBackGround: Color(json['inactiveBackGround']),
    activeTextIconColor: Color(json['activeTextIconColor']),
    inactiveTextIconColor: Color(json['inactiveTextIconColor']),
    textIconPrimaryColor: Color(json['textIconPrimaryColor']),
    textIconSecondaryColor: Color(json['textIconSecondaryColor']),
    searchTextIconColor: Color(json['searchTextIconColor']),
    cardGradientStart: Color(json['cardGradientStart']),
    cardGradientEnd: Color(json['cardGradientEnd']),
    cardShadowColor: Color(json['cardShadowColor']),
    checkboxBorderColor: Color(json['checkboxBorderColor']),
    datePickerColor: Color(json['datePickerColor']),
    datePickerPrimaryColor: Color(json['datePickerPrimaryColor']),
    datePickerBackgroundColor: Color(json['datePickerBackgroundColor']),
    datePickerDialogBackgroundColor: Color(
      json['datePickerDialogBackgroundColor'],
    ),
    defultColor: Color(json['defultColor']),
    successColor: Color(json['successColor']),
    deleteColor: Color(json['deleteColor']),
  );
}
