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
    this.image = '',
    this.availability = 1,
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
  final String image;
  final int availability;

  bool get isVisible => availability == 1;

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? 0;
  }

  static num _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse('${value ?? ''}') ?? 0;
  }

  static String _asString(dynamic value) => '${value ?? ''}'.trim();

  Savis.fromJson(dynamic json)
      : id = _asInt(json['id']),
        name = _asString(json['name']),
        amount = _asNum(json['amount'] ?? json['price']),
        commission = json['commission'] ?? json['commission_id'],
        discount = json['discount'],
        discountStartDate = json['startTime'] ?? json['start_time'],
        discountEndDate = json['endTime'] ?? json['end_time'],
        hours = _asNum(json['hours']),
        minutes = _asNum(json['minutes']),
        quantity = _asNum(json['quantity'] ?? json['qty']),
        type = _asString(json['type'] ?? json['service_type']),
        image = _asString(json['image'] ?? json['images'] ?? json['image_url']),
        availability = _asInt(json['availability'] ?? json['visible'] ?? 1);

  static List<Savis> fromJsonApi(List<dynamic> data) {
    return List<Savis>.from(
      data.map(Savis.fromJson),
    );
  }

  Savis copyWith({
    num? quantity,
    num? discount,
    String? image,
    int? availability,
  }) {
    return Savis(
      id: id,
      name: name,
      amount: amount,
      hours: hours,
      minutes: minutes,
      quantity: quantity ?? this.quantity,
      discount: '${discount ?? this.discount}',
      commission: commission,
      discountStartDate: discountStartDate,
      discountEndDate: discountEndDate,
      type: type,
      image: image ?? this.image,
      availability: availability ?? this.availability,
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
        'image': image,
        'availability': availability,
      });
}
