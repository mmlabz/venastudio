import 'dart:io';

import 'package:venastudio/common.dart';

final quickActionsServiceProvider =
    StateNotifierProvider<QuickActionsNotifier, QuickActions>(
      (ref) => QuickActionsNotifier(const QuickActions(), ref: ref),
    );

class QuickActionsNotifier extends StateNotifier<QuickActions> {
  QuickActionsNotifier(super.state, {required this.ref}) {
    initialize();
  }
  final StateNotifierProviderRef<QuickActionsNotifier, QuickActions> ref;

  void initialize() {
    final agent = LocalStorage.nosql.activeAgent;
    final user = agent != null
        ? ServiceUser.fromMap(agent)
        : LocalStorage.nosql.user;
    state.initialize((type) {
      if (type.startsWith('/')) {
        ref.read(appRouterProvider).go(type);
      }
    });

    if (user != null && (Platform.isAndroid || Platform.isIOS)) {
      setQuickActions(user);
    }
  }

  void setQuickActions(ServiceUser user) {
    final usertype = user.type;
    state.setShortcutItems(<ShortcutItem>[
      if (usertype == SUPERADMIN_TYPE_NAME || usertype == FRONTOFFICE_TYPE_NAME)
        const ShortcutItem(
          type: '/account/mpesa_codes',
          localizedTitle: 'Mpesa Codes',
          icon: 'venastudios',
        ),
      if (usertype == SUPERADMIN_TYPE_NAME || usertype == FRONTOFFICE_TYPE_NAME)
        const ShortcutItem(
          type: '/account/summary',
          localizedTitle: 'Summary',
          icon: 'venastudios',
        ),
    ]);
  }

  Future<void> clear() async {
    if ((Platform.isAndroid || Platform.isIOS)) {
      await state.clearShortcutItems();
    }
  }
}
