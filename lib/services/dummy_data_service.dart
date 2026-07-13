import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import '../models/invoice.dart';
import '../models/quotation.dart';
import '../models/invoice_item.dart';

class DummyDataService {
  static Future<void> populateIfNeeded() async {
    final clientBox = Hive.box<Client>('clients');
    if (clientBox.isNotEmpty) return; // Only populate if empty

    final invoiceBox = Hive.box<Invoice>('invoices');
    final quotationBox = Hive.box<Quotation>('quotations');
    final uuid = const Uuid();
    final now = DateTime.now();

    // ── Dummy Clients ──
    final c1 = Client(
      id: uuid.v4(),
      name: 'Nairobi Tech Hub',
      phone: '0712345678',
      address: 'Westlands, Nairobi',
      serviceType: 'Fire Extinguisher',
      lastServiceDate: now.subtract(const Duration(days: 120)),
      nextServiceDate: now.subtract(const Duration(days: 5)), // Overdue
      notes: 'Premium client, fast payment. 5 Fire Extinguishers (CO2), 2 Fire Blankets',
      notificationId: 1001,
    );

    final c2 = Client(
      id: uuid.v4(),
      name: 'Alpha Bakers Ltd',
      phone: '0722000111',
      address: 'Industrial Area, Nairobi',
      serviceType: 'Suppression System',
      lastServiceDate: now.subtract(const Duration(days: 300)),
      nextServiceDate: now.add(const Duration(days: 4)), // Urgent
      notes: '12 Dry Powder Extinguishers',
      notificationId: 1002,
    );

    final c3 = Client(
      id: uuid.v4(),
      name: 'Sunset Apartments',
      phone: '0733444555',
      address: 'Kilimani, Nairobi',
      serviceType: 'Fire Alarm',
      lastServiceDate: now.subtract(const Duration(days: 50)),
      nextServiceDate: now.add(const Duration(days: 130)),
      notificationId: 1003,
    );

    await clientBox.putAll({
      c1.id: c1,
      c2.id: c2,
      c3.id: c3,
    });

    // ── Dummy Invoices ──
    final inv1 = Invoice(
      id: uuid.v4(),
      invoiceNumber: 'SIMKA-INV-1001',
      clientId: c1.id,
      clientName: c1.name,
      clientPhone: c1.phone,
      clientAddress: c1.address,
      issueDate: now.subtract(const Duration(days: 15)),
      dueDate: now.add(const Duration(days: 15)),
      amountPaid: 14500,
      status: 'Paid',
    )..items = [
        InvoiceItem(description: 'Service 5kg CO2 Extinguisher', quantity: 5, unitPrice: 1500),
        InvoiceItem(description: 'Replace Fire Blanket', quantity: 2, unitPrice: 2500),
      ];

    final inv2 = Invoice(
      id: uuid.v4(),
      invoiceNumber: 'SIMKA-INV-1002',
      clientId: c2.id,
      clientName: c2.name,
      clientPhone: c2.phone,
      clientAddress: c2.address,
      issueDate: now.subtract(const Duration(days: 40)),
      dueDate: now.subtract(const Duration(days: 10)), // Overdue
      amountPaid: 0,
      status: 'Overdue',
    )..items = [
        InvoiceItem(description: 'Refill 9kg Dry Powder', quantity: 12, unitPrice: 2200),
      ];

    await invoiceBox.putAll({
      inv1.id: inv1,
      inv2.id: inv2,
    });

    // ── Dummy Quotations ──
    final q1 = Quotation(
      id: uuid.v4(),
      quoteNumber: 'SIMKA-QT-001',
      clientId: c3.id,
      clientName: c3.name,
      clientPhone: c3.phone,
      clientAddress: c3.address,
      issueDate: now.subtract(const Duration(days: 2)),
      validUntil: now.add(const Duration(days: 28)),
      status: 'Sent',
    )..items = [
        InvoiceItem(description: 'Install new Smoke Detectors', quantity: 10, unitPrice: 3500),
      ];

    await quotationBox.put(q1.id, q1);
  }
}
