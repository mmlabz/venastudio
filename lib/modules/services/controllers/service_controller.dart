import 'dart:async';
import 'package:venastudio/common.dart';

final businessServicesProvider =
    StateNotifierProvider<DashBoardServiceNotifier, ServicesState>((ref) {
      final authService = ref.watch(authenticationServiceProvider);
      return DashBoardServiceNotifier(authService: authService, ref: ref);
    });

class DashBoardServiceNotifier extends StateNotifier<ServicesState> {
  DashBoardServiceNotifier({required this.authService, required this.ref})
    : super(ServicesState.initial(LocalStorage.nosql.savises)) {
    if (authService is! AsyncLoading) init();
  }

  final AsyncValue<AuthData> authService;
  final StateNotifierProviderRef<DashBoardServiceNotifier, ServicesState> ref;
  final _apiService = ApiProvider();

  Future<void> init() async {
    final user = authService.valueOrNull?.user ?? LocalStorage.nosql.user;
    final body = {
      'id': '',
      'shop': user?.shop,
      'type': user?.type,
      'store': '',
      'userType': '',
    };
    try {
      final dynamic response = await _apiService.post(
        '/fetch_services.php',
        body: body,
      );

      final services = Savis.fromJsonApi(response as List);
      state = ServicesLoaded(services: services);
      LocalStorage.nosql.updateSavis(services);
    } catch (e) {
      state = ServicesError(error: e.toString(), services: state.services);
    }
  }

  Future<void> update(Savis savis) async {
    if (authService.value != null) {
      final user = authService.value!.user;
      final body = {
        'shop': user.shop,
        'store_id': user.storeName,
        'id': '',
        'industry': user.industry,
        'service_id': '${savis.id}',
        'amount': '${savis.amount}',
        'name': savis.name,
        'quan': '${savis.quantity}',
        'hour': '${savis.hours}',
        'minute': '${savis.minutes}',
        'type': savis.type,
        'commission': '${savis.commission}',
        'discount': '${savis.discount}',
        'start': savis.discountStartDate,
        'end': savis.discountEndDate,
      };
      await _apiService.post('/edit_service.php', body: body);
    }
  }

  Future<void> add(Savis savis) async {
    if (authService.value != null) {
      final user = authService.value!.user;
      final body = {
        'commission': '${savis.commission}',
        'hour': '${savis.hours}',
        'minute': '${savis.minutes}',
        'type': savis.type,
        'quantity': '${savis.quantity}',
        'shop': user.shop,
        'name': savis.name,
        'amount': '${savis.amount.toDouble()}',
      };
      await _apiService.post('/add_service.php', body: body, print: true);
    }
  }
}
