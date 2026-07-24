import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import '../theme/app_theme.dart';
import 'create_invoice_screen.dart';
import 'quotations_screen.dart';
import '../widgets/background_glow.dart';
import '../widgets/glass_card.dart';
import '../widgets/fade_in.dart';
import 'pdf_preview_screen.dart';

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

  void _showDetailScreen(BuildContext context, Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceDetailScreen(invoice: invoice),
      ),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.fireRed,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          );
        },
        icon: const Icon(Icons.add, size: 20),
        label: const Text('New Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    onDelete: () => service.deleteInvoice(filtered[index].id),
                    onTap: () => _showDetailScreen(context, filtered[index]),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.fireRed : AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.fireRed : AppTheme.borderColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
            color: AppTheme.fireRed.withOpacity(0.4),
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
  final VoidCallback onDelete;

  const _InvoiceCard({
    required this.invoice,
    required this.statusColor,
    required this.onTap,
    required this.onDelete,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        invoice.invoiceNumber,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    _StatusBadge(label: status.label, color: statusColor),
                    const SizedBox(width: 8),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.dangerRed),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.surfaceDark,
                            title: const Text('Delete Invoice', style: TextStyle(color: AppTheme.textPrimary)),
                            content: const Text('Are you sure you want to delete this invoice?', style: TextStyle(color: AppTheme.textSecondary)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  onDelete();
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  invoice.clientName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      'Due: ${dateFormatter.format(invoice.dueDate)}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: AppTheme.borderColor, height: 1),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ksh ${formatter.format(invoice.total)}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (invoice.balance > 0 && status != InvoiceStatus.draft)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Balance',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ksh ${formatter.format(invoice.balance)}',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Invoice Detail Screen ───────────────────────────────────────────────────

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

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
        backgroundColor: AppTheme.surfaceDark,
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
              'Balance: Ksh ${NumberFormat('#,##0', 'en_US').format(invoice.balance)}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Amount Paid (Ksh)',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                prefixText: 'Ksh ',
                prefixStyle: const TextStyle(color: AppTheme.textPrimary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.fireRed),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.fireRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
              if (amount > 0) {
                context.read<InvoiceService>().recordPayment(invoice.id, amount);
                Navigator.pop(ctx);
                Navigator.pop(context); // Go back to list
              }
            },
            child: const Text('Save Payment', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        title: const Text(
          'Delete Invoice',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to permanently delete ${invoice.invoiceNumber}?',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              context.read<InvoiceService>().deleteInvoice(invoice.id);
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back to list
            },
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
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

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppTheme.fireRed),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PdfPreviewScreen(invoice: invoice)),
              );
            },
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _StatusBadge(label: status.label, color: statusColor),
            ),
          )
        ],
      ),
      body: BackgroundGlow(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client info card
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('CLIENT DETAILS'),
                      const SizedBox(height: 12),
                      _InfoRow(icon: Icons.person_outline, value: invoice.clientName),
                      if (invoice.clientPhone.isNotEmpty)
                        _InfoRow(icon: Icons.phone_outlined, value: invoice.clientPhone),
                      if (invoice.clientAddress.isNotEmpty)
                        _InfoRow(icon: Icons.location_on_outlined, value: invoice.clientAddress),
                      const SizedBox(height: 12),
                      const Divider(color: AppTheme.borderColor),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoRow(
                              icon: Icons.calendar_today_outlined,
                              value: 'Issued\\n${dateFmt.format(invoice.issueDate)}',
                            ),
                          ),
                          Expanded(
                            child: _InfoRow(
                              icon: Icons.event_outlined,
                              value: 'Due Date\\n${dateFmt.format(invoice.dueDate)}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Line items card
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('LINE ITEMS'),
                      const SizedBox(height: 16),
                      // Table header
                      Row(
                        children: [
                          const Expanded(
                            flex: 3,
                            child: Text('Description', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 40, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
                          const SizedBox(width: 80, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
                          const SizedBox(width: 80, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: AppTheme.borderColor, height: 1),
                      const SizedBox(height: 10),
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(item.description, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1), textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(numFmt.format(item.unitPrice), textAlign: TextAlign.right, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(numFmt.format(item.total), textAlign: TextAlign.right, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppTheme.borderColor, height: 1),
                      const SizedBox(height: 16),

                      // Totals
                      _TotalRow(label: 'Subtotal', value: 'Ksh ${numFmt.format(invoice.subtotal)}'),
                      const SizedBox(height: 8),
                      _TotalRow(label: 'VAT (${(invoice.taxRate * 100).toStringAsFixed(0)}%)', value: 'Ksh ${numFmt.format(invoice.taxAmount)}'),
                      const SizedBox(height: 12),
                      const Divider(color: AppTheme.borderColor),
                      const SizedBox(height: 12),
                      _TotalRow(label: 'TOTAL', value: 'Ksh ${numFmt.format(invoice.total)}', isTotal: true),
                      
                      if (invoice.amountPaid > 0) ...[
                        const SizedBox(height: 12),
                        _TotalRow(label: 'Amount Paid', value: 'Ksh ${numFmt.format(invoice.amountPaid)}', valueColor: AppTheme.successGreen),
                        const SizedBox(height: 8),
                        _TotalRow(
                          label: 'Balance Due',
                          value: 'Ksh ${numFmt.format(invoice.balance)}',
                          valueColor: invoice.balance > 0 ? AppTheme.dangerRed : AppTheme.successGreen,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (invoice.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('NOTES'),
                        const SizedBox(height: 10),
                        Text(
                          invoice.notes,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Action buttons
              if (invoice.paymentStatus != InvoiceStatus.paid)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.fireRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    onPressed: () => _showRecordPaymentDialog(context),
                    icon: const Icon(Icons.payments_outlined, size: 22),
                    label: const Text('Record Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showDeleteDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.dangerRed,
                    side: const BorderSide(color: AppTheme.dangerRed, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 22),
                  label: const Text('Delete Invoice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
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
        fontSize: 12,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
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
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? (isTotal ? AppTheme.textPrimary : AppTheme.textSecondary),
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
