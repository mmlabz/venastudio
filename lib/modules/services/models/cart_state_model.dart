import 'package:venastudio/common.dart';

class Cart {
  final List<Savis> items;
  final Agent? mainAgent;
  final Map<dynamic, dynamic>? shop;
  final String? phone;
  final Map<String, Map<String, String>>? assigned;
  final DateTime? bookingDate;
  final List<Map<String, dynamic>> addons;

  Cart({
    required this.items,
    required this.addons,
    this.mainAgent,
    this.shop,
    this.phone,
    this.assigned,
    this.bookingDate,
  });

  Cart.empty()
    : items = [],
      addons = [],
      mainAgent = null,
      phone = null,
      shop = null,
      assigned = null,
      bookingDate = null;

  Cart copyWith({
    List<Savis>? items,
    Agent? mainAgent,
    Map<dynamic, dynamic>? shop,
    String? phone,
    Map<String, Map<String, String>>? assigned,
    DateTime? bookingDate,
    bool emptyBookingDate = false,
    List<Map<String, dynamic>>? addons,
  }) {
    return Cart(
      items: items ?? this.items,
      addons: addons ?? this.addons,
      mainAgent: mainAgent ?? this.mainAgent,
      shop: shop ?? this.shop,
      phone: phone ?? this.phone,
      assigned: assigned ?? this.assigned,
      bookingDate: emptyBookingDate ? null : bookingDate ?? this.bookingDate,
    );
  }
}
