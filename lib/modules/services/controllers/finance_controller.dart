import 'package:venastudio/common.dart';

ServiceUser? financeCurrentUser(Ref ref) {
  final activeAgent = LocalStorage.nosql.activeAgent;

  if (activeAgent != null) {
    return ServiceUser.fromMap(activeAgent);
  }

  return ref.read(authenticationServiceProvider).valueOrNull?.user ??
      LocalStorage.nosql.user;
}

ServiceUser? financeCurrentUserFromWidget(WidgetRef ref) {
  final activeAgent = LocalStorage.nosql.activeAgent;

  if (activeAgent != null) {
    return ServiceUser.fromMap(activeAgent);
  }

  return ref.read(authenticationServiceProvider).valueOrNull?.user ??
      LocalStorage.nosql.user;
}

bool financeIsAdmin(ServiceUser? user) {
  final type = (user?.type ?? '').toLowerCase();

  return {
    SUPERADMIN_TYPE_NAME.toLowerCase(),
    'admin',
    'owner',
    'director',
    'manager',
  }.contains(type);
}

bool financeIsSuperAdmin(ServiceUser? user) {
  return (user?.type ?? '').toLowerCase() == SUPERADMIN_TYPE_NAME.toLowerCase();
}

String financeDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

final financeExpensesProvider = StateNotifierProvider<FinanceExpensesNotifier,
    AsyncValue<List<Map<String, dynamic>>>>(
  (ref) => FinanceExpensesNotifier(ref)..load(),
);

class FinanceExpensesNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  FinanceExpensesNotifier(this.ref) : super(const AsyncLoading());

  final Ref ref;
  final _api = ApiProvider();

  Future<void> load({DateTime? start, DateTime? end}) async {
    final user = financeCurrentUser(ref);

    if (user == null) {
      state = const AsyncData([]);
      return;
    }

    state = const AsyncLoading();

    try {
      final res = await _api.post('/finance/list_expenses.php', body: {
        'company_id': user.shop ?? '',
        'shop': user.shop ?? '',
        'store_id': user.storeName ?? '',
        'store': user.storeName ?? '',
        'user_type': user.type ?? '',
        'start': financeDate(start ?? DateTime.now()),
        'end': financeDate(end ?? start ?? DateTime.now()),
      });

      final raw = res is Map ? (res['data'] ?? res['expenses'] ?? []) : [];

      final rows = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      state = AsyncData(rows);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addExpense({
    required String amount,
    required String category,
    required String reason,
    required String type,
    required String paymentOptionId,
    required String paymentMethod,
    String transactionCost = '0',
    String referenceNo = '',
    DateTime? date,
  }) async {
    final user = financeCurrentUser(ref);

    if (user == null) return;

    final expenseDate = date ?? DateTime.now();

    await _api.post('/finance/save_expense.php', body: {
      'company_id': user.shop ?? '',
      'shop': user.shop ?? '',
      'store_id': user.storeName ?? '',
      'store': user.storeName ?? '',
      'user_id': '${user.id}',
      'user_name': user.name ?? user.email,
      'amount': amount,
      'category': category,
      'reason': reason,
      'type': type,
      'payment_option_id': paymentOptionId,
      'payment_method': paymentMethod,
      'transaction_cost': transactionCost,
      'reference_no': referenceNo,
      'date': financeDate(expenseDate),
    });

    await load(start: expenseDate, end: expenseDate);
  }
}

final financeExpenseCategoriesProvider =
    StateNotifierProvider<ExpenseCategoriesNotifier,
        AsyncValue<List<Map<String, dynamic>>>>(
  (ref) => ExpenseCategoriesNotifier(ref)..load(),
);

class ExpenseCategoriesNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  ExpenseCategoriesNotifier(this.ref) : super(const AsyncLoading());

  final Ref ref;
  final _api = ApiProvider();

  Future<void> load() async {
    final user = financeCurrentUser(ref);

    state = const AsyncLoading();

    try {
      final res = await _api.post('/finance/expense_categories.php', body: {
        'company_id': user?.shop ?? '',
        'shop': user?.shop ?? '',
      });

      final raw = res is Map ? (res['data'] ?? res['categories'] ?? []) : res;

      final rows = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      state = AsyncData(rows);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> save({
    String id = '',
    required String name,
    String isActive = '1',
  }) async {
    final user = financeCurrentUser(ref);
    if (user == null) return;

    await _api.post('/finance/save_expense_category.php', body: {
      'company_id': user.shop ?? '',
      'shop': user.shop ?? '',
      'user_type': user.type ?? '',
      'id': id,
      'expense': name,
      'is_active': isActive,
    });

    await load();
  }
}

final financePaymentOptionsProvider =
    StateNotifierProvider<PaymentOptionsNotifier,
        AsyncValue<List<Map<String, dynamic>>>>(
  (ref) => PaymentOptionsNotifier(ref)..load(),
);

class PaymentOptionsNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  PaymentOptionsNotifier(this.ref) : super(const AsyncLoading());

  final Ref ref;
  final _api = ApiProvider();

  Future<void> load() async {
    final user = financeCurrentUser(ref);

    state = const AsyncLoading();

    try {
      final res = await _api.post('/finance/payment_options.php', body: {
        'company_id': user?.shop ?? '',
        'shop': user?.shop ?? '',
      });

      final raw = res is Map ? (res['data'] ?? res['options'] ?? []) : res;

      final rows = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      state = AsyncData(rows);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> save({
    String id = '',
    required String name,
    required String code,
    required bool hasTransactionCost,
    required bool affectsCashReconciliation,
    bool isActive = true,
  }) async {
    final user = financeCurrentUser(ref);
    if (user == null) return;

    await _api.post('/finance/save_payment_option.php', body: {
      'company_id': user.shop ?? '',
      'shop': user.shop ?? '',
      'user_type': user.type ?? '',
      'id': id,
      'name': name,
      'code': code,
      'has_transaction_cost': hasTransactionCost ? '1' : '0',
      'affects_cash_reconciliation': affectsCashReconciliation ? '1' : '0',
      'is_active': isActive ? '1' : '0',
    });

    await load();
  }
}

final cashReconciliationProvider = StateNotifierProvider<
    CashReconciliationNotifier, AsyncValue<Map<String, dynamic>>>(
  (ref) => CashReconciliationNotifier(ref)..load(),
);

class CashReconciliationNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  CashReconciliationNotifier(this.ref) : super(const AsyncLoading());

  final Ref ref;
  final _api = ApiProvider();

  DateTime selectedDate = DateTime.now();

  Future<void> load({DateTime? date}) async {
    final user = financeCurrentUser(ref);

    if (user == null) {
      state = const AsyncData({});
      return;
    }

    selectedDate = date ?? selectedDate;
    state = const AsyncLoading();

    try {
      final res =
          await _api.post('/finance/cash_reconciliation_summary.php', body: {
        'company_id': user.shop ?? '',
        'shop': user.shop ?? '',
        'store_id': user.storeName ?? '',
        'store': user.storeName ?? '',
        'user_id': '${user.id}',
        'user_type': user.type ?? '',
        'date': financeDate(selectedDate),
      });

      state = AsyncData(res is Map ? Map<String, dynamic>.from(res) : {});
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> submitClosing({
    required String amount,
    required String notes,
  }) async {
    final user = financeCurrentUser(ref);

    if (user == null) return;

    await _api.post('/finance/submit_cash_reconciliation.php', body: {
      'company_id': user.shop ?? '',
      'shop': user.shop ?? '',
      'store_id': user.storeName ?? '',
      'store': user.storeName ?? '',
      'user_id': '${user.id}',
      'user_name': user.name ?? user.email,
      'date': financeDate(selectedDate),
      'reported_cash': amount,
      'notes': notes,
    });

    await load(date: selectedDate);
  }

  Future<void> submitExplanation({
    required String reportId,
    required String explanation,
  }) async {
    final user = financeCurrentUser(ref);

    if (user == null) return;

    await _api.post('/finance/submit_reconciliation_explanation.php', body: {
      'company_id': user.shop ?? '',
      'shop': user.shop ?? '',
      'store_id': user.storeName ?? '',
      'store': user.storeName ?? '',
      'user_id': '${user.id}',
      'report_id': reportId,
      'explanation': explanation,
    });

    await load(date: selectedDate);
  }

  Future<void> approve({
    required String reportId,
    String notes = '',
  }) async {
    final user = financeCurrentUser(ref);

    if (user == null) return;

    await _api.post('/finance/approve_cash_reconciliation.php', body: {
      'company_id': user.shop ?? '',
      'user_id': '${user.id}',
      'report_id': reportId,
      'notes': notes,
    });

    await load(date: selectedDate);
  }
}

final statementOfCashflowProvider = StateNotifierProvider<
    StatementOfCashflowNotifier, AsyncValue<Map<String, dynamic>>>(
  (ref) => StatementOfCashflowNotifier(ref)..load(),
);

class StatementOfCashflowNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  StatementOfCashflowNotifier(this.ref) : super(const AsyncLoading());

  final Ref ref;
  final _api = ApiProvider();

  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime endDate = DateTime.now();

  Future<void> load({DateTime? start, DateTime? end}) async {
    final user = financeCurrentUser(ref);

    if (user == null) {
      state = const AsyncData({});
      return;
    }

    startDate = start ?? startDate;
    endDate = end ?? endDate;

    state = const AsyncLoading();

    try {
      final res = await _api.post('/finance/statement_cashflow.php', body: {
        'company_id': user.shop ?? '',
        'shop': user.shop ?? '',
        'store_id': user.storeName ?? '',
        'store': user.storeName ?? '',
        'user_type': user.type ?? '',
        'start': financeDate(startDate),
        'end': financeDate(endDate),
      });

      state = AsyncData(res is Map ? Map<String, dynamic>.from(res) : {});
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
