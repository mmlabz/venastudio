import 'dart:convert';

import 'package:venastudio/common.dart';

final isUpdatingOrderProvider = StateProvider<bool>((ref) => false);

final updateCartServiceProvider =
    StateNotifierProvider<UpdateCartNotifier, Cart>((ref) {
      final authService = ref.watch(authenticationServiceProvider);
      return UpdateCartNotifier(authService: authService.value, ref: ref);
    });

class UpdateCartNotifier extends StateNotifier<Cart> {
  UpdateCartNotifier({required this.ref, required this.authService})
    : super(Cart.empty());
  final StateNotifierProviderRef<UpdateCartNotifier, Cart> ref;
  final AuthData? authService;
  final _apiService = ApiProvider();

  void load({required String orderId}) {
    final order = ref
        .read(orderServicesProvider)
        .orders
        .where((element) => element['id'].toString() == orderId)
        .firstOrNull;
    if (order != null) {
      final items = List<Map>.from(order['orderItems'] as List);
      final savises = <Savis>[];
      for (final item in items) {
        final savis = Savis(
          id: item['id'],
          name: item['name'],
          amount: item['price'],
          hours: 1,
          minutes: 1,
          quantity: item['items'],
          discount: item['discount'].toString(),
          type: 'Main',
        );
        savises.add(savis);
      }
      state = state.copyWith(items: savises);
    }
  }

  remove(Savis savis) {
    final prev = state.items;
    prev.removeWhere((element) => element.id == savis.id);
    state = state.copyWith(items: prev);
  }

  setDiscount(Savis savis, num disc) {
    final prev = state.items;
    final exists = prev.indexWhere((element) => element.id == savis.id);
    prev[exists] = savis.copyWith(discount: disc);
    state = state.copyWith(items: prev);
  }

  set agent(MapEntry<String, Map<String, String>> value) {
    final prev = state.assigned ?? {};
    prev.addEntries({value});
    state = state.copyWith(assigned: prev);
  }

  void changeQnty(Savis savis, num qnty) {
    if (qnty >= 1) {
      final prev = state.items;
      final exists = prev.indexWhere((element) => element.id == savis.id);
      prev[exists] = savis.copyWith(quantity: qnty);
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

  Future<void> updateIt({required String orderId}) async {
    final user = authService!.user;
    final fullorder = ref
        .read(orderServicesProvider)
        .orders
        .where((element) => element['id'].toString() == orderId)
        .firstOrNull;
    final fullItems = List<Map>.from(fullorder?['orderItems'] as List? ?? []);
    final List<Map<String, dynamic>> cart;
    if (fullItems.isNotEmpty) {
      final allAssigned = state.assigned ?? {};
      cart = state.items.map((e) {
        final assigned = allAssigned['${e.id}'];
        final fullItem = fullItems.firstWhere(
          (element) => element['id'] == e.id,
          orElse: () => {},
        );
        final discount = num.tryParse(e.discount);
        return {
          'cartId': fullItem['cartId'] ?? 0,
          'id': e.id,
          'name': e.name,
          'date': '',
          // 'shop': num.tryParse(user.shop ?? '0') ?? '0',
          'amount': e.amount,
          'quantity': e.quantity,
          'price': e.amount,
          'originalPrice': e.amount,
          // 'image': 'https://storage.googleapis.com/shopi_express/receipts/',
          'agentName': assigned?['agentName'] ?? fullItem['agent'] ?? '',
          'agentId': assigned?['agentId'] ?? '${fullItem['userid'] ?? -1}',
          'smartAssignment': assigned?['smartAssignment'] ?? '',
          'assignmentPayload': assigned?['smartAssignment'] ?? '',
          'type': 'Main',
          'isDiscount': discount != null && discount > 0,
          'discounted': discount,
          // 'commission': e.commission ?? 0.0,
          'services': [],
        };
      }).toList();
    } else {
      cart = [];
    }

    final ttp = ServiceCartPage.calculateTotalPrice(state.items);

    final body = {
      'mode': fullorder?['mode'] ?? '',
      'order': fullorder?['billno'] ?? '',
      // 'assign': assign,
      'cart_addon': jsonEncode(state.addons),
      // 'addon_agents': '[]',
      'shop': user.shop,
      'user': '${user.name}',
      'cart': jsonEncode(cart),
      'phone': fullorder?['customer'] ?? '',
      'total': ttp.toStringAsFixed(2),
      'store': fullorder?['store'].toString() ?? '',
      'agent': state.mainAgent?.name ?? '',
      'agent_id': (fullorder?['agentid'] ?? -1).toString(),
      // if (state.bookingDate != null)
      //   'booking_date': state.bookingDate!.toUtc().toString(),
      // if (mode == 'Before') ...{
      //   'order_type': orderType,
      //   'amount': totalPrice.toStringAsFixed(1),
      //   if (orderType == 'code' && code != null)
      //     'codes': jsonEncode([
      //       ...code.map(
      //         (e) => {"amount": totalPrice, 'code': e},
      //       )
      //     ])
      //   else
      //     'codes': '',
      //   'ref': reference ?? '',
      //   'order_amount': totalPrice.toStringAsFixed(1),
      //   'type': type ?? '',
      //   'mpesa': '0',
      //   if (cashAdd != null)
      //     'cash_add': cashAdd.toStringAsFixed(1)
      //   else
      //     'cash_add': '0',
      //   if (orderType == 'Equity') 'equity': totalPrice.toStringAsFixed(0),
      // }
    };

    await _apiService.post('/new_update_cart.php', body: body);
  }
}
