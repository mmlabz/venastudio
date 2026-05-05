import 'dart:convert';

class Savis {
  Savis({
    required this.id,
    required this.name,
    required this.amount,
    this.commission,
    this.discount,
    this.discountStartDate,
    this.discountEndDate,
    required this.hours,
    required this.minutes,
    required this.quantity,
    required this.type,
  });

  final int id;
  final String name;
  final num amount;
  final dynamic commission;
  final dynamic discount;
  final dynamic discountStartDate;
  final dynamic discountEndDate;
  final num hours;
  final num minutes;
  final num quantity;
  final String type;

  Savis.fromJson(dynamic json)
      : id = json['id'] as int,
        name = json['name'] as String,
        amount = json['amount'] as num,
        commission = json['commission'],
        discount = json['discount'],
        discountStartDate = json['startTime'],
        discountEndDate = json['endTime'],
        hours = json['hours'] as num,
        minutes = json['minutes'] as num,
        quantity = json['quantity'] as num,
        type = json['type'];

  static List<Savis> fromJsonApi(List<dynamic> data) {
    return List<Savis>.from(
      data.map(Savis.fromJson),
    );
  }

  Savis copyWith({num? quantity, num? discount}) {
    return Savis(
      id: id,
      name: name,
      amount: amount,
      hours: hours,
      minutes: minutes,
      quantity: quantity ?? this.quantity,
      discount: '${discount ?? this.discount}',
      type: type,
    );
  }

  @override
  String toString() => jsonEncode({
        'id': id,
        'name': name,
        'amount': amount,
        'commission': commission,
        'discount': discount,
        'startTime': discountStartDate,
        'endTime': discountEndDate,
        'hours': hours,
        'minutes': minutes,
        'quantity': quantity,
        'type': type,
      });
}
