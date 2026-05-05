import 'package:venastudio/common.dart';

abstract class ServicesState {
  final List<Savis> services;
  const ServicesState({required this.services});

  static ServicesState initial([List<Savis>? savises]) =>
      ServicesLoading(services: savises ?? []);
}

class ServicesError extends ServicesState {
  final String error;
  const ServicesError({required this.error, List<Savis>? services})
    : super(services: services ?? const []);
}

class ServicesLoading extends ServicesState {
  const ServicesLoading({required super.services});
}

class ServicesLoaded extends ServicesState {
  ServicesLoaded({required super.services});
}
