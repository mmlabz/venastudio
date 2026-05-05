import 'dart:convert';

class ServiceUser {
  final int id;
  final String pin;
  final String email;
  final String? type;
  final String? name;
  final String? phone;
  final String? shop;
  final String? storeName;
  final String? industry;
  final String? merchant;
  final String? paybill;
  final String? storeId;
  final String? payUrl;
  final String? subscriptionStatus;

  ServiceUser({
    required this.id,
    required this.pin,
    required this.email,
    this.type,
    this.name,
    this.phone,
    this.storeName,
    this.shop,
    this.industry,
    this.merchant,
    this.paybill,
    this.storeId,
    this.payUrl,
    this.subscriptionStatus,
  });

  factory ServiceUser.fromString(String data) {
    final decoded = jsonDecode(data);

    if (decoded is Map<String, dynamic>) {
      return ServiceUser.fromMap(decoded);
    }

    return ServiceUser.empty();
  }

  factory ServiceUser.fromMap(Map<String, dynamic> json, [String? pin]) {
    return ServiceUser(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      pin: pin?.toString() ?? json['pin']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString(),
      type: json['type']?.toString(),
      phone: json['phone']?.toString(),
      storeName: json['storeName']?.toString() ?? json['store']?.toString(),
      shop: json['shop']?.toString(),
      industry: json['industry']?.toString(),
      merchant: json['merchant']?.toString(),
      paybill: json['paybill']?.toString(),
      storeId: json['storeId']?.toString() ?? json['store_id']?.toString(),
      payUrl: json['pay_url']?.toString() ?? json['payUrl']?.toString(),
      subscriptionStatus:
          json['subscription_status']?.toString() ??
          json['subscriptionStatus']?.toString(),
    );
  }

  factory ServiceUser.empty() {
    return ServiceUser(id: 0, pin: '', email: '');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storeName': storeName,
      'name': name,
      'email': email,
      'pin': pin,
      'phone': phone,
      'shop': shop,
      'type': type,
      'industry': industry,
      'merchant': merchant,
      'paybill': paybill,
      'storeId': storeId,
      'pay_url': payUrl,
      'subscription_status': subscriptionStatus,
    };
  }

  @override
  String toString() => jsonEncode(toMap());
}
