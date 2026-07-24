import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/invoice.dart';

class PdfInvoiceService {
  static const _darkBlue = PdfColor(0.121569, 0.329412, 0.560784);
  static const _lightBlue = PdfColor(0.32549, 0.556863, 0.843137);
  static const _rowGrey = PdfColor(0.878431, 0.878431, 0.878431);

  static const String companyName = "SIMKA TECHNOLOGIES FIRE SERVICES";
  static const String companyAddress1 = "P.O, BOX 7785 - 00200";
  static const String companyAddress2 = "NAIROBI";
  static const String companyPhone = "+254 725 625 952, +254 738 456 909";

  static Future<Uint8List> generate(Invoice invoice) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/images/simka_logo.jpg');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      // Ignored if logo isn't found
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(54),
        build: (context) {
          return [
            _buildHeader(invoice, logoImage),
            pw.SizedBox(height: 20),
            _buildBillTo(invoice),
            pw.SizedBox(height: 20),
            _buildTable(invoice),
            pw.SizedBox(height: 20),
            _buildTotals(invoice),
            pw.SizedBox(height: 40),
            pw.Text(
              "Thank you for your business.",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              height: 19,
              color: _lightBlue,
              width: double.infinity,
            ),
          ];
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Invoice #${invoice.invoiceNumber}, Page ${context.pageNumber}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(Invoice invoice, pw.MemoryImage? logoImage) {
    final df = DateFormat('dd MMMM yyyy');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Top dark blue bar
        pw.Container(
          width: double.infinity,
          height: 19,
          color: _darkBlue,
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text('Invoice', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 22)),
        ),
        pw.SizedBox(height: 14),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left Column
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(width: 270, height: 9, color: _darkBlue),
                pw.SizedBox(height: 16),
                if (logoImage != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 6),
                    child: pw.Container(
                      width: 51,
                      height: 54,
                      child: pw.Image(logoImage),
                    ),
                  )
                else
                  pw.SizedBox(height: 54),
                pw.SizedBox(height: 20),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(companyName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.SizedBox(height: 5),
                      pw.Text(companyAddress1, style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 2),
                      pw.Text(companyAddress2, style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 2),
                      pw.Text(companyPhone, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Container(width: 270, height: 2, color: _darkBlue),
              ],
            ),
            // Right Column
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(width: 216, height: 9, color: _darkBlue),
                pw.SizedBox(height: 19),
                pw.Container(
                  width: 216,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildMetaRow('Date:', df.format(invoice.issueDate)),
                      pw.SizedBox(height: 2),
                      _buildMetaRow('Invoice No.:', invoice.invoiceNumber),
                      pw.SizedBox(height: 2),
                      _buildMetaRow('Due Date:', df.format(invoice.dueDate)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Container(width: 216, height: 2, color: _darkBlue),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMetaRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _buildBillTo(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(width: 244, height: 9, color: _lightBlue),
        pw.SizedBox(height: 8),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill To:', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.clientName, style: const pw.TextStyle(fontSize: 10)),
              if (invoice.clientAddress.isNotEmpty)
                pw.Text(invoice.clientAddress, style: const pw.TextStyle(fontSize: 10)),
              if (invoice.clientPhone.isNotEmpty)
                pw.Text(invoice.clientPhone, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(width: 244, height: 2, color: _lightBlue),
      ],
    );
  }

  static pw.Widget _buildTable(Invoice invoice) {
    return pw.TableHelper.fromTextArray(
      headers: ['Qty', 'Item', 'Description', 'Unit Price', 'VAT', 'TAX %', 'Total'],
      data: invoice.items.map((item) {
        return [
          item.quantity.toStringAsFixed(0),
          item.code,
          item.description,
          'Ksh.${item.unitPrice.toStringAsFixed(2)}',
          'Ksh.0.00', // VAT empty in current model
          '0%', // Tax % empty in current model
          'Ksh.${item.total.toStringAsFixed(2)}',
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
      headerDecoration: const pw.BoxDecoration(color: _lightBlue),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignments: {
        0: pw.Alignment.centerRight,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
      },
      oddRowDecoration: const pw.BoxDecoration(color: _rowGrey),
    );
  }

  static pw.Widget _buildTotals(Invoice invoice) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(width: 100, child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
              pw.SizedBox(width: 12),
              pw.Container(width: 80, child: pw.Text('Ksh.${invoice.total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(width: 100, child: pw.Text('Balance Due', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
              pw.SizedBox(width: 12),
              pw.Container(width: 80, child: pw.Text('Ksh.${invoice.balance.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
            ],
          ),
        ],
      ),
    );
  }
}
