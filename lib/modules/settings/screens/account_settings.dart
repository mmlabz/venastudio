import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:venastudio/common.dart';

class SettingsDetailPage extends ConsumerWidget {
  const SettingsDetailPage({super.key});

  static const Color venaBg = Color(0xffEEF9FB);
  static const Color venaTeal = Color(0xff00BFD8);
  static const Color venaDark = Color(0xff07304A);
  static const Color venaMuted = Color(0xff6B8794);
  static const Color venaLine = Color(0xffCFEFF4);
  static const Color venaDanger = Color(0xffD94B4B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsService = ref.watch(settingsServicesProvider);
    final userService = ref.watch(authenticationServiceProvider);
    final user = userService.valueOrNull?.user;
    final isAdmin = user?.type == SUPERADMIN_TYPE_NAME;

    return Scaffold(
      backgroundColor: venaBg,
      appBar: AppBar(
        backgroundColor: venaBg,
        foregroundColor: venaDark,
        elevation: 0,
        centerTitle: true,
        leading: context.backIcon(ref, () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/settings');
          }
        }),
        title: const Text(
          'Settings',
          style: TextStyle(color: venaDark, fontWeight: FontWeight.w900),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xffF8FDFF), Color(0xffEEF9FB), Color(0xffE4F7FA)],
          ),
        ),
        child: RefreshIndicator(
          color: venaTeal,
          onRefresh: () async {
            ref.invalidate(settingsServicesProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              if (settingsService.loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(color: venaTeal),
                ),
              _sectionTitle('GENERAL'),
              _settingTile(
                icon: Icons.lock_outline_rounded,
                title: 'Account Privacy',
                subtitle:
                    '${settingsService.screenLock ? 'Disable' : 'Enable'} password every time you open the app',
                trailing: CupertinoSwitch(
                  value: settingsService.screenLock,
                  activeColor: venaTeal,
                  onChanged: (_) {
                    ref
                        .read(settingsServicesProvider.notifier)
                        .changeScreenLock();
                  },
                ),
              ),
              if (isAdmin) ...[
                _sectionTitle('BUSINESS CONTROLS'),
                _settingTile(
                  icon: Icons.discount_outlined,
                  title: 'Discounts',
                  subtitle:
                      '${settingsService.showDiscount ? 'Disable' : 'Enable'} discounts when creating an order',
                  trailing: CupertinoSwitch(
                    value: settingsService.showDiscount,
                    activeColor: venaTeal,
                    onChanged: (_) {
                      ref
                          .read(settingsServicesProvider.notifier)
                          .changeShowDiscount();
                    },
                  ),
                ),
                _settingTile(
                  icon: Icons.payments_outlined,
                  title: 'Pay First',
                  subtitle:
                      '${settingsService.payFirst ? 'Disable' : 'Enable'} pay first option when creating an order',
                  trailing: CupertinoSwitch(
                    value: settingsService.payFirst,
                    activeColor: venaTeal,
                    onChanged: (_) {
                      ref
                          .read(settingsServicesProvider.notifier)
                          .changePayFirst();
                    },
                  ),
                ),
                _settingTile(
                  icon: Icons.bar_chart_rounded,
                  title: 'Store Summary',
                  subtitle:
                      '${settingsService.showSummary ? 'Disable' : 'Enable'} the Front-Office to view the store summary',
                  trailing: CupertinoSwitch(
                    value: settingsService.showSummary,
                    activeColor: venaTeal,
                    onChanged: (_) {
                      ref
                          .read(settingsServicesProvider.notifier)
                          .changeshowSummary();
                    },
                  ),
                ),
                _settingTile(
                  icon: Icons.groups_2_outlined,
                  title: 'Staff Commissions',
                  subtitle:
                      '${settingsService.showCommissions ? 'Disable' : 'Enable'} commissions visibility',
                  trailing: CupertinoSwitch(
                    value: settingsService.showCommissions,
                    activeColor: venaTeal,
                    onChanged: (_) {
                      ref
                          .read(settingsServicesProvider.notifier)
                          .changeshowCommissions();
                    },
                  ),
                ),
                _settingTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Cash Register',
                  subtitle:
                      '${settingsService.showCashRegister ? 'Disable' : 'Enable'} the Front-Office to view the cash register',
                  trailing: CupertinoSwitch(
                    value: settingsService.showCashRegister,
                    activeColor: venaTeal,
                    onChanged: (_) {
                      ref
                          .read(settingsServicesProvider.notifier)
                          .changecashRegister();
                    },
                  ),
                ),
                _settingTile(
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'Create Agent',
                  subtitle:
                      '${settingsService.createAttendant ? 'Disable' : 'Enable'} the Front-Office from creating an agent',
                  trailing: CupertinoSwitch(
                    value: settingsService.createAttendant,
                    activeColor: venaTeal,
                    onChanged: (_) {
                      ref
                          .read(settingsServicesProvider.notifier)
                          .changeCreateAttendant();
                    },
                  ),
                ),
                _settingTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Stock Tracking',
                  subtitle:
                      '${settingsService.trackStock ? 'Disable' : 'Enable'} stock tracking when creating an order',
                  trailing: CupertinoSwitch(
                    value: settingsService.trackStock,
                    activeColor: venaTeal,
                    onChanged: (_) {
                      ref
                          .read(settingsServicesProvider.notifier)
                          .changeTrackStock();
                    },
                  ),
                ),
                _settingTile(
                  icon: Icons.fact_check_outlined,
                  title: 'Attendance Tracking',
                  subtitle:
                      '${settingsService.trackAttendance ? 'Disable' : 'Enable'} attendance-based service assignment',
                  trailing: CupertinoSwitch(
                    value: settingsService.trackAttendance,
                    activeColor: venaTeal,
                    onChanged: (_) {
                      ref
                          .read(settingsServicesProvider.notifier)
                          .changeTrackAttendance();
                    },
                  ),
                ),
                _settingTile(
                  icon: Icons.format_list_numbered_rounded,
                  title: 'Queue Tracking',
                  subtitle:
                      '${settingsService.trackQueue ? 'Disable' : 'Enable'} queue-based service assignment and skip reasons',
                  trailing: CupertinoSwitch(
                    value: settingsService.trackQueue,
                    activeColor: venaTeal,
                    onChanged: (_) {
                      ref
                          .read(settingsServicesProvider.notifier)
                          .changeTrackQueue();
                    },
                  ),
                ),
              ],
              _sectionTitle('DEVICES'),
              _settingTile(
                icon: Icons.print_outlined,
                title: 'Printer',
                subtitle: (settingsService.printer == null &&
                        settingsService.bluetoothPrinter == null)
                    ? 'No printer selected'
                    : 'Selected: ${settingsService.printer?.name ?? settingsService.bluetoothPrinter?.name}',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: venaMuted,
                ),
                onTap: () {
                  showAvailablePrinters(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: venaMuted,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        border: Border.all(color: venaLine),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: venaTeal.withOpacity(0.10),
            border: Border.all(color: venaTeal.withOpacity(0.25)),
          ),
          child: Icon(icon, color: venaTeal, size: 21),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: venaDark,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: venaMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}

void showAvailablePrinters(BuildContext context) {
  final dWidth = context.sz.width;
  final width = dWidth > 430.0 ? 430.0 : dWidth - 24;

  showCupertinoModalPopup(
    context: context,
    useRootNavigator: SrceenType.type(context.sz).isMobile,
    builder: (_) {
      return Center(
        child: SizedBox(
          width: width,
          child: Material(
            color: Colors.transparent,
            child: Consumer(
              builder: (context, ref, _) {
                final printerServ = ref.watch(settingsServicesProvider);
                final activePrinter = printerServ.printer;
                final bluetoothPrinter = printerServ.bluetoothPrinter;

                return Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: SettingsDetailPage.venaLine),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xffF8FDFF),
                          border: Border(
                            bottom: BorderSide(
                              color: SettingsDetailPage.venaLine,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 38,
                              width: 38,
                              decoration: BoxDecoration(
                                color: SettingsDetailPage.venaTeal.withOpacity(
                                  0.10,
                                ),
                                border: Border.all(
                                  color: SettingsDetailPage.venaTeal
                                      .withOpacity(0.25),
                                ),
                              ),
                              child: const Icon(
                                Icons.print_outlined,
                                color: SettingsDetailPage.venaTeal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Printers Found',
                                style: TextStyle(
                                  color: SettingsDetailPage.venaDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: SettingsDetailPage.venaDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _PrinterSectionTitle('Connected'),
                              FutureBuilder(
                                future: Printing.listPrinters(),
                                builder: (context, snap) {
                                  if (snap.hasError) {
                                    return const _PrinterMessage(
                                      'Unable to load printers',
                                    );
                                  }

                                  if (snap.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: SettingsDetailPage.venaTeal,
                                        ),
                                      ),
                                    );
                                  }

                                  if (snap.hasData) {
                                    final data = snap.data ?? [];

                                    if (data.isEmpty) {
                                      return const _PrinterMessage(
                                        'No printers found',
                                      );
                                    }

                                    return ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      shrinkWrap: true,
                                      itemCount: data.length,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        final printer = data[index];
                                        final bool active = printer.model ==
                                            (activePrinter?.model ?? 'x');

                                        return _PrinterTile(
                                          title: printer.name,
                                          subtitle: active
                                              ? 'Tap to test print'
                                              : printer.model,
                                          active: active,
                                          onTap: active
                                              ? () async {
                                                  ref
                                                      .read(
                                                        settingsServicesProvider
                                                            .notifier,
                                                      )
                                                      .print();
                                                }
                                              : null,
                                          onSelect: active
                                              ? null
                                              : () async {
                                                  ref
                                                      .read(
                                                        settingsServicesProvider
                                                            .notifier,
                                                      )
                                                      .selectPrinter(printer);
                                                },
                                        );
                                      },
                                    );
                                  }

                                  return const SizedBox.shrink();
                                },
                              ),
                              if (Platform.isAndroid) ...[
                                const SizedBox(height: 14),
                                const _PrinterSectionTitle('Bluetooth'),
                                StreamBuilder(
                                  stream: FlutterBluetoothPrinter.discovery,
                                  builder: (context, snapshot) {
                                    final data = snapshot.data;

                                    if (data != null) {
                                      if (data is PermissionRestrictedState) {
                                        return const _PrinterMessage(
                                          'Permission restricted',
                                        );
                                      }

                                      if (data is DiscoveryResult) {
                                        final devices = data.devices;

                                        if (devices.isEmpty) {
                                          return const _PrinterMessage(
                                            'No bluetooth printers found',
                                          );
                                        }

                                        return ListView.builder(
                                          padding: EdgeInsets.zero,
                                          itemCount: devices.length,
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemBuilder: (context, index) {
                                            final printer = devices[index];
                                            final bool active = printer
                                                    .address ==
                                                (bluetoothPrinter?.address ??
                                                    'xx');

                                            return _PrinterTile(
                                              title: printer.name ?? 'Unknown',
                                              subtitle: active
                                                  ? 'Tap to test print'
                                                  : printer.address,
                                              active: active,
                                              onTap: active
                                                  ? () async {
                                                      ref
                                                          .read(
                                                            settingsServicesProvider
                                                                .notifier,
                                                          )
                                                          .print();
                                                    }
                                                  : null,
                                              onSelect: active
                                                  ? null
                                                  : () async {
                                                      ref
                                                          .read(
                                                            settingsServicesProvider
                                                                .notifier,
                                                          )
                                                          .selectBluetoothPrinter(
                                                            printer,
                                                          );
                                                    },
                                            );
                                          },
                                        );
                                      }
                                    }

                                    return const _PrinterMessage(
                                      'No printers found, check if bluetooth is on',
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

class _PrinterSectionTitle extends StatelessWidget {
  const _PrinterSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: SettingsDetailPage.venaMuted,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _PrinterMessage extends StatelessWidget {
  const _PrinterMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SettingsDetailPage.venaBg.withOpacity(0.75),
        border: Border.all(color: SettingsDetailPage.venaLine),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: SettingsDetailPage.venaMuted,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PrinterTile extends StatelessWidget {
  const _PrinterTile({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
    required this.onSelect,
  });

  final String title;
  final String? subtitle;
  final bool active;
  final VoidCallback? onTap;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: active
            ? SettingsDetailPage.venaTeal.withOpacity(0.08)
            : Colors.white,
        border: Border.all(
          color: active
              ? SettingsDetailPage.venaTeal.withOpacity(0.25)
              : SettingsDetailPage.venaLine,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(
            color: SettingsDetailPage.venaDark,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
        subtitle: subtitle == null || subtitle!.isEmpty
            ? null
            : Text(
                subtitle!,
                style: const TextStyle(
                  color: SettingsDetailPage.venaMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
        trailing: active
            ? const Icon(
                Icons.check_circle_rounded,
                color: SettingsDetailPage.venaTeal,
              )
            : TextButton(
                onPressed: onSelect,
                style: TextButton.styleFrom(
                  foregroundColor: SettingsDetailPage.venaTeal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text(
                  'Select',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
      ),
    );
  }
}
