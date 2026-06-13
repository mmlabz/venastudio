import 'package:venastudio/common.dart';

ServiceUser? getCurrentUser(WidgetRef ref) {
  final activeAgent = LocalStorage.nosql.activeAgent;

  if (activeAgent != null) {
    return ServiceUser.fromMap(activeAgent);
  }

  return ref.watch(authenticationServiceProvider).valueOrNull?.user ??
      LocalStorage.nosql.user;
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaSurface = Colors.white;
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 700;

    final userService = ref.watch(authenticationServiceProvider);
    final settingsService = ref.watch(settingsServicesProvider);
    final user = getCurrentUser(ref);

    return Scaffold(
      backgroundColor: venaBg,
      appBar: isSmallScreen
          ? AppBar(
              backgroundColor: venaBg,
              foregroundColor: venaDark,
              elevation: 0,
              title: const Text(
                'Settings',
                style: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
              ),
            )
          : null,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xffF8FDFF), Color(0xffEEF9FB), Color(0xffE4F7FA)],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeader(isSmallScreen: isSmallScreen),
                    const SizedBox(height: 18),
                    Expanded(
                      child: userService.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: venaTeal),
                        ),
                        error: (error, stackTrace) => const SizedBox.shrink(),
                        data: (_) {
                          final actions = _getCategorizedActions(
                            settingsService,
                            user,
                          );

                          return GridView(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isSmallScreen ? 1 : 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: isSmallScreen ? 1.65 : 1.75,
                                ),
                            children: actions.entries.map((entry) {
                              final userType = normalizeUserType(user?.type);
                              final items = entry.value
                                  .where(
                                    (action) => (action['show'] as List).any(
                                      (allowedType) =>
                                          normalizeUserType(
                                            allowedType.toString(),
                                          ) ==
                                          userType,
                                    ),
                                  )
                                  .toList();

                              return _SettingsCategoryCard(
                                title: entry.key,
                                items: items,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final bool isSmallScreen;

  const _ProfileHeader({required this.isSmallScreen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userService = ref.watch(authenticationServiceProvider);
    final user = getCurrentUser(ref);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
      decoration: BoxDecoration(
        color: SettingsPage.venaSurface.withOpacity(0.94),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: SettingsPage.venaLine),
      ),
      child: Row(
        children: [
          Container(
            height: isSmallScreen ? 52 : 60,
            width: isSmallScreen ? 52 : 60,
            decoration: BoxDecoration(
              color: SettingsPage.venaTeal.withOpacity(0.12),
              borderRadius: BorderRadius.zero,
              border: Border.all(
                color: SettingsPage.venaTeal.withOpacity(0.28),
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              size: isSmallScreen ? 28 : 32,
              color: SettingsPage.venaTeal,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.email ?? 'Email',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SettingsPage.venaDark,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  user?.phone ?? '',
                  style: const TextStyle(
                    color: SettingsPage.venaMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: SettingsPage.venaTeal.withOpacity(0.10),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: SettingsPage.venaTeal.withOpacity(0.24),
                    ),
                  ),
                  child: Text(
                    user?.type ?? '',
                    style: const TextStyle(
                      color: SettingsPage.venaTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const _ProfileMenu(),
        ],
      ),
    );
  }
}

class _ProfileMenu extends ConsumerWidget {
  const _ProfileMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_MenuActions>(
      icon: const Icon(Icons.more_vert_rounded, color: SettingsPage.venaDark),
      color: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: SettingsPage.venaLine),
      ),
      itemBuilder: (context) => _MenuActions.values.map((e) {
        final isLogout = e == _MenuActions.logout;

        return PopupMenuItem<_MenuActions>(
          value: e,
          child: Row(
            children: [
              Icon(
                e.logo(),
                color: isLogout
                    ? SettingsPage.venaDanger
                    : SettingsPage.venaDark,
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                e.name(),
                style: TextStyle(
                  color: isLogout
                      ? SettingsPage.venaDanger
                      : SettingsPage.venaDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onSelected: (item) {
        if (item == _MenuActions.logout) {
          ref.read(authenticationServiceProvider.notifier).logout();
        } else if (item == _MenuActions.customer) {
          context.go('/customer_screen?isAgent=false');
        } else if (item == _MenuActions.agentCustomer) {
          context.go('/customer_screen?isAgent=true');
        }
      },
    );
  }
}

class _SettingsCategoryCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;

  const _SettingsCategoryCard({required this.title, required this.items});

  IconData get icon {
    switch (title) {
      case 'Finance':
        return Icons.account_balance_wallet_outlined;
      case 'Orders Management':
        return Icons.receipt_long_outlined;
      case 'Agent Management':
        return Icons.groups_2_outlined;
      default:
        return Icons.settings_suggest_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SettingsPage.venaSurface.withOpacity(0.94),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: SettingsPage.venaLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: SettingsPage.venaTeal.withOpacity(0.10),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: SettingsPage.venaTeal.withOpacity(0.22),
                  ),
                ),
                child: Icon(icon, color: SettingsPage.venaTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: SettingsPage.venaDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final action = items[index];

                return _SettingsActionTile(
                  title: action['name'],
                  icon: action['icon'],
                  route: action['page'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends ConsumerWidget {
  final String title;
  final IconData icon;
  final String route;

  const _SettingsActionTile({
    required this.title,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        if (route == 'commission') {
          ref.invalidate(commissionServicesProvider);
        }

        context.go('/settings/$route');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.70),
          borderRadius: BorderRadius.zero,
          border: Border.all(color: SettingsPage.venaLine),
        ),
        child: Row(
          children: [
            Icon(icon, color: SettingsPage.venaMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: SettingsPage.venaDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: SettingsPage.venaMuted,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

enum _MenuActions {
  logout,
  customer,
  agentCustomer;

  String name() => switch (this) {
    _MenuActions.logout => 'Log out',
    _MenuActions.customer => 'Customer Portal',
    _MenuActions.agentCustomer => 'Agents Portal',
  };

  IconData logo() => switch (this) {
    _MenuActions.logout => Icons.logout_rounded,
    _MenuActions.customer => Icons.co_present_outlined,
    _MenuActions.agentCustomer => Icons.group_outlined,
  };
}

Map<String, List<Map<String, dynamic>>> _getCategorizedActions(
  SettingsConfig st,
  ServiceUser? user,
) {
  bool userHasPermission(List<Map<String, dynamic>> actions) {
    return actions.any((action) {
      final userType = normalizeUserType(user?.type);
      return (action['show'] as List).any(
        (allowedType) => normalizeUserType(allowedType.toString()) == userType,
      );
    });
  }

  final categories = {
    'Finance': [
      {
        'name': 'Commission',
        'page': 'commission',
        'icon': Icons.money,
        'show': [SUPERADMIN_TYPE_NAME, EMPLOYEE_TYPE_NAME],
      },
      if ((!st.loading && st.showCashRegister) ||
          isSuperAdminType(user?.type))
        {
          'name': 'Cash Register',
          'page': 'cash_register',
          'icon': Icons.attach_money,
          'show': [SUPERADMIN_TYPE_NAME],
        },
      {
        'name': 'Expenses',
        'page': 'expenses',
        'icon': Icons.receipt_long_rounded,
        'show': [SUPERADMIN_TYPE_NAME, FRONTOFFICE_TYPE_NAME],
      },
      {
        'name': 'Cash Reconciliation',
        'page': 'cash_reconciliation',
        'icon': Icons.fact_check_rounded,
        'show': [SUPERADMIN_TYPE_NAME, FRONTOFFICE_TYPE_NAME, EMPLOYEE_TYPE_NAME],
      },
      if ((!st.loading && st.showSummary) || isSuperAdminType(user?.type))
        {
          'name': 'Summary',
          'page': 'summary',
          'icon': Icons.bar_chart_rounded,
          'show': [SUPERADMIN_TYPE_NAME],
        },
      {
        'name': 'Mpesa Codes',
        'page': 'mpesa_codes',
        'icon': Icons.sms_outlined,
        'show': [SUPERADMIN_TYPE_NAME, FRONTOFFICE_TYPE_NAME],
      },
    ],
    'Orders Management': [
      {
        'name': 'Completed Orders',
        'page': 'completed_orders',
        'icon': Icons.check_circle_outline,
        'show': [
          SUPERADMIN_TYPE_NAME,
          FRONTOFFICE_TYPE_NAME,
          EMPLOYEE_TYPE_NAME,
        ],
      },
      {
        'name': 'Orders by Branch',
        'page': 'all_orders',
        'icon': Icons.sort,
        'show': [SUPERADMIN_TYPE_NAME],
      },
      {
        'name': 'Manage Bookings',
        'page': 'booked_orders',
        'icon': Icons.bookmark_added_outlined,
        'show': [SUPERADMIN_TYPE_NAME, FRONTOFFICE_TYPE_NAME],
      },
    ],
    'Agent Management': [
      {
        'name': 'Agents',
        'page': 'agents',
        'icon': Icons.groups_outlined,
        'show': [SUPERADMIN_TYPE_NAME, FRONTOFFICE_TYPE_NAME],
      },
      {
        'name': 'Branches',
        'page': 'branches',
        'icon': Icons.apartment,
        'show': [SUPERADMIN_TYPE_NAME],
      },
    ],
    'Settings': [
      {
        'name': 'Edit Services & Addons',
        'page': 'edit_services',
        'icon': Icons.edit_note_rounded,
        'show': [SUPERADMIN_TYPE_NAME, FRONTOFFICE_TYPE_NAME],
      },
      {
        'name': 'Settings',
        'page': 'account_settings',
        'icon': Icons.settings_suggest_outlined,
        'show': [SUPERADMIN_TYPE_NAME, FRONTOFFICE_TYPE_NAME],
      },
      {
        'name': 'Color Customization',
        'page': 'theme_settings',
        'icon': Icons.color_lens,
        'show': [
          SUPERADMIN_TYPE_NAME,
          FRONTOFFICE_TYPE_NAME,
          EMPLOYEE_TYPE_NAME,
        ],
      },
    ],
  };

  final Map<String, List<Map<String, dynamic>>> filteredCategories = {};

  categories.forEach((category, actions) {
    if (userHasPermission(actions)) {
      filteredCategories[category] = actions;
    }
  });

  return filteredCategories;
}
