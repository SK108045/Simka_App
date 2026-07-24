import 'package:hive/hive.dart';
import 'invoice_item.dart';

part 'invoice.g.dart';

@HiveType(typeId: 3)
class Invoice extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String invoiceNumber;

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
  late DateTime dueDate;

  @HiveField(8)
  late String itemsJson;

  @HiveField(9)
  late double taxRate; // 0.16 = 16% VAT

  @HiveField(10)
  late String status; // draft, sent, paid, overdue

  @HiveField(11)
  late String notes;

  @HiveField(12)
  late String currency;

  @HiveField(13)
  late double amountPaid;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    required this.clientName,
    this.clientPhone = '',
    this.clientAddress = '',
    required this.issueDate,
    required this.dueDate,
    this.itemsJson = '[]',
    this.taxRate = 0.0,
    this.status = 'draft',
    this.notes = '',
    this.currency = 'Ksh',
    this.amountPaid = 0,
  });

  List<InvoiceItem> get items => InvoiceItem.listFromJson(itemsJson);
  set items(List<InvoiceItem> value) => itemsJson = InvoiceItem.listToJson(value);

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get taxAmount => subtotal * taxRate;
  double get total => subtotal + taxAmount;
  double get balance => total - amountPaid;

  InvoiceStatus get paymentStatus {
    if (amountPaid >= total) return InvoiceStatus.paid;
    if (DateTime.now().isAfter(dueDate) && amountPaid < total) return InvoiceStatus.overdue;
    if (status == 'sent') return InvoiceStatus.sent;
    return InvoiceStatus.draft;
  }
}

enum InvoiceStatus { draft, sent, paid, overdue }

extension InvoiceStatusExt on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.draft: return 'Draft';
      case InvoiceStatus.sent: return 'Sent';
      case InvoiceStatus.paid: return 'Paid';
      case InvoiceStatus.overdue: return 'Overdue';
    }
  }
}
