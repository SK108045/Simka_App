import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';

class InvoiceService extends ChangeNotifier {
  static const String _boxName = 'invoices';
  late Box<Invoice> _box;
  final _uuid = const Uuid();

  List<Invoice> get allInvoices => _box.values.toList()
    ..sort((a, b) => b.issueDate.compareTo(a.issueDate));

  double get totalRevenue => _box.values
      .where((i) => i.status == 'paid')
      .fold(0, (sum, i) => sum + i.total);

  double get totalOutstanding => _box.values
      .where((i) => i.status != 'paid')
      .fold(0, (sum, i) => sum + i.total);

  double get totalInvoiced =>
      _box.values.fold(0, (sum, i) => sum + i.total);

  Map<String, double> getMonthlyRevenue() {
    final now = DateTime.now();
    final result = <String, double>{};
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    for (int i = 5; i >= 0; i--) {
      final target = DateTime(now.year, now.month - i, 1);
      final label = months[target.month - 1];
      result[label] = _box.values
          .where((i) =>
              i.status == 'paid' &&
              i.issueDate.year == target.year &&
              i.issueDate.month == target.month)
          .fold(0.0, (sum, i) => sum + i.total);
    }
    return result;
  }

  Future<void> init() async {
    _box = await Hive.openBox<Invoice>(_boxName);
    notifyListeners();
  }

  List<Invoice> getInvoicesForClient(String clientId) {
    return _box.values.where((i) => i.clientId == clientId).toList()
      ..sort((a, b) => b.issueDate.compareTo(a.issueDate));
  }

  String _nextInvoiceNumber() {
    final count = _box.length + 1;
    return 'SIMKA-INV-${count.toString().padLeft(3, '0')}';
  }

  Future<Invoice> addInvoice({
    required String clientId,
    required String clientName,
    String clientPhone = '',
    String clientAddress = '',
    required DateTime issueDate,
    required DateTime dueDate,
    required List<InvoiceItem> items,
    double taxRate = 0.0,
    String status = 'draft',
    String notes = '',
    String currency = 'Ksh',
  }) async {
    final id = _uuid.v4();
    final invoice = Invoice(
      id: id,
      invoiceNumber: _nextInvoiceNumber(),
      clientId: clientId,
      clientName: clientName,
      clientPhone: clientPhone,
      clientAddress: clientAddress,
      issueDate: issueDate,
      dueDate: dueDate,
      taxRate: taxRate,
      status: status,
      notes: notes,
      currency: currency,
    )..items = items;
    await _box.put(id, invoice);
    notifyListeners();
    return invoice;
  }

  Future<void> updateInvoice(Invoice invoice) async {
    await _box.put(invoice.id, invoice);
    notifyListeners();
  }

  Future<void> recordPayment(String invoiceId, double amount) async {
    final invoice = _box.get(invoiceId);
    if (invoice == null) return;
    invoice.amountPaid = (invoice.amountPaid + amount).clamp(0, invoice.total);
    if (invoice.amountPaid >= invoice.total) invoice.status = 'paid';
    await _box.put(invoiceId, invoice);
    notifyListeners();
  }

  Future<void> deleteInvoice(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  /// Returns monthly revenue for last 6 months as Map[monthLabel, amount]
  Map<String, double> getMonthlyRevenue() {
    final now = DateTime.now();
    final result = <String, double>{};
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    for (int i = 5; i >= 0; i--) {
      final target = DateTime(now.year, now.month - i, 1);
      final label = months[target.month - 1];
      result[label] = _box.values
          .where((inv) =>
              inv.issueDate.year == target.year &&
              inv.issueDate.month == target.month)
          .fold(0, (sum, inv) => sum + inv.amountPaid);
    }
    return result;
  }
}
