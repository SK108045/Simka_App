import 'package:hive/hive.dart';

part 'payment.g.dart';

@HiveType(typeId: 2)
class Payment extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String clientId;

  @HiveField(2)
  late String clientName;

  @HiveField(3)
  late double amount;

  @HiveField(4)
  late double amountPaid;

  @HiveField(5)
  late DateTime date;

  @HiveField(6)
  late String status; // 'paid', 'unpaid', 'partial'

  @HiveField(7)
  late String description;

  @HiveField(8)
  late String invoiceNumber;

  @HiveField(9)
  late String notes;

  Payment({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.amount,
    this.amountPaid = 0,
    required this.date,
    this.status = 'unpaid',
    this.description = '',
    this.invoiceNumber = '',
    this.notes = '',
  });

  double get balance => amount - amountPaid;

  PaymentStatus get paymentStatus {
    if (amountPaid >= amount) return PaymentStatus.paid;
    if (amountPaid > 0) return PaymentStatus.partial;
    return PaymentStatus.unpaid;
  }

  Payment copyWith({
    String? id,
    String? clientId,
    String? clientName,
    double? amount,
    double? amountPaid,
    DateTime? date,
    String? status,
    String? description,
    String? invoiceNumber,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      amount: amount ?? this.amount,
      amountPaid: amountPaid ?? this.amountPaid,
      date: date ?? this.date,
      status: status ?? this.status,
      description: description ?? this.description,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      notes: notes ?? this.notes,
    );
  }
}

enum PaymentStatus { paid, unpaid, partial }

extension PaymentStatusExt on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.unpaid:
        return 'Unpaid';
      case PaymentStatus.partial:
        return 'Partial';
    }
  }
}
