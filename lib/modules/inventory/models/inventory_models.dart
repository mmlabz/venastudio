class InventoryProduct {
  InventoryProduct({
    required this.id,
    required this.name,
    required this.qty,
    required this.availableQty,
    required this.trackingType,
    required this.reorderLevel,
    required this.isLowStock,
    this.sku = '',
    this.variantLabel = '',
    this.categoryName = 'Uncategorized',
    this.unit = 'units',
    this.image = '',
    this.description = '',
    this.storeName = '',
    this.colour = '',
    this.sizes = '',
  });

  final int id;
  final String name;
  final String sku;
  final String variantLabel;
  final String categoryName;
  final double qty;
  final double availableQty;
  final String unit;
  final String trackingType;
  final double reorderLevel;
  final bool isLowStock;
  final String image;
  final String description;
  final String storeName;
  final String colour;
  final String sizes;

  factory InventoryProduct.fromMap(Map<dynamic, dynamic> json) {
    return InventoryProduct(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      variantLabel: json['variant_label']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? 'Uncategorized',
      qty: _toDouble(json['qty']),
      availableQty: _toDouble(json['available_qty'] ?? json['qty']),
      unit: json['unit']?.toString().isNotEmpty == true
          ? json['unit'].toString()
          : 'units',
      trackingType: json['tracking_type']?.toString() ?? 'consumable',
      reorderLevel: _toDouble(json['reorder_level']),
      isLowStock: json['is_low_stock'] == true || json['is_low_stock'] == 1,
      image: json['image']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      storeName: json['store_name']?.toString() ?? '',
      colour: json['colour']?.toString() ?? '',
      sizes: json['sizes']?.toString() ?? '',
    );
  }
}

class InventoryRequest {
  InventoryRequest({
    required this.id,
    required this.requestNo,
    required this.status,
    required this.itemCount,
    required this.totalRequested,
    required this.totalApproved,
    required this.totalFulfilled,
    required this.requestedBy,
    required this.createdAt,
    this.notes = '',
  });

  final int id;
  final String requestNo;
  final String status;
  final int itemCount;
  final double totalRequested;
  final double totalApproved;
  final double totalFulfilled;
  final int requestedBy;
  final int createdAt;
  final String notes;

  factory InventoryRequest.fromMap(Map<dynamic, dynamic> json) {
    return InventoryRequest(
      id: _toInt(json['id']),
      requestNo: json['request_no']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      itemCount: _toInt(json['item_count']),
      totalRequested: _toDouble(json['total_requested']),
      totalApproved: _toDouble(json['total_approved']),
      totalFulfilled: _toDouble(json['total_fulfilled']),
      requestedBy: _toInt(json['requested_by']),
      createdAt: _toInt(json['created_at']),
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class InventoryIssue {
  InventoryIssue({
    required this.issueId,
    required this.issueNo,
    required this.itemId,
    required this.productId,
    required this.name,
    required this.qtyIssued,
    required this.qtyReturned,
    required this.qtyDamaged,
    required this.qtyOutstanding,
    required this.trackingType,
    required this.issuedBy,
    required this.issuedTo,
    required this.status,
    required this.createdAt,
    this.sku = '',
    this.variantLabel = '',
    this.unit = 'units',
    this.headerNotes = '',
    this.itemNotes = '',
  });

  final int issueId;
  final String issueNo;
  final int itemId;
  final int productId;
  final String name;
  final String sku;
  final String variantLabel;
  final String unit;
  final double qtyIssued;
  final double qtyReturned;
  final double qtyDamaged;
  final double qtyOutstanding;
  final String trackingType;
  final int issuedBy;
  final int issuedTo;
  final String status;
  final String headerNotes;
  final String itemNotes;
  final int createdAt;

  factory InventoryIssue.fromMap(Map<dynamic, dynamic> json) {
    return InventoryIssue(
      issueId: _toInt(json['issue_id']),
      issueNo: json['issue_no']?.toString() ?? '',
      itemId: _toInt(json['item_id']),
      productId: _toInt(json['product_id']),
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      variantLabel: json['variant_label']?.toString() ?? '',
      unit: json['unit']?.toString().isNotEmpty == true
          ? json['unit'].toString()
          : 'units',
      qtyIssued: _toDouble(json['qty_issued']),
      qtyReturned: _toDouble(json['qty_returned']),
      qtyDamaged: _toDouble(json['qty_damaged']),
      qtyOutstanding: _toDouble(json['qty_outstanding']),
      trackingType: json['tracking_type']?.toString() ?? 'consumable',
      issuedBy: _toInt(json['issued_by']),
      issuedTo: _toInt(json['issued_to']),
      status: json['status']?.toString() ?? '',
      headerNotes: json['header_notes']?.toString() ?? '',
      itemNotes: json['item_notes']?.toString() ?? '',
      createdAt: _toInt(json['created_at']),
    );
  }
}

class InventoryReturnRecord {
  InventoryReturnRecord({
    required this.returnId,
    required this.returnNo,
    required this.issueId,
    required this.productId,
    required this.name,
    required this.qtyReturned,
    required this.conditionStatus,
    required this.returnedBy,
    required this.receivedBy,
    required this.createdAt,
    this.variantLabel = '',
    this.unit = 'units',
  });

  final int returnId;
  final String returnNo;
  final int issueId;
  final int productId;
  final String name;
  final String variantLabel;
  final String unit;
  final double qtyReturned;
  final String conditionStatus;
  final int returnedBy;
  final int receivedBy;
  final int createdAt;

  factory InventoryReturnRecord.fromMap(Map<dynamic, dynamic> json) {
    return InventoryReturnRecord(
      returnId: _toInt(json['return_id'] ?? json['id']),
      returnNo: json['return_no']?.toString() ?? '',
      issueId: _toInt(json['issue_id']),
      productId: _toInt(json['product_id']),
      name: json['name']?.toString() ?? '',
      variantLabel: json['variant_label']?.toString() ?? '',
      unit: json['unit']?.toString().isNotEmpty == true
          ? json['unit'].toString()
          : 'units',
      qtyReturned: _toDouble(json['qty_returned']),
      conditionStatus: json['condition_status']?.toString() ?? 'good',
      returnedBy: _toInt(json['returned_by']),
      receivedBy: _toInt(json['received_by']),
      createdAt: _toInt(json['created_at']),
    );
  }
}

class InventoryEmployee {
  InventoryEmployee({required this.id, required this.name, this.phone = ''});

  final int id;
  final String name;
  final String phone;

  factory InventoryEmployee.fromMap(Map<dynamic, dynamic> json) {
    return InventoryEmployee(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? 'Employee',
      phone: json['phone']?.toString() ?? '',
    );
  }
}

class InventoryStateData {
  InventoryStateData({
    this.products = const [],
    this.requests = const [],
    this.issues = const [],
    this.returns = const [],
    this.employees = const [],
  });

  final List<InventoryProduct> products;
  final List<InventoryRequest> requests;
  final List<InventoryIssue> issues;
  final List<InventoryReturnRecord> returns;
  final List<InventoryEmployee> employees;

  InventoryStateData copyWith({
    List<InventoryProduct>? products,
    List<InventoryRequest>? requests,
    List<InventoryIssue>? issues,
    List<InventoryReturnRecord>? returns,
    List<InventoryEmployee>? employees,
  }) {
    return InventoryStateData(
      products: products ?? this.products,
      requests: requests ?? this.requests,
      issues: issues ?? this.issues,
      returns: returns ?? this.returns,
      employees: employees ?? this.employees,
    );
  }

  int get lowStockCount => products.where((p) => p.isLowStock).length;
  int get outstandingCount => issues.where((i) => i.qtyOutstanding > 0).length;
  int pendingRequestsCount(String userType, int employeeId) {
    final list = userType == 'Employee'
        ? requests.where((r) => r.requestedBy == employeeId)
        : requests;
    return list.where((r) => r.status == 'pending_approval').length;
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return double.parse(value.toStringAsFixed(2));
  if (value is num) return double.parse(value.toStringAsFixed(2));
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
