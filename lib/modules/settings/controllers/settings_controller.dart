import 'package:venastudio/common.dart';
import 'package:venastudio/components/views/printing.dart';

final settingsServicesProvider =
    StateNotifierProvider<SettingsServiceNotifier, SettingsConfig>((ref) {
      final authService = ref.watch(authenticationServiceProvider);
      return SettingsServiceNotifier(ref: ref, authService: authService.value);
    });

class SettingsServiceNotifier extends StateNotifier<SettingsConfig> {
  SettingsServiceNotifier({required this.ref, required this.authService})
    : super(SettingsConfig.initial()) {
    if (authService != null) init();
  }
  final StateNotifierProviderRef<SettingsServiceNotifier, SettingsConfig> ref;

  final AuthData? authService;
  final _apiService = ApiProvider();

  Future<void> init() async {
    final response =
        await _apiService.post(
              '/get_settings.php',
              body: {'shop': authService?.user.shop},
            )
            as Map;
    final data = response['data'] as Map<String, dynamic>;
    final showDiscount = data['discount'] == '1';
    final payFirst = data['pay_first'] == '1';
    final showRegister = data['show_register'] == '1';
    final showSummary = data['show_summary'] == '1';
    final createAttendant = data['create_attendant'] == '1';
    final trackStock = data['track_stock'] == '1';
    await LocalStorage.nosql.updateShowDiscount(showDiscount);
    await LocalStorage.nosql.updatePayFirst(payFirst);
    await LocalStorage.nosql.updateShowCashRegister(showRegister);
    await LocalStorage.nosql.updateShowSummary(showSummary);
    await LocalStorage.nosql.updateCreateAttendant(createAttendant);
    await LocalStorage.nosql.updateTrackStock(trackStock);
    state = state.copyWith(
      showDiscount: showDiscount,
      payFirst: payFirst,
      loading: false,
      showCashRegister: showRegister,
      showSummary: showSummary,
      trackStock: trackStock,
      createAttendant: createAttendant,
    );
  }

  Future<void> changeShowDiscount() async {
    state = state.copyWith(loading: true);
    final newValue = !state.showDiscount;
    await _apiService.post(
      '/update_settings.php',
      body: {
        'shop': authService?.user.shop,
        'action': 'discount',
        'value': newValue ? '1' : '0',
      },
    );
    state = state.copyWith(showDiscount: newValue, loading: false);
    LocalStorage.nosql.updateShowDiscount(newValue);
  }

  Future<void> changePayFirst() async {
    state = state.copyWith(loading: true);
    final newValue = !state.payFirst;
    await _apiService.post(
      '/update_settings.php',
      body: {
        'shop': authService?.user.shop,
        'action': 'pay_first',
        'value': newValue ? '1' : '0',
      },
    );
    state = state.copyWith(payFirst: newValue, loading: false);
    LocalStorage.nosql.updatePayFirst(newValue);
  }

  Future<void> changeshowSummary() async {
    state = state.copyWith(loading: true);
    final newValue = !state.showSummary;
    await _apiService.post(
      '/update_settings.php',
      body: {
        'shop': authService?.user.shop,
        'action': 'show_summary',
        'value': newValue ? '1' : '0',
      },
    );
    state = state.copyWith(showSummary: newValue, loading: false);
    LocalStorage.nosql.updateShowSummary(newValue);
  }

  Future<void> changeshowCommissions() async {
    state = state.copyWith(loading: true);
    final newValue = !state.showSummary;
    await _apiService.post(
      '/update_settings.php',
      body: {
        'shop': authService?.user.shop,
        'action': 'show_commissions',
        'value': newValue ? '1' : '0',
      },
    );
    state = state.copyWith(showCommissions: newValue, loading: false);
    LocalStorage.nosql.updateShowCommissions(newValue);
  }

  Future<void> changecashRegister() async {
    state = state.copyWith(loading: true);
    final newValue = !state.showCashRegister;
    await _apiService.post(
      '/update_settings.php',
      body: {
        'shop': authService?.user.shop,
        'action': 'show_register',
        'value': newValue ? '1' : '0',
      },
    );
    state = state.copyWith(showCashRegister: newValue, loading: false);
    LocalStorage.nosql.updateShowCashRegister(newValue);
  }

  Future<void> changeCreateAttendant() async {
    state = state.copyWith(loading: true);
    final newValue = !state.createAttendant;
    await _apiService.post(
      '/update_settings.php',
      body: {
        'shop': authService?.user.shop,
        'action': 'create_attendant',
        'value': newValue ? '1' : '0',
      },
    );
    state = state.copyWith(createAttendant: newValue, loading: false);
    LocalStorage.nosql.updateCreateAttendant(newValue);
  }

  Future<void> changeTrackStock() async {
    state = state.copyWith(loading: true);
    final newValue = !state.trackStock;
    await _apiService.post(
      '/update_settings.php',
      body: {
        'shop': authService?.user.shop,
        'action': 'track_stock',
        'value': newValue ? '1' : '0',
      },
    );
    state = state.copyWith(trackStock: newValue, loading: false);
    LocalStorage.nosql.updateTrackStock(newValue);
  }

  Future<void> changeScreenLock() async {
    state = state.copyWith(loading: true);
    final newValue = !state.screenLock;
    await LocalStorage.nosql.updateScreenLock(newValue);
    state = state.copyWith(screenLock: newValue, loading: false);
  }

  void selectPrinter(Printer printer) {
    state = state.copyWith(printer: printer);
  }

  void selectBluetoothPrinter(BluetoothDevice printer) {
    state = state.copyWith(bluetoothPrinter: printer);
  }

  void print({String? ticket, bool isTest = false, double? ttProce}) {
    if (state.printer != null || state.bluetoothPrinter != null) {
      final shop = ref
          .read(authenticationServiceProvider)
          .value
          ?.user
          .storeName;
      final Map<String, dynamic>? details;
      if (isTest) {
        details = null;
      } else {
        final items = ref.read(cartServiceProvider).items;
        details = {
          'total_price': ttProce?.money ?? 'Ksh 0.00',
          'items': items
              .map((e) => {'name': e.name, 'quantity': e.quantity})
              .toList(),
        };
      }
      if (state.bluetoothPrinter != null) {
        printBluetoothReceipt(
          state.bluetoothPrinter!,
          ticket: ticket,
          shop: shop,
          details: details,
        );
      } else {
        printReceipt(
          state.printer!,
          ticket: ticket,
          shop: shop,
          details: details,
        );
      }
    }
  }
}

void selectBluetoothPrinter(BluetoothDevice pinter) {}
