import 'package:hive/hive.dart';
import 'invoice_item.dart';

part 'quotation.g.dart';

@HiveType(typeId: 4)
class Quotation extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String quoteNumber;

  @HiveField(2)
  late String clientId;

  @HiveField(3)
  late String clientName;

  @HiveField(4)
  late String clientPhone;

  @HiveField(5)
  late String clientAddress;

  @HiveField(6)
  late DateTime issueDate;

  @HiveField(7)
  late DateTime validUntil;

  @HiveField(8)
  late String itemsJson;

  @HiveField(9)
  late double taxRate;

  @HiveField(10)
  late String status; // draft, sent, accepted, rejected

  @HiveField(11)
  late String notes;

  @HiveField(12)
  late String currency;

  Quotation({
    required this.id,
    required this.quoteNumber,
    required this.clientId,
    required this.clientName,
    this.clientPhone = '',
    this.clientAddress = '',
    required this.issueDate,
    required this.validUntil,
    this.itemsJson = '[]',
    this.taxRate = 0.16,
    this.status = 'draft',
    this.notes = '',
    this.currency = 'KES',
  });

  List<InvoiceItem> get items => InvoiceItem.listFromJson(itemsJson);
  set items(List<InvoiceItem> value) => itemsJson = InvoiceItem.listToJson(value);

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get taxAmount => subtotal * taxRate;
  double get total => subtotal + taxAmount;

  QuotationStatus get quoteStatus {
    switch (status) {
      case 'accepted': return QuotationStatus.accepted;
      case 'rejected': return QuotationStatus.rejected;
      case 'sent': return QuotationStatus.sent;
      default: return QuotationStatus.draft;
    }
  }

  bool get isExpired =>
      DateTime.now().isAfter(validUntil) && status != 'accepted';
}

enum QuotationStatus { draft, sent, accepted, rejected }

extension QuotationStatusExt on QuotationStatus {
  String get label {
    switch (this) {
      case QuotationStatus.draft: return 'Draft';
      case QuotationStatus.sent: return 'Sent';
      case QuotationStatus.accepted: return 'Accepted';
      case QuotationStatus.rejected: return 'Rejected';
    }
  }
}
