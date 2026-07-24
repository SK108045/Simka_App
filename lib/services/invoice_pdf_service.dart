import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/invoice.dart';

/// SIMKA branded invoice item catalog (mirrors Python SAMPLE_ITEMS)
class SimkaServiceItem {
  final String code;
  final String description;
  final double unitPrice;

  const SimkaServiceItem({
    required this.code,
    required this.description,
    required this.unitPrice,
  });
}

const List<SimkaServiceItem> simkaCatalog = [
  SimkaServiceItem(code: 'STFS/FES/0003', description: '6 LITRE FOAM FIRE EXTINGUISHER SERVICE', unitPrice: 300),
  SimkaServiceItem(code: 'STFS/FES/0006', description: '9 LITRE WATER FIRE EXTINGUISHER SERVICE', unitPrice: 300),
  SimkaServiceItem(code: 'STFS/FES/0007', description: 'CATRIDGE REPLACEMENT', unitPrice: 2000),
  SimkaServiceItem(code: 'STFS/FES/0008', description: 'CATRIDGE REFILL', unitPrice: 1500),
  SimkaServiceItem(code: 'STFS/FES/0002', description: '4KG/6KG/9KG DRY CHEMICAL POWDER FIRE EXTINGUISHER SERVICE', unitPrice: 300),
  SimkaServiceItem(code: 'STFS/FES/001', description: '2KG/5KG CO2 FIRE EXTINGUISHER SERVICE', unitPrice: 300),
  SimkaServiceItem(code: 'STFS/FES/0010', description: 'FIRE BLANKET 4 X 4 SERVICE', unitPrice: 300),
  SimkaServiceItem(code: 'STFS/FES/0011A', description: '9 KG DRY CHEMICAL POWDER REFILL AND PRESSURIZING', unitPrice: 2500),
  SimkaServiceItem(code: 'STFS/FES/0005', description: '9 KG DRY POWDER FIRE EXTINGUISHER SERVICE', unitPrice: 300),
  SimkaServiceItem(code: 'STFS/FES/0009', description: 'FIRE ALARM SYSTEM TESTING AND SERVICING', unitPrice: 4500),
  SimkaServiceItem(code: 'STFS/FES/0004', description: 'CALL POINT BREAK GLASS REPLACEMENT', unitPrice: 600),
];

/// PDF color constants matching original Python invoice
const _darkBlue = PdfColor.fromInt(0xFF1F548F);
const _lightBlue = PdfColor.fromInt(0xFF538ED7);
const _rowGrey = PdfColor.fromInt(0xFFE0E0E0);

const _companyName = 'SIMKA TECHNOLOGIES FIRE SERVICES';
const _companyAddr1 = 'P.O, BOX 7785 - 00200';
const _companyAddr2 = 'NAIROBI';
const _companyPhone = '+254 725 625 952, +254 738 456 909';

String _ksh(double value) {
  final fmt = NumberFormat('#,##0.00', 'en_US');
  return 'Ksh.${fmt.format(value)}';
}

class InvoicePdfService {
  static pw.MemoryImage? _logoImage;

  /// Load the SIMKA logo from assets once
  static Future<void> _loadLogo() async {
    if (_logoImage != null) return;
    try {
      final data = await rootBundle.load('assets/images/simka_logo.jpg');
      _logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      // Logo unavailable, continue without it
    }
  }

  /// Generate a branded SIMKA PDF from an Invoice model
  static Future<Uint8List> generateFromInvoice(Invoice invoice) async {
    await _loadLogo();

    final items = invoice.items;
    final dateFmt = DateFormat('d MMMM yyyy');
    final invoiceDate = dateFmt.format(invoice.issueDate);
    final dueDate = dateFmt.format(invoice.dueDate);
    final billToLines = <String>[
      invoice.clientName,
      if (invoice.clientAddress.isNotEmpty) invoice.clientAddress,
      if (invoice.clientPhone.isNotEmpty) invoice.clientPhone,
    ];

    // Build extended items with line_total, vat, tax_percent
    final extItems = items.map((item) {
      final subtotal = item.quantity * item.unitPrice;
      return {
        'qty': item.quantity,
        'description': item.description,
        'unit_price': item.unitPrice,
        'code': '',
        'vat': 0.0,
        'tax_percent': invoice.taxRate * 100,
        'line_total': subtotal + (subtotal * invoice.taxRate),
      };
    }).toList();

    final grandTotal = extItems.fold<double>(0, (s, i) => s + (i['line_total'] as double));

    return _buildPdf(
      invoiceNo: invoice.invoiceNumber,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      billToLines: billToLines,
      items: extItems,
      grandTotal: grandTotal,
    );
  }

  /// Generate a branded SIMKA PDF from raw form data (for the generator form)
  static Future<Uint8List> generateFromFormData({
    required String invoiceNo,
    required String invoiceDate,
    required String dueDate,
    required String billTo,
    required List<Map<String, dynamic>> items,
  }) async {
    await _loadLogo();

    final billToLines = billTo.split('\n').where((l) => l.trim().isNotEmpty).toList();

    // Calculate line totals
    for (final item in items) {
      final qty = (item['qty'] as num?)?.toDouble() ?? 1;
      final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0;
      final vat = (item['vat'] as num?)?.toDouble() ?? 0;
      final taxPct = (item['tax_percent'] as num?)?.toDouble() ?? 0;
      final subtotal = qty * unitPrice;
      item['line_total'] = subtotal + vat + (subtotal * taxPct / 100.0);
    }

    final grandTotal = items.fold<double>(0, (s, i) => s + ((i['line_total'] as num?)?.toDouble() ?? 0));

    return _buildPdf(
      invoiceNo: invoiceNo,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      billToLines: billToLines,
      items: items,
      grandTotal: grandTotal,
    );
  }

  static Future<Uint8List> _buildPdf({
    required String invoiceNo,
    required String invoiceDate,
    required String dueDate,
    required List<String> billToLines,
    required List<Map<String, dynamic>> items,
    required double grandTotal,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // ── Header Section ──
          _buildHeader(invoiceNo, invoiceDate, dueDate, billToLines),
          pw.SizedBox(height: 20),

          // ── Items Table ──
          _buildItemsTable(items),
          pw.SizedBox(height: 16),

          // ── Totals ──
          _buildTotals(grandTotal),
          pw.SizedBox(height: 24),

          // ── Footer ──
          pw.Text(
            'Thank you for your business.',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(height: 16, color: _lightBlue),
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Invoice #$invoiceNo, Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    String invoiceNo,
    String invoiceDate,
    String dueDate,
    List<String> billToLines,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Dark blue top bar
        pw.Container(height: 16, color: _darkBlue),
        pw.SizedBox(height: 8),

        // "Invoice" title
        pw.Center(
          child: pw.Text(
            'Invoice',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 8),

        // Two thin dark blue bars
        pw.Row(
          children: [
            pw.Expanded(child: pw.Container(height: 8, color: _darkBlue)),
            pw.SizedBox(width: 10),
            pw.Expanded(child: pw.Container(height: 8, color: _darkBlue)),
          ],
        ),
        pw.SizedBox(height: 16),

        // Company info + Invoice details side by side
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left: Logo + Company info
            pw.Expanded(
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (_logoImage != null)
                    pw.Container(
                      width: 50,
                      height: 54,
                      child: pw.Image(_logoImage!, fit: pw.BoxFit.contain),
                    ),
                  if (_logoImage != null) pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_companyName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text(_companyAddr1, style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(_companyAddr2, style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(_companyPhone, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),

            // Right: Date / Invoice No / Due Date
            pw.Container(
              width: 200,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _labelValue('Date:', invoiceDate),
                  _labelValue('Invoice No.:', invoiceNo),
                  _labelValue('Due Date:', dueDate),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 2, color: _darkBlue),
        pw.SizedBox(height: 20),

        // Bill To section
        pw.Container(height: 8, color: _lightBlue),
        pw.SizedBox(height: 8),
        pw.Text('Bill To:', style: const pw.TextStyle(fontSize: 10)),
        ...billToLines.take(5).map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(line, style: const pw.TextStyle(fontSize: 10)),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 2, color: _lightBlue),
      ],
    );
  }

  static pw.Widget _labelValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 80, child: pw.Text(label, style: const pw.TextStyle(fontSize: 10))),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(List<Map<String, dynamic>> items) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: pw.BoxDecoration(color: _lightBlue),
      headerAlignment: pw.Alignment.center,
      cellHeight: 28,
      columnWidths: {
        0: const pw.FixedColumnWidth(35),
        1: const pw.FixedColumnWidth(70),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FixedColumnWidth(75),
        4: const pw.FixedColumnWidth(55),
        5: const pw.FixedColumnWidth(50),
        6: const pw.FixedColumnWidth(75),
      },
      headers: ['Qty', 'Item', 'Description', 'Unit Price', 'VAT', 'TAX %', 'Total'],
      cellAlignments: {
        0: pw.Alignment.centerRight,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
      },
      rowDecoration: pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: pw.BoxDecoration(color: _rowGrey),
      data: items.map((item) {
        final qty = (item['qty'] as num?)?.toDouble() ?? 1;
        final qtyStr = qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toStringAsFixed(1);
        return [
          qtyStr,
          (item['code'] as String?) ?? '',
          (item['description'] as String?) ?? '',
          _ksh((item['unit_price'] as num?)?.toDouble() ?? 0),
          _ksh((item['vat'] as num?)?.toDouble() ?? 0),
          '${((item['tax_percent'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}%',
          _ksh((item['line_total'] as num?)?.toDouble() ?? 0),
        ];
      }).toList(),
    );
  }

  static pw.Widget _buildTotals(double grandTotal) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        _totalLine('Total', _ksh(grandTotal), bold: true),
        pw.SizedBox(height: 6),
        _totalLine('Balance Due', _ksh(grandTotal), bold: true),
      ],
    );
  }

  static pw.Widget _totalLine(String label, String value, {bool bold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ),
        pw.SizedBox(width: 16),
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ),
      ],
    );
  }
}
