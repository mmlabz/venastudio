class Agent {
  final num id;
  final String name;
  final String email;
  final String phone;
  final bool archived;
  final num pin;
  final num commission;
  final num shop;
  final String type;
  final num userID;
  final String? store;

  Agent({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.archived,
    required this.pin,
    required this.commission,
    required this.shop,
    required this.userID,
    required this.type,
    required this.store,
  });

  static Agent fromJson(Map data) {
    return Agent(
      id: data['id'],
      name: data['name'],
      email: data['email'],
      phone: data['phone'],
      archived: data['archived'],
      pin: data['pin'],
      commission: data['commission'],
      shop: data['shop'],
      userID: data['userid'],
      type: data['type'],
      store: data['store'],
    );
  }
}
