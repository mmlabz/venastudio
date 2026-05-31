import 'dart:convert';
import 'dart:io';

import 'package:venastudio/common.dart';

final cartServiceProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  final authService = ref.watch(authenticationServiceProvider);
  return CartNotifier(authService: authService.valueOrNull, ref: ref);
});

class CartNotifier extends StateNotifier<Cart> {
  CartNotifier({required this.ref, required this.authService})
    : super(Cart.empty());

  final StateNotifierProviderRef<CartNotifier, Cart> ref;
  final AuthData? authService;
  final _apiService = ApiProvider();

  add(Savis savis) {
    final prev = state.items;
    final exists = prev.indexWhere((element) => element.id == savis.id);

    if (exists == -1) {
      final dateStart = DateTime.tryParse(savis.discountStartDate.toString());
      final dateEnd = DateTime.tryParse(savis.discountEndDate.toString());
      final dateNow = DateTime.now();
      final pdisc = savis.discount.toString();
      final prevDisc = pdisc != 'null' ? pdisc : null;

      num newdisc = 0;

      if (dateStart != null && dateEnd != null && prevDisc != null) {
        if (dateNow.isAfter(dateStart) && dateNow.isBefore(dateEnd)) {
          newdisc = num.tryParse(prevDisc) ?? 0;
        }
      }

      final newSavis = savis.copyWith(quantity: 1, discount: newdisc);
      state = state.copyWith(items: [...prev, newSavis]);
    } else {
      prev[exists] = savis.copyWith(quantity: prev[exists].quantity + 1);
      state = state.copyWith(items: prev);
    }
  }

  void addAddon({
    required int savisId,
    required List<Map<String, dynamic>> addons,
  }) {
    final oldAddons = state.addons;
    oldAddons.removeWhere((element) => element['mainServiceId'] == savisId);
    state = state.copyWith(addons: [...addons, ...oldAddons]);
  }

  void changeQnty(Savis savis, num qnty) {
    if (qnty >= 1) {
      final prev = state.items;
      final exists = prev.indexWhere((element) => element.id == savis.id);
      prev[exists] = savis.copyWith(quantity: qnty);
      state = state.copyWith(items: prev);
    }
  }

  remove(Savis savis) {
    final prev = state.items;
    prev.removeWhere((element) => element.id == savis.id);
    state = state.copyWith(items: prev);
  }

  clearState() {
    state = Cart.empty();
  }

  set mainAgent(Agent agent) {
    state = state.copyWith(mainAgent: agent);
  }

  set mainShop(Map<dynamic, dynamic> shop) {
    state = state.copyWith(shop: shop);
  }

  set clientPhone(String phone) {
    state = state.copyWith(phone: phone);
  }

  set bookingDate(DateTime? date) {
    state = state.copyWith(bookingDate: date);
  }

  clearBookingDate() {
    state = state.copyWith(emptyBookingDate: true);
  }

  set agent(MapEntry<String, Map<String, String>> value) {
    final prev = state.assigned ?? {};
    prev.addEntries({value});
    state = state.copyWith(assigned: prev);
  }

  setDiscount(Savis savis, num disc) {
    final prev = state.items;
    final exists = prev.indexWhere((element) => element.id == savis.id);
    prev[exists] = savis.copyWith(discount: disc);
    state = state.copyWith(items: prev);
  }

  Future<void> createOrder({
    required double totalPrice,
    bool payFirst = false,
    String? orderType,
    String? reference,
    List<String>? code,
    String? type,
    double? cashAdd,
  }) async {
    if (authService == null) return;

    final activeAgent = LocalStorage.nosql.activeAgent;

    final ServiceUser? user = activeAgent != null
        ? ServiceUser.fromMap(activeAgent)
        : authService?.user;

    if (user == null) return;
    final phn = (state.phone ?? '').replaceFirst('0', '+254');
    final allAssigned = state.assigned ?? {};
    final mainAgent = state.mainAgent;
    final settings = ref.read(settingsServicesProvider);
    final queueEnabled = settings.trackQueue;
    final smartAssignmentEnabled =
        settings.trackStock || settings.trackAttendance || settings.trackQueue;

    String assign = mainAgent != null ? '1' : '';

    final cart = state.items.map((e) {
      final assigned = allAssigned['${e.id}'];

      if (assigned != null) {
        assign = '1';
      }

      final discount = num.tryParse(e.discount);

      return {
        'cartId': 0,
        'id': e.id,
        'name': e.name,
        'date': '',
        'shop': num.tryParse(user.shop ?? '0') ?? 0,
        'amount': e.amount,
        'quantity': e.quantity,
        'originalPrice': e.amount,
        'image': 'https://storage.googleapis.com/shopi_express/receipts/',
        // Service-level assignment wins. Main agent is only a manual legacy fallback.
        // Never use the logged-in user automatically as the assigned beautician.
        'agentName': assigned?['agentName'] ?? mainAgent?.name ?? '',
        'agentId': '${assigned?['agentId'] ?? mainAgent?.id ?? -1}',
        'smartAssignment': assigned?['smartAssignment'] ?? '',
        'assignmentPayload': assigned?['smartAssignment'] ?? '',
        'type': 'Main',
        'isDiscount': discount != null && discount > 0,
        'discounted': discount,
        'commission': e.commission ?? 0.0,
        'services': [],
      };
    }).toList();

    final shop = user.type == SUPERADMIN_TYPE_NAME
        ? '${state.shop?['name'] ?? ''}'
        : '${user.storeName ?? ''}';

    final payUrl = user.type != SUPERADMIN_TYPE_NAME
        ? '${user.payUrl ?? ''}'
        : '${state.shop?['pay_url'] ?? ''}';

    final mode = payFirst ? 'Before' : 'After';

    final Map<String, String> body = {
      'pay_url': payUrl,
      'mode': mode,
      'assign': assign,
      'queue_enabled': queueEnabled ? '1' : '0',
      'track_queue': queueEnabled ? '1' : '0',
      'smart_assignment_enabled': smartAssignmentEnabled ? '1' : '0',
      'track_stock': settings.trackStock ? '1' : '0',
      'track_attendance': settings.trackAttendance ? '1' : '0',
      'cart_addon': jsonEncode(state.addons),
      'addon_agents': '[]',
      'shop': '${user.shop ?? ''}',
      'user': '${user.name ?? ''}',
      'assigned_by_id': '${user.id}',
      'created_by_id': '${user.id}',
      'assigned_by_name': '${user.name ?? ''}',
      'created_by_name': '${user.name ?? ''}',
      'cart': jsonEncode(cart),
      'phone': phn,
      'total': totalPrice.toStringAsFixed(2),
      'store': shop,
      'agent': state.mainAgent?.name ?? '',
      'id': '${state.mainAgent?.id ?? -1}',
    };

    if (state.bookingDate != null) {
      body['booking_date'] = state.bookingDate!.toUtc().toString();
    }

    if (payFirst) {
      body['order_type'] = orderType ?? '';
      body['amount'] = totalPrice.toStringAsFixed(1);
      body['order_amount'] = totalPrice.toStringAsFixed(1);
      body['ref'] = reference ?? '';
      body['type'] = type ?? '';
      body['mpesa'] = '0';
      body['cash_add'] = cashAdd?.toStringAsFixed(1) ?? '0';

      if (orderType == 'code' && code != null && code.isNotEmpty) {
        body['codes'] = jsonEncode([
          ...code.map((e) => {'amount': totalPrice, 'code': e}),
        ]);
      } else {
        body['codes'] = '';
      }

      if (orderType == 'Equity') {
        body['equity'] = totalPrice.toStringAsFixed(0);
      }
    }

    final res = await _apiService.post('/create_order.php', body: body);
    final ticket = res['ticket']?.toString() ?? '';

    if (ticket.isNotEmpty &&
        ticket != 'null' &&
        (Platform.isWindows || Platform.isAndroid)) {
      ref
          .read(settingsServicesProvider.notifier)
          .print(ticket: ticket, ttProce: totalPrice);
    }

    ref.invalidate(orderServicesProvider);
  }
}
