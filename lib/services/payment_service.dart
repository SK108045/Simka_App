import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/payment.dart';

class PaymentService extends ChangeNotifier {
  static const String _boxName = 'payments';
  late Box<Payment> _box;
  final _uuid = const Uuid();

  List<Payment> get allPayments => _box.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  Future<void> init() async {
    _box = await Hive.openBox<Payment>(_boxName);
    notifyListeners();
  }

  List<Payment> getPaymentsForClient(String clientId) {
    return _box.values.where((p) => p.clientId == clientId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double getTotalOwedByClient(String clientId) {
    final clientPayments = getPaymentsForClient(clientId);
    return clientPayments.fold(0.0, (sum, p) => sum + p.balance);
  }

  Future<void> addPayment({
    required String clientId,
    required String clientName,
    required double amount,
    double amountPaid = 0,
    required DateTime date,
    String description = '',
    String invoiceNumber = '',
    String notes = '',
  }) async {
    final id = _uuid.v4();
    final payment = Payment(
      id: id,
      clientId: clientId,
      clientName: clientName,
      amount: amount,
      amountPaid: amountPaid,
      date: date,
      description: description,
      invoiceNumber: invoiceNumber,
      notes: notes,
    );
    await _box.put(id, payment);
    notifyListeners();
  }

  Future<void> updatePayment(Payment payment) async {
    await _box.put(payment.id, payment);
    notifyListeners();
  }

  Future<void> deletePayment(String id) async {
    await _box.delete(id);
    notifyListeners();
  }
}
