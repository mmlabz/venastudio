abstract class OrdersState {
  final List<Map> orders;
  const OrdersState({required this.orders});

  static OrdersState initial([List<Map>? orders]) =>
      OrdersLoading(orders: orders ?? []);
}

class OrdersError extends OrdersState {
  final String error;
  const OrdersError({required this.error, List<Map>? orders})
    : super(orders: orders ?? const []);
}

class OrdersLoading extends OrdersState {
  const OrdersLoading({required super.orders});
}

class OrdersLoaded extends OrdersState {
  OrdersLoaded({required super.orders});
}
