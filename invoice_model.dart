import 'package:json_annotation/json_annotation.dart';

part 'invoice_model.g.dart';

@JsonSerializable()
class Invoice {
  final int id;
  final int customerId;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String invoiceType; // مبيعات, مرتجعات, عرض سعر
  final String paymentStatus; // مدفوعة, جزئي, معلقة, ملغاة
  final String invoiceStatus; //草案, نهائي, مُرسلة, ملغاة
  final double subtotal;
  final String discountType;
  final double discountValue;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String? notes;
  final String? paymentTerms;
  final String syncStatus;
  final List<InvoiceItem> items;

  Invoice({
    required this.id,
    required this.customerId,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    this.invoiceType = 'مبيعات',
    this.paymentStatus = 'معلقة',
    this.invoiceStatus = '草案',
    this.subtotal = 0,
    this.discountType = 'نسبة',
    this.discountValue = 0,
    this.discountAmount = 0,
    this.taxRate = 0,
    this.taxAmount = 0,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.notes,
    this.paymentTerms,
    this.syncStatus = 'pending',
    this.items = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);
  Map<String, dynamic> toJson() => _$InvoiceToJson(this);

  bool get isPaid => remainingAmount == 0 && paymentStatus == 'مدفوعة';
  bool get isPartiallyPaid => paidAmount > 0 && !isPaid;
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!) && !isPaid;

  Invoice copyWith({
    int? id,
    int? customerId,
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? invoiceType,
    String? paymentStatus,
    String? invoiceStatus,
    double? subtotal,
    String? discountType,
    double? discountValue,
    double? discountAmount,
    double? taxRate,
    double? taxAmount,
    double? totalAmount,
    double? paidAmount,
    double? remainingAmount,
    String? notes,
    String? paymentTerms,
    String? syncStatus,
    List<InvoiceItem>? items,
  }) {
    return Invoice(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      invoiceType: invoiceType ?? this.invoiceType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      invoiceStatus: invoiceStatus ?? this.invoiceStatus,
      subtotal: subtotal ?? this.subtotal,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      notes: notes ?? this.notes,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      syncStatus: syncStatus ?? this.syncStatus,
      items: items ?? this.items,
    );
  }
}

@JsonSerializable()
class InvoiceItem {
  final int id;
  final int invoiceId;
  final int? productId;
  final String productName;
  final String? productSku;
  final double unitPrice;
  final double quantity;
  final String unit;
  final String discountType;
  final double discountValue;
  final double lineTotal;
  final double taxRate;
  final String? notes;

  InvoiceItem({
    required this.id,
    required this.invoiceId,
    this.productId,
    required this.productName,
    this.productSku,
    required this.unitPrice,
    required this.quantity,
    this.unit = 'قطعة',
    this.discountType = 'نسبة',
    this.discountValue = 0,
    required this.lineTotal,
    this.taxRate = 0,
    this.notes,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) =>
      _$InvoiceItemFromJson(json);
  Map<String, dynamic> toJson() => _$InvoiceItemToJson(this);
}

@JsonSerializable()
class Product {
  final int id;
  final String name;
  final String? description;
  final String sku;
  final String? barcode;
  final int? categoryId;
  final double purchasePrice;
  final double wholesalePrice;
  final double retailPrice;
  final int quantityInStock;
  final int lowStockAlert;
  final String unit;
  final String? imageUrl;
  final double taxRate;
  final bool isActive;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.sku,
    this.barcode,
    this.categoryId,
    this.purchasePrice = 0,
    this.wholesalePrice = 0,
    required this.retailPrice,
    required this.quantityInStock,
    this.lowStockAlert = 10,
    this.unit = 'قطعة',
    this.imageUrl,
    this.taxRate = 0,
    this.isActive = true,
    this.syncStatus = 'synced',
    required this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  bool get isLowStock => quantityInStock <= lowStockAlert;
  bool get isOutOfStock => quantityInStock == 0;

  double getPrice(String customerType) {
    switch (customerType) {
      case 'جملة':
      case 'تاجر':
        return wholesalePrice > 0 ? wholesalePrice : retailPrice;
      default:
        return retailPrice;
    }
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    String? sku,
    String? barcode,
    int? categoryId,
    double? purchasePrice,
    double? wholesalePrice,
    double? retailPrice,
    int? quantityInStock,
    int? lowStockAlert,
    String? unit,
    String? imageUrl,
    double? taxRate,
    bool? isActive,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      retailPrice: retailPrice ?? this.retailPrice,
      quantityInStock: quantityInStock ?? this.quantityInStock,
      lowStockAlert: lowStockAlert ?? this.lowStockAlert,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      taxRate: taxRate ?? this.taxRate,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class Category {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final int? parentId;
  final String? icon;
  final String color;
  final int displayOrder;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.parentId,
    this.icon,
    this.color = '#1976d2',
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}
