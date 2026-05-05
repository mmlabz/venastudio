import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

extension MyDoubles on double {
  String get money {
    return '''Ksh ${toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}.${((this * 100).roundToDouble() % 100).toInt().toString().padLeft(2, '0')}''';
  }

  String get moneyNumber {
    return '''${toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}.${((this * 100).roundToDouble() % 100).toInt().toString().padLeft(2, '0')}''';
  }

  String get money0 {
    return '''Ksh ${toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}''';
  }
}

extension MyStrings on String? {
  String get value {
    return this ?? '';
  }
}

String sDate(DateTime dateTime) {
  final formatter = DateFormat('yyyy-MM-dd');
  return formatter.format(dateTime);
}

String sDate2(DateTime dateTime) {
  return DateFormat.MMMEd().format(dateTime);
}

String sDate3(DateTime dateTime) {
  return DateFormat.MMMEd().add_jm().format(dateTime);
}

String sDate4(DateTime dateTime) {
  return DateFormat.yMMMMd().add_jm().format(dateTime);
}

bool isdesktop() {
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS || kIsWeb;
}
