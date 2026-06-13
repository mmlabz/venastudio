import 'package:venastudio/common.dart';

class ServiceSummary {
  final AsyncValue<AdminFinanceSummary> finance;

  ServiceSummary({required this.finance});

  factory ServiceSummary.loading() {
    return ServiceSummary(finance: const AsyncLoading());
  }

  ServiceSummary copyWith({AsyncValue<AdminFinanceSummary>? finance}) {
    return ServiceSummary(finance: finance ?? this.finance);
  }
}

class AdminFinanceSummary {
  final bool isSuperAdmin;
  final String role;
  final String startDate;
  final String endDate;
  final double totalSales;
  final double totalCommissions;
  final double totalExpenses;
  final double totalCashOutflows;
  final double grossProfit;
  final List<StoreSaleBreakdown> stores;
  final List<ExpenseCategorySummary> expensesByCategory;

  const AdminFinanceSummary({
    required this.isSuperAdmin,
    required this.role,
    required this.startDate,
    required this.endDate,
    required this.totalSales,
    required this.totalCommissions,
    required this.totalExpenses,
    required this.totalCashOutflows,
    required this.grossProfit,
    required this.stores,
    required this.expensesByCategory,
  });

  factory AdminFinanceSummary.empty() {
    return const AdminFinanceSummary(
      isSuperAdmin: false,
      role: '',
      startDate: '',
      endDate: '',
      totalSales: 0,
      totalCommissions: 0,
      totalExpenses: 0,
      totalCashOutflows: 0,
      grossProfit: 0,
      stores: [],
      expensesByCategory: [],
    );
  }

  factory AdminFinanceSummary.fromMap(Map<String, dynamic> json) {
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data']) : json;
    final totals = data['totals'] is Map
        ? Map<String, dynamic>.from(data['totals'])
        : <String, dynamic>{};

    List<T> parseList<T>(dynamic value, T Function(Map<String, dynamic>) build) {
      if (value is! List) return <T>[];
      return value
          .whereType<Map>()
          .map((e) => build(Map<String, dynamic>.from(e)))
          .toList();
    }

    return AdminFinanceSummary(
      isSuperAdmin: _bool(data['is_superadmin']),
      role: data['role']?.toString() ?? '',
      startDate: data['start_date']?.toString() ?? '',
      endDate: data['end_date']?.toString() ?? '',
      totalSales: _double(totals['total_sales']),
      totalCommissions: _double(totals['total_commissions']),
      totalExpenses: _double(totals['total_expenses']),
      totalCashOutflows: _double(totals['total_cash_outflows'] ?? (_double(totals['total_commissions']) + _double(totals['total_expenses']))),
      grossProfit: _double(totals['gross_profit']),
      stores: parseList(data['stores'], StoreSaleBreakdown.fromMap),
      expensesByCategory: parseList(
        data['expenses_by_category'],
        ExpenseCategorySummary.fromMap,
      ),
    );
  }
}

class StoreSaleBreakdown {
  final String store;
  final double cash;
  final double mpesa;
  final double bank;
  final double total;
  final int orders;

  const StoreSaleBreakdown({
    required this.store,
    required this.cash,
    required this.mpesa,
    required this.bank,
    required this.total,
    required this.orders,
  });

  factory StoreSaleBreakdown.fromMap(Map<String, dynamic> json) {
    return StoreSaleBreakdown(
      store: json['store']?.toString() ?? 'Store',
      cash: _double(json['cash']),
      mpesa: _double(json['mpesa']),
      bank: _double(json['bank']),
      total: _double(json['total']),
      orders: _int(json['orders']),
    );
  }
}

class ExpenseCategorySummary {
  final String category;
  final double amount;
  final int count;

  const ExpenseCategorySummary({
    required this.category,
    required this.amount,
    required this.count,
  });

  factory ExpenseCategorySummary.fromMap(Map<String, dynamic> json) {
    return ExpenseCategorySummary(
      category: json['category']?.toString() ?? 'Uncategorised',
      amount: _double(json['amount']),
      count: _int(json['count']),
    );
  }
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase() ?? '';
  return text == '1' || text == 'true' || text == 'yes';
}
