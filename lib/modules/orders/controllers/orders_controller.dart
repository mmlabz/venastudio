import 'dart:async';
import 'dart:convert';

import 'package:venastudio/common.dart';

final orderServicesProvider =
    StateNotifierProvider<OrderServiceNotifier, OrdersState>((ref) {
      final authService = ref.watch(authenticationServiceProvider);
      return OrderServiceNotifier(authService: authService);
    });

class OrderServiceNotifier extends StateNotifier<OrdersState> {
  OrderServiceNotifier({required this.authService})
    : super(OrdersState.initial(LocalStorage.nosql.orders)) {
    if (authService is! AsyncLoading) init();
  }

  final AsyncValue<AuthData> authService;
  final _apiService = ApiProvider();
  ServiceUser? get _user {
    final activeAgent = LocalStorage.nosql.activeAgent;

    if (activeAgent != null) {
      return ServiceUser.fromMap(activeAgent);
    }

    return authService.valueOrNull?.user ?? LocalStorage.nosql.user;
  }

  Future<void> init({(DateTime start, DateTime end)? range}) async {
    if (range != null) {
      state = OrdersLoading(orders: state.orders);
    }

    try {
      final user = _user;

      // Some backend endpoints treat `user` as an admin-like role and return
      // everything. In Vena Studio, `user` is employee-equivalent, so orders
      // requests must post the normalized backend role.
      final orderUserType = normalizeUserType(user?.type);

      final body = {
        'id': '${user?.id}',
        'industry': user?.industry,
        'shop': user?.shop,
        'type': orderUserType,
        'store': user?.storeName,
        'usertype': orderUserType,
        if (range != null) ...{
          'start': sDate(range.$1),
          'end': sDate(range.$2),
        },
      };
      final dynamic response = await _apiService.post(
        '/fetch_waiting.php',
        body: body,
      );
      final comms = List<Map>.from((response as List).map((e) => e as Map));
      state = OrdersLoaded(orders: comms);
      if (range == null) {
        LocalStorage.nosql.updateOrders(comms);
      }
    } catch (e) {
      if (mounted) {
        state = OrdersError(error: e.toString(), orders: state.orders);
      }
    }
  }

  Future<void> completeOrder({
    required Map<dynamic, dynamic> order,
    required String orderType,
    required String url,
    String? reference,
    List<String>? code,
    String? type,
    String? phonestk,
    double? cashAdd,
  }) async {
    final user = _user;
    if (user != null) {
      final amt = (order['amount'] as num);
      final body = {
        'merchant': user.merchant,
        'shop': user.shop,
        'user': '${user.name}',
        'order_mode': order['mode'],
        'agent_id': '${order['agentid']}',
        'result': '0',
        if (orderType == 'Equity') 'cash': '' else 'cash': '${order['amount']}',
        'order_type': orderType,
        'order_post': jsonEncode(order),
        'order': order['billno'],
        'agent': order['agentname'],
        'amount': amt.toStringAsFixed(1),
        if (orderType == 'code' && code != null)
          'codes': jsonEncode([
            ...code.map((e) => {"amount": amt, 'code': e}),
          ])
        else
          'codes': '',
        'ref': reference ?? '',
        'order_amount': amt.toStringAsFixed(1),
        'type': type ?? '',
        'mpesa': '0',
        if (cashAdd != null)
          'cash_add': cashAdd.toStringAsFixed(1)
        else
          'cash_add': '0',
        if (orderType == 'Equity') 'equity': amt.toStringAsFixed(0),
        if (orderType == 'stkpush') 'phone': phonestk,
      };
      final dynamic response = await _apiService.post(
        '/request.php',
        body: body,
      );
      if (response['code'] != 201) {
        throw 'Unable to complete';
      }
      return;
    }
  }

  Future<void> assignAgent({
    required Agent agent,
    required String billno,
    required num orderid,
  }) async {
    final user = _user;
    final body = {
      'user': '',
      'order': billno,
      'agent': agent.name,
      'id': '${agent.id}',
      'shop': user?.shop,
    };
    final res = await _apiService.post('/assign_order.php', body: body);
    final neworder = jsonDecode(res['data']) as Map;
    final oldorders = state.orders;
    oldorders.removeWhere((x) => x['id'] == orderid);
    final toupdate = [neworder, ...oldorders];
    state = OrdersLoaded(orders: toupdate);
    LocalStorage.nosql.updateOrders(toupdate);
  }

  Future<void> assignSingleAgent({
    required Agent agent,
    required String order,
    required String cartid,
  }) async {
    final body = {
      'state': 'single',
      'cart_id': cartid,
      'agent': agent.name,
      'id': '${agent.id}',
      'order': order,
      'user': '',
    };
    await _apiService.post('/assign_single.php', body: body);
  }

  Future<void> assignSingleSmart({
    required SmartServiceAssignmentResult result,
    required String order,
    required String cartid,
  }) async {
    final user = _user;
    final cartMap = result.toCartMap();
    final payload = result.payload;
    final trackQueue = '${payload['enforce_queue'] ?? payload['track_queue'] ?? '0'}' == '1';
    final trackStock = '${payload['track_stock'] ?? '0'}' == '1';
    final trackAttendance = '${payload['enforce_attendance'] ?? payload['track_attendance'] ?? '0'}' == '1';

    final body = {
      'company_id': user?.shop ?? '',
      'shop': user?.shop ?? '',
      'cart_id': cartid,
      'cart_item_id': cartid,
      'order_no': order,
      'order': order,
      'service_id': '${result.savis.id}',
      'employee_id': '${result.agent.id}',
      'employee_name': result.agent.name,
      'agent_id': '${result.agent.id}',
      'agent_name': result.agent.name,
      'assigned_by_id': '${user?.id ?? 0}',
      'created_by_id': '${user?.id ?? 0}',
      'assigned_by_name': user?.name ?? '',
      'created_by_name': user?.name ?? '',
      'user': user?.name ?? '',
      'smartAssignment': cartMap['smartAssignment'] ?? '',
      'assignmentPayload': cartMap['smartAssignment'] ?? '',
      'track_queue': trackQueue ? '1' : '0',
      'queue_enabled': trackQueue ? '1' : '0',
      'track_stock': trackStock ? '1' : '0',
      'track_attendance': trackAttendance ? '1' : '0',
      'smart_assignment_enabled': (trackStock || trackAttendance || trackQueue) ? '1' : '0',
    };

    await _apiService.post('/workforce/smart_assign_existing_service.php', body: body);
  }

  Future<void> removeAddon({
    required String order,
    required String cartid,
    required String addonid,
  }) async {
    final user = _user;
    final body = {
      'user': user?.name ?? '',
      'shop': user?.shop ?? '',
      'order': order,
      'cart_id': cartid,
      'addon_id': addonid,
    };
    await _apiService.post('/remove_addon.php', body: body);
  }

  Future<void> rescheduleOrder({
    required String order,
    required DateTime date,
  }) async {
    final user = _user;
    final body = {
      'bill_no': order,
      'date_rescheduled': sDate(date),
      'store': user?.storeName ?? '',
      'shop': user?.shop ?? '',
    };
    await _apiService.post('/remove_addon.php', body: body);
  }

  Future<void> addService({
    required num orderId,
    required List<Savis> savises,
  }) async {
    final user = _user;
    final order = state.orders
        .where((element) => element['id'] == orderId)
        .firstOrNull;
    final cart = savises.map((e) {
      return {
        'cartId': 0,
        'id': e.id,
        'name': e.name,
        'date': '',
        'shop': num.tryParse(user?.shop ?? '0') ?? '0',
        'amount': e.amount,
        'quantity': e.quantity,
        'originalPrice': e.amount,
        'image': 'https://storage.googleapis.com/shopi_express/receipts/',
        'agentName': '${order?['agentname']}',
        'agentId': '${order?['agentid']}',
        'type': 'Main',
        'isDiscount': true,
        'discounted': 10.0,
        'commission': e.commission ?? 0.0,
        'services': [],
      };
    }).toList();
    final totalPrice = _calculateTotalPrice(savises);
    final body = {
      'mode': 'After',
      'assign': '',
      'cart_addon': '[]',
      'addon_agents': '[]',
      'shop': user?.shop,
      'user': '${user?.id}',
      'cart': jsonEncode(cart),
      'phone': '',
      'total': totalPrice.toStringAsFixed(2),
      'store': '${order?['store']}',
      'agent': '${order?['agentname']}',
      'id': '0',
      'agent_id': '${order?['agentid']}',
      'mainid': '${order?['id']}',
      'order': '${order?['billno']}',
      'order_post': jsonEncode(order),
      'amount': '${order?['amount']}',
    };
    await _apiService.post('/update_cart.php', body: body);
  }

  double _calculateTotalPrice(List<Savis> cartitems) {
    final tt = cartitems.fold(0.0, (previousValue, element) {
      final discount = num.tryParse(element.discount) ?? 0;
      final hasdiscount = discount > 0;
      if (hasdiscount) {
        return ((element.amount - discount) * element.quantity) + previousValue;
      }
      return (element.amount * element.quantity) + previousValue;
    });
    return tt;
  }

  Future<void> updateAddon({
    required num orderId,
    required num mainServiceId,
    required Map<String, Agent> agents,
    required List<Savis> addons,
  }) async {
    final user = _user;
    final order = state.orders
        .where((element) => element['id'] == orderId)
        .firstOrNull;
    final orderItems = (order?['orderItems'] as List<dynamic>?);
    final service = orderItems
        ?.where((element) => element['id'] == mainServiceId)
        .firstOrNull;

    final adsrv = addons.map((e) {
      return jsonEncode({
        'id': agents['${e.id}-${e.quantity}']?.id ?? '-1',
        'name': agents['${e.id}-${e.quantity}']?.name ?? '',
        'serviceId': '${e.id}',
        'mainServiceId': '$mainServiceId',
        'serviceName': e.name,
        'serviceType': 'Addon',
        'quantity': e.quantity,
        'amount': '${e.amount}',
        'price': e.amount,
        'agents': [],
      });
    }).toList();
    final body = {
      'mode': 'After',
      'assign': '1',
      'cart_addon': '$adsrv',
      'addon_agents': '[]',
      'shop': user?.shop,
      'user': '${user?.id}',
      'mainid': '${service?['cartid']}',
      'order': '${order?['billno']}',
      'cart': '[]',
      'phone': '',
      if (((order?['agentname'] as String?) ?? '').isNotEmpty)
        'agent': '${order?['agentname']}',
      if ((order?['agentid'].toString() ?? '').isNotEmpty ||
          order?['agentid'].toString() != '-1')
        'id': '${order?['agentid']}',
    };

    await _apiService.post('/update_addon.php', body: body);
  }

  Future<void> changeQuantity({
    required num newQuantity,
    required dynamic order,
    required Map item,
  }) async {
    final body = {
      'order': order['billno'],
      'quantity': item['items'].toString(),
      'serviceId': item['id'].toString(),
      'price': item['price'].toString(),
      'new_quantity': '$newQuantity',
    };
    await _apiService.post('/update_cart.php', body: body);
  }
}

final servicesToAdd = StateProvider((ref) => <Savis>[]);
final addonToAdd = StateProvider.autoDispose((ref) => <Savis>[]);
