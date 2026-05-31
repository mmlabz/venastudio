import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:venastudio/common.dart';

class MainPage extends ConsumerStatefulWidget {
  final Widget child;

  const MainPage({super.key, required this.child});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> with WindowListener {
  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaSurface = Color(0xffffffff);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaTealDark = Color(0xff00A9C0);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffD8F3F7);
  static const Color snapOrange = Color(0xffff6841);

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();

    // onesignalPermission();
    // unawaited(configureOnesignal(ref.read(appRouterProvider)));

    if (Platform.isAndroid || Platform.isIOS) {
      ref.read(quickActionsServiceProvider);
    }

    checkUpdate();
  }

  Future<void> checkUpdate() async {
    if (Platform.isAndroid) {
      InAppUpdateManager manager = InAppUpdateManager();
      AppUpdateInfo? appUpdateInfo = await manager.checkForUpdate();

      if (appUpdateInfo == null) return;

      if (appUpdateInfo.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        await manager.startAnUpdate(type: AppUpdateType.immediate);
      } else if (appUpdateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        if (appUpdateInfo.immediateAllowed) {
          await manager.startAnUpdate(type: AppUpdateType.immediate);
        } else if (appUpdateInfo.flexibleAllowed) {
          debugPrint('Start a flexible update');
          await manager.startAnUpdate(type: AppUpdateType.flexible);
        } else {
          debugPrint(
            'Update available. Immediate & Flexible Update Flow not allowed',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  // Future<void> onesignalPermission() async {
  //   if (Platform.isAndroid || Platform.isIOS) {
  //     OneSignal.Notifications.requestPermission(true).then((accepted) {
  //       Logger('ONESIGNAL').finest('Accepted permission: $accepted');
  //     });
  //   }
  // }

  // Future<void> configureOnesignal(GoRouter router) async {
  //   if (Platform.isAndroid || Platform.isIOS) {
  //     OneSignal.Notifications.addClickListener((event) {
  //       final page = event.notification.additionalData?['page'].toString();
  //       if (page != null) {
  //         router.go(page);
  //       }
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeServicesProvider);

    final bool isDesktop = MediaQuery.of(context).size.width > 800;
    final currentRoute = GoRouterState.of(context).uri.toString();
    final route = currentRoute;

    final activeAgent = LocalStorage.nosql.activeAgent;

    ServiceUser? user = activeAgent != null
        ? ServiceUser.fromMap(activeAgent)
        : (ref.watch(authenticationServiceProvider).valueOrNull?.user ??
            LocalStorage.nosql.user);

    final destinations = _destinations(user?.type);

    return Scaffold(
      backgroundColor: venaBg,
      body: isDesktop
          ? Row(
              children: [
                Container(
                  width: 88,
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    color: venaSurface.withOpacity(0.92),
                    border: const Border(
                      right: BorderSide(color: venaLine, width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: venaTeal.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(8, 0),
                      ),
                    ],
                  ),
                  child: _sideMenu(
                    context,
                    theme,
                    route,
                    currentRoute,
                    destinations,
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 18, 18),
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: venaBg,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ],
            )
          : widget.child,
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              backgroundColor: Colors.white,
              selectedItemColor: venaTeal,
              unselectedItemColor: venaMuted,
              type: BottomNavigationBarType.fixed,
              currentIndex: _getSelectedIndex(currentRoute, destinations),
              elevation: 14,
              onTap: (idx) {
                setState(() {
                  context.go(destinations[idx]['page'] as String);
                });
              },
              items: destinations.map((dest) {
                bool isActive = _isRouteActive(
                  dest['page'] as String,
                  currentRoute,
                );

                return BottomNavigationBarItem(
                  icon: Icon(
                    isActive
                        ? dest['active_icon'] as IconData
                        : dest['icon'] as IconData,
                    size: 26,
                  ),
                  label: dest['name'] as String,
                );
              }).toList(),
            )
          : null,
    );
  }

  bool _isRouteActive(String route, String currentRoute) {
    if (route == '/') {
      return currentRoute == '/';
    }

    return currentRoute.startsWith(route);
  }

  int _getSelectedIndex(
    String currentRoute,
    List<Map<String, Object>> destinations,
  ) {
    for (int i = 0; i < destinations.length; i++) {
      if (_isRouteActive(destinations[i]['page'] as String, currentRoute)) {
        return i;
      }
    }

    return 0;
  }

  Widget _sideMenu(
    BuildContext context,
    ThemeConfig theme,
    String route,
    String currentRoute,
    List<Map<String, Object>> destinations,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            _logo(theme, route, currentRoute),
            const SizedBox(height: 28),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: destinations
                    .where((dest) => dest['page'] != '/settings')
                    .map(
                      (dest) => _itemMenu(
                        menu: dest['name'] as String,
                        icon: dest['icon'] as IconData,
                        activeIcon: dest['active_icon'] as IconData,
                        route: dest['page'] as String,
                        context: context,
                        theme: theme,
                        currentRoute: currentRoute,
                      ),
                    )
                    .toList(),
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              color: venaLine,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: destinations
                    .where((dest) => dest['page'] == '/settings')
                    .map(
                      (dest) => _itemMenu(
                        menu: dest['name'] as String,
                        icon: dest['icon'] as IconData,
                        activeIcon: dest['active_icon'] as IconData,
                        route: dest['page'] as String,
                        context: context,
                        theme: theme,
                        currentRoute: currentRoute,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemMenu({
    required String menu,
    required IconData icon,
    required IconData activeIcon,
    required String route,
    required BuildContext context,
    required ThemeConfig theme,
    required String currentRoute,
  }) {
    final bool isActive = _isRouteActive(route, currentRoute);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => context.go(route),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                left: isActive ? 0 : -6,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: isActive ? 1 : 0,
                  child: Container(
                    width: 4,
                    height: 46,
                    decoration: BoxDecoration(
                      color: venaTeal,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: venaTeal.withOpacity(0.45),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? venaTeal.withOpacity(0.11)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isActive
                        ? venaTeal.withOpacity(0.22)
                        : Colors.transparent,
                  ),
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: venaTeal.withOpacity(0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: isActive ? venaTeal : Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          if (isActive)
                            BoxShadow(
                              color: venaTeal.withOpacity(0.30),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                        ],
                      ),
                      child: Icon(
                        isActive ? activeIcon : icon,
                        size: 21,
                        color: isActive ? Colors.white : venaMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      menu,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive ? venaDark : venaMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo(theme, route, currentRoute) {
    return Column(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [venaTeal, venaTealDark],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: venaTeal.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.spa_outlined, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 9),
        const Text(
          'Vena',
          style: TextStyle(
            color: venaDark,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Studio',
          style: TextStyle(
            color: venaMuted.withOpacity(0.8),
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  void onWindowClose() {
    final theme = ref.watch(themeServicesProvider);

    showCupertinoModalPopup(
      context: context,
      builder: (_) {
        return CupertinoTheme(
          data: CupertinoThemeData(
            brightness: theme.brightness,
            primaryColor: theme.deleteColor,
          ),
          child: CupertinoAlertDialog(
            title: Text(
              'Close Vena Studio?',
              style: TextStyle(color: theme.textIconPrimaryColor),
            ),
            content: Text(
              'Are you sure you want to close this window?',
              style: TextStyle(color: theme.textIconPrimaryColor),
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(context),
                child: Text('No', style: TextStyle(color: theme.successColor)),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  exit(0);
                },
                child: Text('Yes', style: TextStyle(color: theme.deleteColor)),
              ),
            ],
          ),
        );
      },
    );
  }
}

List<Map<String, Object>> _destinations(String? userType) => [
      if (userType == SUPERADMIN_TYPE_NAME ||
          userType == FRONTOFFICE_TYPE_NAME ||
          userType == EMPLOYEE_TYPE_NAME)
        {
          'name': 'Services',
          'icon': Icons.build_circle_outlined,
          'active_icon': Icons.build_circle,
          'page': '/',
        },
      if (userType == SUPERADMIN_TYPE_NAME ||
          userType == FRONTOFFICE_TYPE_NAME ||
          userType == EMPLOYEE_TYPE_NAME)
        {
          'name': 'Queue',
          'icon': Icons.receipt_long_outlined,
          'active_icon': Icons.receipt_long,
          'page': '/orders',
        },
      if (userType == SUPERADMIN_TYPE_NAME || userType == FRONTOFFICE_TYPE_NAME)
        {
          'name': 'Stock',
          'icon': Icons.storefront_outlined,
          'active_icon': Icons.storefront,
          'page': '/inventory',
        },
      if (userType == SUPERADMIN_TYPE_NAME || userType == FRONTOFFICE_TYPE_NAME)
        {
          'name': 'HR',
          'icon': Icons.groups_3_outlined,
          'active_icon': Icons.groups_3,
          'page': '/workforce',
        },
      if (userType == SUPERADMIN_TYPE_NAME || userType == FRONTOFFICE_TYPE_NAME)
        {
          'name': 'Analytics',
          'icon': Icons.analytics_outlined,
          'active_icon': Icons.analytics_rounded,
          'page': '/analytics',
        },
      if (userType == SUPERADMIN_TYPE_NAME ||
          userType == FRONTOFFICE_TYPE_NAME ||
          userType == EMPLOYEE_TYPE_NAME)
        {
          'name': 'Settings',
          'icon': Icons.settings_outlined,
          'active_icon': Icons.settings,
          'page': '/settings',
        },
    ];
