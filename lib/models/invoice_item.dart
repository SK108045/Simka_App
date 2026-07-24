import 'dart:convert';

class InvoiceItem {
  final String description;
  final double quantity;
  final double unitPrice;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        description: (json['description'] as String?) ?? (json['desc'] as String?) ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? (json['qty'] as num?)?.toDouble() ?? 1.0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      );

  static List<InvoiceItem> listFromJson(String jsonStr) {
    if (jsonStr.trim().isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded
          .where((e) => e is Map)
          .map((e) => InvoiceItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }
  static String listToJson(List<InvoiceItem> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }
}
