import 'dart:convert';

import 'package:venastudio/common.dart';

class NoSQLDb {
  const NoSQLDb({required this.preferences});
  final SharedPreferences preferences;
  static const String _docVersion = 'V003';
  static const String _keySuffix = 'PROD-$_docVersion';
  static final _log = Logger('NoSQLDb');

  //Keys
static const String _savisesKey = 'saviseskey-$_keySuffix';
  static const String _ordersKey = 'orderskey-$_keySuffix';
  static const String _showDiscountKey = 'showdiscount-$_keySuffix';
  static const String _payFirstKey = 'payfirst-$_keySuffix';
  static const String _screenLockKey = 'screenlock-$_keySuffix';
  static const String _showSummaryKey = 'showsummary-$_keySuffix';
  static const String _showCommissionsKey = 'showcommissions-$_keySuffix';
  static const String _trackStockKey = 'trackstock-$_keySuffix';
  static const String _trackAttendanceKey = 'trackattendance-$_keySuffix';
  static const String _trackQueueKey = 'trackqueue-$_keySuffix';
  static const String _createAttendantKey = 'createattendant-$_keySuffix';

  static const String _authKey = 'authkey-$_keySuffix';
  static const String _themeModeKey = 'thememodekey-$_keySuffix';
  static const String _showCashRegisterKey = 'showcashregister-$_keySuffix';
  static const String _multiCompaniesKey = 'multicompanieskey-$_keySuffix';
  static const String _currentCompanyKey = 'currentCompanyKey-$_keySuffix';
  static const String _activeAgentKey = 'activeagent-$_keySuffix';

  Future<void> updateUser(ServiceUser useer) async {
    final res = await preferences.setString(_authKey, useer.toString());
    _log.info('Updating auth details result = $res');
  }

  ServiceUser? get user {
    try {
      final userString = preferences.getString(_authKey);
      if (userString != null && userString.length > 3) {
        final authUser = ServiceUser.fromString(userString);
        if (authUser.pin.isNotEmpty && authUser.email.length > 2) {
          return authUser;
        }
      }
      return null;
    } catch (e) {
      _log.warning(e);
      return null;
    }
  }

  Map<String, dynamic>? get activeAgent {
    try {
      final data = preferences.getString(_activeAgentKey);
      if (data == null || data.isEmpty) return null;

      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      _log.warning(e);
      return null;
    }
  }

  set activeAgent(Map<String, dynamic>? agent) {
    try {
      if (agent == null) {
        preferences.remove(_activeAgentKey);
      } else {
        preferences.setString(_activeAgentKey, jsonEncode(agent));
      }
    } catch (e) {
      _log.warning(e);
    }
  }
  Future<void> deleteUser() async {
    await preferences.clear();
    _log.warning('User deleted');
  }

  List<Savis>? get savises {
    try {
      final savisString = preferences.getStringList(_savisesKey);
      if (savisString != null && savisString.isNotEmpty) {
        return savisString.map((e) => Savis.fromJson(jsonDecode(e))).toList();
      }
      return null;
    } catch (e) {
      _log.warning(e);
      return null;
    }
  }

  List<Map>? get orders {
    try {
      final savisString = preferences.getStringList(_ordersKey);
      if (savisString != null && savisString.isNotEmpty) {
        return savisString.map((e) => jsonDecode(e) as Map).toList();
      }
      return null;
    } catch (e) {
      _log.warning(e);
      return null;
    }
  }

  Future<void> updateOrders(List<Map> orders) async {
    final res = await preferences.setStringList(
      _ordersKey,
      orders.map((e) => jsonEncode(e)).toList(),
    );
    _log.info('Updating auth details result = $res');
  }

  Future<void> updateSavis(List<Savis> savises) async {
    final res = await preferences.setStringList(
      _savisesKey,
      savises.map((e) => e.toString()).toList(),
    );
    _log.info('Updating auth details result = $res');
  }

  Future<void> updateThemeMode(int theme) async {
    await preferences.setInt(_themeModeKey, theme);
  }

  int get themeMode {
    try {
      final theme = preferences.getInt(_themeModeKey);
      return theme ?? 1;
    } catch (e) {
      _log.warning(e);
      return 1;
    }
  }
bool get isEmployeeSession {
    final agent = activeAgent;
    final loggedUser = user;

    return agent != null || loggedUser?.type == EMPLOYEE_TYPE_NAME;
  }
  bool get payFirst {
    try {
      final payFirst = preferences.getBool(_payFirstKey);
      return payFirst ?? false;
    } catch (e) {
      _log.warning(e);
      return false;
    }
  }

  bool get showDiscount {
    try {
      final disc = preferences.getBool(_showDiscountKey);
      return disc ?? false;
    } catch (e) {
      _log.warning(e);
      return false;
    }
  }

  Future<void> updateShowDiscount(bool show) async {
    await preferences.setBool(_showDiscountKey, show);
  }

  Future<void> updatePayFirst(bool show) async {
    await preferences.setBool(_payFirstKey, show);
  }

  bool get screenLock {
    try {
      final screenlock = preferences.getBool(_screenLockKey);
      return screenlock ?? false;
    } catch (e) {
      _log.warning(e);
      return false;
    }
  }

  set screenLock(bool value) {
    try {
      preferences.setBool(_screenLockKey, value);
    } catch (e) {
      _log.warning(e);
    }
  }

  Future<void> updateScreenLock(bool show) async {
    await preferences.setBool(_screenLockKey, show);
  }

  bool get showSummary {
    try {
      final showsummary = preferences.getBool(_showSummaryKey);
      return showsummary ?? false;
    } catch (e) {
      _log.warning(e);
      return false;
    }
  }

  Future<void> updateShowSummary(bool show) async {
    await preferences.setBool(_showSummaryKey, show);
  }

  bool get showCommissions {
    try {
      final showsummary = preferences.getBool(_showSummaryKey);
      return showsummary ?? false;
    } catch (e) {
      _log.warning(e);
      return false;
    }
  }

  Future<void> updateShowCommissions(bool show) async {
    await preferences.setBool(_showCommissionsKey, show);
  }

  bool get showCashRegister {
    try {
      final cashregister = preferences.getBool(_showCashRegisterKey);
      return cashregister ?? false;
    } catch (e) {
      _log.warning(e);
      return false;
    }
  }

  Future<void> updateShowCashRegister(bool show) async {
    await preferences.setBool(_showCashRegisterKey, show);
  }

  bool get trackStock {
    try {
      final trackstock = preferences.getBool(_trackStockKey);
      return trackstock ?? false;
    } catch (e) {
      _log.warning(e);
      return false;
    }
  }

  Future<void> updateTrackStock(bool track) async {
    await preferences.setBool(_trackStockKey, track);
  }


  bool get trackAttendance {
    try {
      final value = preferences.getBool(_trackAttendanceKey);
      return value ?? false;
    } catch (e) {
      _log.warning(e);
      return false;
    }
  }

  Future<void> updateTrackAttendance(bool track) async {
    await preferences.setBool(_trackAttendanceKey, track);
  }

  bool get trackQueue {
    try {
      final value = preferences.getBool(_trackQueueKey);
      return value ?? false;
    } catch (e) {
      _log.warning(e);
      return false;
    }
  }

  Future<void> updateTrackQueue(bool track) async {
    await preferences.setBool(_trackQueueKey, track);
  }

  bool get createAttendant {
    try {
      final createattendant = preferences.getBool(_createAttendantKey);
      return createattendant ?? false;
    } catch (e) {
      _log.warning(e);
      return false;
    }
  }

  Future<void> updateCreateAttendant(bool create) async {
    await preferences.setBool(_createAttendantKey, create);
  }

  List? get multipleCompanies {
    try {
      final cp = preferences.getString(_multiCompaniesKey);
      if (cp?.isNotEmpty ?? false) {
        return jsonDecode(cp!) as List;
      }
      return null;
    } catch (e) {
      _log.warning(e);
      return null;
    }
  }

  Future<void> updateMultipleCompanies(List<Map> companies) async {
    await preferences.setString(_multiCompaniesKey, jsonEncode(companies));
  }

  ({String id, String companyId})? get currentCompany {
    try {
      final cp = preferences.getString(_currentCompanyKey) ?? '';
      final cpitems = cp.split('-');
      if (cpitems.length == 2) {
        return (id: cpitems[0], companyId: cpitems[1]);
      }
      return null;
    } catch (e) {
      _log.warning(e);
      return null;
    }
  }

  Future<void> updateCurrentCompany(String company) async {
    await preferences.setString(_currentCompanyKey, company);
  }
}
