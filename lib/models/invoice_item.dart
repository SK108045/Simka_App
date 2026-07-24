import 'dart:convert';

class InvoiceItem {
  final String description;
  final String code;
  final double quantity;
  final double unitPrice;

  InvoiceItem({
    required this.description,
    this.code = '',
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'description': description,
        'code': code,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        description: json['description'] as String,
        code: json['code'] as String? ?? '',
        quantity: (json['quantity'] as num).toDouble(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
      );

  static List<InvoiceItem> listFromJson(String jsonStr) {
    if (jsonStr.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<InvoiceItem> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }
}
