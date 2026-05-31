import 'package:venastudio/common.dart';

class SettingsConfig {
  final bool showDiscount;
  final bool payFirst;
  final bool screenLock;
  final Printer? printer;
  final BluetoothDevice? bluetoothPrinter;
  final bool loading;
  final bool showSummary;
  final bool showCommissions;
  final bool showCashRegister;
  final bool createAttendant;
  final bool trackStock;
  final bool trackAttendance;
  final bool trackQueue;

  SettingsConfig({
    required this.showDiscount,
    required this.payFirst,
    required this.loading,
    required this.showSummary,
    required this.showCommissions,
    required this.showCashRegister,
    required this.createAttendant,
    required this.trackStock,
    required this.trackAttendance,
    required this.trackQueue,
    this.printer,
    this.bluetoothPrinter,
    this.screenLock = false,
  });

  factory SettingsConfig.initial() {
    final db = LocalStorage.nosql;
    return SettingsConfig(
      showDiscount: db.showDiscount,
      payFirst: db.payFirst,
      screenLock: db.screenLock,
      showSummary: db.showSummary,
      showCommissions: db.showCommissions,
      showCashRegister: db.showCashRegister,
      loading: true,
      createAttendant: db.createAttendant,
      trackStock: db.trackStock,
      trackAttendance: db.trackAttendance,
      trackQueue: db.trackQueue,
    );
  }

  SettingsConfig copyWith({
    bool? showDiscount,
    bool? payFirst,
    bool? screenLock,
    Printer? printer,
    bool? showSummary,
    bool? showCommissions,
    bool? showCashRegister,
    bool? loading,
    BluetoothDevice? bluetoothPrinter,
    bool? createAttendant,
    bool? trackStock,
    bool? trackAttendance,
    bool? trackQueue,
  }) {
    return SettingsConfig(
      showDiscount: showDiscount ?? this.showDiscount,
      payFirst: payFirst ?? this.payFirst,
      printer: (bluetoothPrinter == null) ? (printer ?? this.printer) : null,
      screenLock: screenLock ?? this.screenLock,
      showSummary: showSummary ?? this.showSummary,
      showCommissions: showCommissions ?? this.showCommissions,
      showCashRegister: showCashRegister ?? this.showCashRegister,
      loading: loading ?? this.loading,
      bluetoothPrinter: (printer == null)
          ? (bluetoothPrinter ?? this.bluetoothPrinter)
          : null,
      createAttendant: createAttendant ?? this.createAttendant,
      trackStock: trackStock ?? this.trackStock,
      trackAttendance: trackAttendance ?? this.trackAttendance,
      trackQueue: trackQueue ?? this.trackQueue,
    );
  }
}
