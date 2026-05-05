import 'package:venastudio/common.dart';

class ServiceSummary {
  final AsyncValue<List<Map>> storesales;
  final AsyncValue<List<Map>> storesummary;

  ServiceSummary({required this.storesales, required this.storesummary});

  factory ServiceSummary.loading() {
    return ServiceSummary(
      storesales: const AsyncLoading(),
      storesummary: const AsyncLoading(),
    );
  }

  ServiceSummary copyWith({
    AsyncValue<List<Map>>? storesales,
    AsyncValue<List<Map>>? storesummary,
  }) {
    return ServiceSummary(
      storesales: storesales ?? this.storesales,
      storesummary: storesummary ?? this.storesummary,
    );
  }
}
