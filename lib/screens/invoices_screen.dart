import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import '../services/invoice_pdf_service.dart';
import '../theme/app_theme.dart';
import 'create_invoice_screen.dart';
import 'quotations_screen.dart';
import '../widgets/background_glow.dart';
import '../widgets/glass_card.dart';
import '../widgets/fade_in.dart';

class InvoicesScreen extends StatefulWidget {
  final int initialSubTab;
  const InvoicesScreen({super.key, this.initialSubTab = 0});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  late int _activeSubTab;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Paid', 'Unpaid', 'Overdue'];

  @override
  void initState() {
    super.initState();
    _activeSubTab = widget.initialSubTab;
  }

  List<Invoice> _applyFilter(List<Invoice> invoices) {
    switch (_selectedFilter) {
      case 'Paid':
        return invoices
            .where((i) => i.paymentStatus == InvoiceStatus.paid)
            .toList();
      case 'Unpaid':
        return invoices
            .where((i) =>
                i.paymentStatus == InvoiceStatus.draft ||
                i.paymentStatus == InvoiceStatus.sent)
            .toList();
      case 'Overdue':
        return invoices
            .where((i) => i.paymentStatus == InvoiceStatus.overdue)
            .toList();
      default:
        return invoices;
    }
  }

  Color _statusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return AppTheme.successGreen;
      case InvoiceStatus.overdue:
        return AppTheme.dangerRed;
      case InvoiceStatus.sent:
        return AppTheme.emberOrange;
      case InvoiceStatus.draft:
        return AppTheme.textMuted;
    }
  }

  void _showDetailSheet(BuildContext context, Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvoiceDetailSheet(invoice: invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_activeSubTab == 1) {
      return QuotationsScreen(
        topNavigation: _buildTabSegmentToggle(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        title: _buildTabSegmentToggle(),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildFilterRow(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.fireRed,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: BackgroundGlow(
        child: Consumer<InvoiceService>(
          builder: (context, service, _) {
            final filtered = _applyFilter(service.allInvoices);
            if (filtered.isEmpty) {
              return FadeIn(
                delayMs: 200,
                child: _buildEmptyState(),
              );
            }
            return FadeIn(
              delayMs: 200,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return _InvoiceCard(
                    invoice: filtered[index],
                    statusColor: _statusColor(filtered[index].paymentStatus),
                    onTap: () => _showDetailSheet(context, filtered[index]),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabSegmentToggle() {
    return Container(
      width: 240,
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeSubTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _activeSubTab == 0 ? AppTheme.fireRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Invoices',
                  style: TextStyle(
                    color: _activeSubTab == 0 ? Colors.white : AppTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeSubTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _activeSubTab == 1 ? AppTheme.fireRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Quotations',
                  style: TextStyle(
                    color: _activeSubTab == 1 ? Colors.white : AppTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return FadeIn(
      delayMs: 100,
      child: SizedBox(
        height: 52,
        child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.fireRed
                    : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.fireRed
                      : AppTheme.borderColor,
                  width: 1,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 64,
            color: AppTheme.fireRed.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No invoices yet',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to create your first invoice',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Invoice Card ────────────────────────────────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final Color statusColor;
  final VoidCallback onTap;

  const _InvoiceCard({
    required this.invoice,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final dateFormatter = DateFormat('dd MMM yyyy');
    final status = invoice.paymentStatus;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: invoice number + status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  _StatusBadge(
                      label: status.label, color: statusColor),
                ],
              ),
              const SizedBox(height: 10),
              // Client name
              Text(
                invoice.clientName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              // Due date
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppTheme.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    'Due: ${dateFormatter.format(invoice.dueDate)}',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppTheme.borderColor, height: 1),
              const SizedBox(height: 10),
              // Amount row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 11),
                      ),
                      Text(
                        'KES ${formatter.format(invoice.total)}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (invoice.balance > 0 &&
                      status != InvoiceStatus.draft)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Balance',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 11),
                        ),
                        Text(
                          'KES ${formatter.format(invoice.balance)}',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Invoice Detail Bottom Sheet ─────────────────────────────────────────────

class _InvoiceDetailSheet extends StatelessWidget {
  final Invoice invoice;

  const _InvoiceDetailSheet({required this.invoice});

  Color _statusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return AppTheme.successGreen;
      case InvoiceStatus.overdue:
        return AppTheme.dangerRed;
      case InvoiceStatus.sent:
        return AppTheme.emberOrange;
      case InvoiceStatus.draft:
        return AppTheme.textMuted;
    }
  }

  void _showRecordPaymentDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        title: const Text(
          'Record Payment',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance: KES ${NumberFormat('#,##0', 'en_US').format(invoice.balance)}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Amount Paid (KES)',
                prefixText: 'KES ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
              if (amount > 0) {
                context
                    .read<InvoiceService>()
                    .recordPayment(invoice.id, amount);
                Navigator.pop(ctx);
                Navigator.pop(context); // close bottom sheet
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        title: const Text(
          'Delete Invoice',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete ${invoice.invoiceNumber}? This cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed),
            onPressed: () {
              context.read<InvoiceService>().deleteInvoice(invoice.id);
              Navigator.pop(ctx);
              Navigator.pop(context); // close bottom sheet
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numFmt = NumberFormat('#,##0.00', 'en_US');
    final dateFmt = DateFormat('dd MMM yyyy');
    final status = invoice.paymentStatus;
    final statusColor = _statusColor(status);
    final items = invoice.items;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppTheme.borderColor, width: 1),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              invoice.invoiceNumber,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _StatusBadge(
                              label: status.label, color: statusColor),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Client info
                      _SectionLabel('CLIENT'),
                      const SizedBox(height: 8),
                      _InfoRow(
                          icon: Icons.person_outline,
                          value: invoice.clientName),
                      if (invoice.clientPhone.isNotEmpty)
                        _InfoRow(
                            icon: Icons.phone_outlined,
                            value: invoice.clientPhone),
                      if (invoice.clientAddress.isNotEmpty)
                        _InfoRow(
                            icon: Icons.location_on_outlined,
                            value: invoice.clientAddress),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _InfoRow(
                              icon: Icons.calendar_today_outlined,
                              value:
                                  'Issued: ${dateFmt.format(invoice.issueDate)}'),
                          const SizedBox(width: 16),
                          _InfoRow(
                              icon: Icons.event_outlined,
                              value:
                                  'Due: ${dateFmt.format(invoice.dueDate)}'),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: AppTheme.borderColor),
                      const SizedBox(height: 12),

                      // Line items
                      _SectionLabel('LINE ITEMS'),
                      const SizedBox(height: 10),
                      // Table header
                      Row(
                        children: [
                          const Expanded(
                            flex: 4,
                            child: Text(
                              'Description',
                              style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(
                            width: 40,
                            child: Text(
                              'Qty',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(
                            width: 80,
                            child: Text(
                              'Unit Price',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(
                            width: 80,
                            child: Text(
                              'Total',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Divider(color: AppTheme.borderColor, height: 1),
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  item.description,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 13),
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  item.quantity
                                      .toStringAsFixed(
                                          item.quantity % 1 == 0 ? 0 : 1),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  numFmt.format(item.unitPrice),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  numFmt.format(item.total),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(color: AppTheme.borderColor, height: 1),

                      const SizedBox(height: 16),
                      // Totals
                      _TotalRow(
                          label: 'Subtotal',
                          value: 'KES ${numFmt.format(invoice.subtotal)}'),
                      const SizedBox(height: 6),
                      _TotalRow(
                          label: 'VAT (${(invoice.taxRate * 100).toStringAsFixed(0)}%)',
                          value: 'KES ${numFmt.format(invoice.taxAmount)}'),
                      const SizedBox(height: 8),
                      const Divider(color: AppTheme.borderColor),
                      _TotalRow(
                        label: 'TOTAL',
                        value: 'KES ${numFmt.format(invoice.total)}',
                        isTotal: true,
                      ),
                      if (invoice.amountPaid > 0) ...[
                        const SizedBox(height: 6),
                        _TotalRow(
                          label: 'Amount Paid',
                          value: 'KES ${numFmt.format(invoice.amountPaid)}',
                          valueColor: AppTheme.successGreen,
                        ),
                        _TotalRow(
                          label: 'Balance Due',
                          value: 'KES ${numFmt.format(invoice.balance)}',
                          valueColor: invoice.balance > 0
                              ? AppTheme.dangerRed
                              : AppTheme.successGreen,
                        ),
                      ],

                      if (invoice.notes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(color: AppTheme.borderColor),
                        const SizedBox(height: 8),
                        _SectionLabel('NOTES'),
                        const SizedBox(height: 6),
                        Text(
                          invoice.notes,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Action buttons
                      if (invoice.paymentStatus != InvoiceStatus.paid)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _showRecordPaymentDialog(context),
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Record Payment'),
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showDeleteDialog(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.dangerRed,
                            side: const BorderSide(
                                color: AppTheme.dangerRed, width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.dangerRed),
                          label: const Text('Delete Invoice'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppTheme.borderColor),
                      const SizedBox(height: 12),
                      _SectionLabel('PDF EXPORT'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final pdfBytes = await InvoicePdfService.generateFromInvoice(invoice);
                                await Printing.layoutPdf(onLayout: (_) => pdfBytes);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1F548F),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.print_rounded, color: Colors.white, size: 20),
                              label: const Text('Print', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final pdfBytes = await InvoicePdfService.generateFromInvoice(invoice);
                                final safeNo = invoice.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '');
                                await Printing.sharePdf(
                                  bytes: pdfBytes,
                                  filename: 'SIMKA_Invoice_$safeNo.pdf',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.emberOrange,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                              label: const Text('Download', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.fireRed,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _InfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontSize: isTotal ? 15 : 13,
            fontWeight:
                isTotal ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ??
                (isTotal ? AppTheme.textPrimary : AppTheme.textSecondary),
            fontSize: isTotal ? 16 : 13,
            fontWeight:
                isTotal ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
