import 'dart:io';

import 'package:venastudio/common.dart';

final authenticationServiceProvider =
    StateNotifierProvider<AuthenticationNotifier, AsyncValue<AuthData>>(
      (ref) => AuthenticationNotifier(ref: ref, user: LocalStorage.nosql.user),
    );

class AuthenticationNotifier extends StateNotifier<AsyncValue<AuthData>> {
  AuthenticationNotifier({required this.ref, required this.user})
    : super(const AsyncLoading()) {
    if (user != null) init();
  }

  final StateNotifierProviderRef<AuthenticationNotifier, AsyncValue<AuthData>>
  ref;

  final ServiceUser? user;
  final _apiService = ApiProvider();

  Future<void> init() async {
    try {
      final loginData = await login(email: user!.email, password: user!.pin);
      state = AsyncData(AuthData(user: loginData.user));
      //updating locally  the newly fetched data
      await LocalStorage.nosql.updateUser(loginData.user);
      if (loginData.user.subscriptionStatus == "notsubscribed") {
        ref.read(appRouterProvider).go('/subscriptions');
      }
    } catch (e) {
      if (e != "notsubscribed") state = AsyncError(e, StackTrace.current);
    }
  }

  Future<({ServiceUser user})> login({
    required String email,
    required String password,
  }) async {
    final dynamic response = await _apiService.post(
      '/login.php',
      body: {'email': email, 'password': password},
    );
    if (response.toString().length < 10) {
      if (response.toString() == "500") {
        throw FetchDataException();
      }
      throw UnauthorisedException();
    }
    final $user = ServiceUser.fromMap(
      response as Map<String, dynamic>,
      password,
    );
    return (user: $user);
  }

  Future<void> newLogin({
    required String email,
    required String password,
  }) async {
    final loginData = await login(email: email, password: password);

    LocalStorage.nosql.activeAgent = null;
    LocalStorage.nosql.screenLock = true;

    await LocalStorage.nosql.updateUser(loginData.user);

    state = AsyncData(AuthData(user: loginData.user));

    ref.read(appRouteService).refreshUser();

    ref.read(appRouterProvider).go('/welcome_page');
  }

  Future<void> logout() async {
    LocalStorage.nosql.activeAgent = null;
    LocalStorage.nosql.screenLock = false;

    await LocalStorage.nosql.deleteUser();

    if (Platform.isAndroid || Platform.isIOS) {
      await ref.read(quickActionsServiceProvider.notifier).clear();
    }

    ref.read(appRouteService).refreshUser();
  }
}
