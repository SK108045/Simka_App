import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/quotation.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import 'invoice_service.dart';

class QuotationService extends ChangeNotifier {
  static const String _boxName = 'quotations';
  late Box<Quotation> _box;
  final _uuid = const Uuid();

  List<Quotation> get allQuotations => _box.values.toList()
    ..sort((a, b) => b.issueDate.compareTo(a.issueDate));

  Future<void> init() async {
    _box = await Hive.openBox<Quotation>(_boxName);
    notifyListeners();
  }

  List<Quotation> getQuotationsForClient(String clientId) {
    return _box.values.where((q) => q.clientId == clientId).toList()
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
  }

  String _nextQuoteNumber() {
    final count = _box.length + 1;
    return 'SIMKA-QT-${count.toString().padLeft(3, '0')}';
  }

  Future<Quotation> addQuotation({
    required String clientId,
    required String clientName,
    String clientPhone = '',
    String clientAddress = '',
    required DateTime issueDate,
    required DateTime validUntil,
    required List<InvoiceItem> items,
    double taxRate = 0.16,
    String status = 'draft',
    String notes = '',
    String currency = 'Ksh',
  }) async {
    final id = _uuid.v4();
    final quotation = Quotation(
      id: id,
      quoteNumber: _nextQuoteNumber(),
      clientId: clientId,
      clientName: clientName,
      clientPhone: clientPhone,
      clientAddress: clientAddress,
      issueDate: issueDate,
      validUntil: validUntil,
      taxRate: taxRate,
      status: status,
      notes: notes,
      currency: currency,
    )..items = items;
    await _box.put(id, quotation);
    notifyListeners();
    return quotation;
  }

  Future<void> updateQuotation(Quotation quotation) async {
    await _box.put(quotation.id, quotation);
    notifyListeners();
  }

  Future<void> updateStatus(String id, String status) async {
    final q = _box.get(id);
    if (q == null) return;
    q.status = status;
    await _box.put(id, q);
    notifyListeners();
  }

  /// Convert a quotation into an invoice
  Future<Invoice> convertToInvoice(
    Quotation quotation,
    InvoiceService invoiceService,
  ) async {
    final invoice = await invoiceService.addInvoice(
      clientId: quotation.clientId,
      clientName: quotation.clientName,
      clientPhone: quotation.clientPhone,
      clientAddress: quotation.clientAddress,
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      items: quotation.items,
      taxRate: quotation.taxRate,
      status: 'sent',
      notes: 'Converted from ${quotation.quoteNumber}\n${quotation.notes}',
      currency: quotation.currency,
    );
    await updateStatus(quotation.id, 'accepted');
    return invoice;
  }

  Future<void> deleteQuotation(String id) async {
    await _box.delete(id);
    notifyListeners();
  }
}
