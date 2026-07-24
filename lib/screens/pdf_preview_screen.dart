import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import '../services/pdf_invoice_service.dart';
import '../theme/app_theme.dart';

class PdfPreviewScreen extends StatefulWidget {
  final Invoice invoice;

  const PdfPreviewScreen({super.key, required this.invoice});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late Future<Uint8List> _pdfFuture;

  @override
  void initState() {
    super.initState();
    _pdfFuture = PdfInvoiceService.generate(widget.invoice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text('Invoice ${widget.invoice.invoiceNumber}', style: const TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.cardDark,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.fireRed));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error generating PDF', style: const TextStyle(color: AppTheme.dangerRed)));
          }
          
          return PdfPreview(
            build: (format) => snapshot.data!,
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            pdfFileName: 'SIMKA_Invoice_${widget.invoice.invoiceNumber}.pdf',
            previewPageMargin: const EdgeInsets.all(12),
            pdfPreviewPageDecoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
