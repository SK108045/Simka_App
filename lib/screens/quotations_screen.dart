import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/quotation.dart';

import '../services/quotation_service.dart';
import '../services/invoice_service.dart';
import '../theme/app_theme.dart';
import 'create_quotation_screen.dart';
import '../widgets/background_glow.dart';
import '../widgets/glass_card.dart';
import '../widgets/fade_in.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Quotations Screen
// ─────────────────────────────────────────────────────────────────────────────

class QuotationsScreen extends StatefulWidget {
  final Widget? topNavigation;
  const QuotationsScreen({super.key, this.topNavigation});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  // null means "All"
  String? _filterStatus;

  static const _filters = <String?>[null, 'draft', 'sent', 'accepted', 'rejected'];
  static const _filterLabels = ['All', 'Draft', 'Sent', 'Accepted', 'Rejected'];

  List<Quotation> _apply(List<Quotation> all) {
    if (_filterStatus == null) return all;
    return all.where((q) => q.status == _filterStatus).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted': return AppTheme.successGreen;
      case 'rejected': return AppTheme.dangerRed;
      case 'sent':     return AppTheme.emberOrange;
      default:         return AppTheme.textMuted;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted': return 'Accepted';
      case 'rejected': return 'Rejected';
      case 'sent':     return 'Sent';
      default:         return 'Draft';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: widget.topNavigation ?? const Text('Quotations'),
        centerTitle: true,
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.fireRed,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: BackgroundGlow(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Filter Chips ──────────────────────────────────────────────────
            FadeIn(
              delayMs: 100,
              child: SizedBox(
                height: 52,
                child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = _filterStatus == _filters[i];
                return GestureDetector(
                  onTap: () => setState(() => _filterStatus = _filters[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.fireRed.withValues(alpha: 0.15)
                          : AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppTheme.fireRed : AppTheme.borderColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _filterLabels[i],
                      style: TextStyle(
                        color: selected ? AppTheme.fireRed : AppTheme.textSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
              ),
            ),

            // ── List ─────────────────────────────────────────────────────────
            Expanded(
            child: Consumer<QuotationService>(
              builder: (ctx, svc, _) {
                final quotations = _apply(svc.allQuotations);
                if (quotations.isEmpty) {
                  return FadeIn(
                    delayMs: 200,
                    child: _EmptyState(),
                  );
                }
                return FadeIn(
                  delayMs: 200,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: quotations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                      _QuotationCard(
                        quotation: quotations[i],
                        statusColor: _statusColor(quotations[i].status),
                        statusLabel: _statusLabel(quotations[i].status),
                        onDelete: () => svc.deleteQuotation(quotations[i].id),
                        onTap: () => _showDetailSheet(context, quotations[i]),
                      ),
                  ),
                );
              },
            ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, Quotation quotation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuotationDetailSheet(quotation: quotation),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quotation Card
// ─────────────────────────────────────────────────────────────────────────────

class _QuotationCard extends StatelessWidget {
  final Quotation quotation;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _QuotationCard({
    required this.quotation,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    final nf = NumberFormat('#,##0.00', 'en_US');
    final expired = quotation.isExpired;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Quote number + status badge ─────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.fireRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: AppTheme.fireRed,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        quotation.quoteNumber,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (expired) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.warningAmber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppTheme.warningAmber.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'EXPIRED',
                            style: TextStyle(
                              color: AppTheme.warningAmber,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle,
                                color: statusColor, size: 6),
                            const SizedBox(width: 5),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                              title: const Text('Delete Quotation', style: TextStyle(color: AppTheme.textPrimary)),
                              content: const Text('Are you sure you want to delete this quotation?', style: TextStyle(color: AppTheme.textSecondary)),
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
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: AppTheme.borderColor),
              const SizedBox(height: 12),

              // ── Row 2: Client name ──────────────────────────────────────
              Text(
                quotation.clientName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              // ── Row 3: Valid Until + Total ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Valid until ${df.format(quotation.validUntil)}',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    '${quotation.currency} ${nf.format(quotation.total)}',
                    style: const TextStyle(
                      color: AppTheme.fireRed,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.fireRed.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppTheme.fireRed,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No quotations yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap + to create your first quote',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quotation Detail Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _QuotationDetailSheet extends StatelessWidget {
  final Quotation quotation;

  const _QuotationDetailSheet({required this.quotation});

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted': return AppTheme.successGreen;
      case 'rejected': return AppTheme.dangerRed;
      case 'sent':     return AppTheme.emberOrange;
      default:         return AppTheme.textMuted;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted': return 'Accepted';
      case 'rejected': return 'Rejected';
      case 'sent':     return 'Sent';
      default:         return 'Draft';
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    final nf = NumberFormat('#,##0.00', 'en_US');
    final sColor = _statusColor(quotation.status);
    final sLabel = _statusLabel(quotation.status);
    final items = quotation.items;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Drag Handle ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Sheet Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quotation.quoteNumber,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: sColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: sColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          sLabel,
                          style: TextStyle(
                            color: sColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppTheme.borderColor),

            // ── Scrollable Content ────────────────────────────────────────
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  // Client Info Card
                  _sectionCard(
                    title: 'CLIENT',
                    children: [
                      _detailRow(Icons.person_outline_rounded,
                          quotation.clientName, bold: true),
                      if (quotation.clientPhone.isNotEmpty)
                        _detailRow(
                            Icons.phone_outlined, quotation.clientPhone),
                      if (quotation.clientAddress.isNotEmpty)
                        _detailRow(Icons.location_on_outlined,
                            quotation.clientAddress),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Dates Card
                  _sectionCard(
                    title: 'DATES',
                    children: [
                      _detailRow(Icons.today_outlined,
                          'Issued: ${df.format(quotation.issueDate)}'),
                      _detailRow(Icons.event_outlined,
                          'Valid Until: ${df.format(quotation.validUntil)}',
                          valueColor: quotation.isExpired
                              ? AppTheme.warningAmber
                              : AppTheme.textSecondary),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Line Items Card
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'LINE ITEMS',
                                style: TextStyle(
                                  color: AppTheme.fireRed,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                '${items.length} item${items.length != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppTheme.borderColor),
                        // Table header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                          child: Row(
                            children: const [
                              Expanded(
                                flex: 4,
                                child: Text('Description',
                                    style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11)),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text('Qty',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11)),
                              ),
                              SizedBox(
                                width: 70,
                                child: Text('Unit',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11)),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text('Total',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppTheme.borderColor),
                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No items added.',
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 13)),
                          ),
                        ...items.map((item) => Padding(
                              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
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
                                              item.quantity % 1 == 0 ? 0 : 2),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 70,
                                    child: Text(
                                      nf.format(item.unitPrice),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      nf.format(item.total),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const Divider(height: 1, color: AppTheme.borderColor),
                        // Totals
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              _totalRow('Subtotal',
                                  '${quotation.currency} ${nf.format(quotation.subtotal)}'),
                              const SizedBox(height: 6),
                              _totalRow(
                                  'VAT (${(quotation.taxRate * 100).toStringAsFixed(0)}%)',
                                  '${quotation.currency} ${nf.format(quotation.taxAmount)}'),
                              const Divider(
                                  height: 16, color: AppTheme.borderColor),
                              _totalRow(
                                'TOTAL',
                                '${quotation.currency} ${nf.format(quotation.total)}',
                                bold: true,
                                valueColor: AppTheme.fireRed,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (quotation.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _sectionCard(
                      title: 'NOTES',
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            quotation.notes,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Action Buttons ────────────────────────────────────────
                  _StatusButtons(quotation: quotation),

                  const SizedBox(height: 12),

                  // Convert to Invoice (prominent)
                  _ConvertToInvoiceButton(quotation: quotation),

                  const SizedBox(height: 12),

                  // Delete
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.dangerRed,
                        side: const BorderSide(color: AppTheme.dangerRed),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () =>
                          _confirmDelete(context, quotation),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete Quotation'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.fireRed,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: valueColor ??
                    (bold ? AppTheme.textPrimary : AppTheme.textSecondary),
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            fontSize: bold ? 15 : 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.textPrimary,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            fontSize: bold ? 15 : 13,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Quotation q) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Quotation',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Remove ${q.quoteNumber} permanently? This cannot be undone.',
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
            onPressed: () async {
              final svc = context.read<QuotationService>();
              await svc.deleteQuotation(q.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Buttons
// ─────────────────────────────────────────────────────────────────────────────

class _StatusButtons extends StatelessWidget {
  final Quotation quotation;

  const _StatusButtons({required this.quotation});

  @override
  Widget build(BuildContext context) {
    final svc = context.read<QuotationService>();
    final status = quotation.status;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (status != 'sent' && status != 'accepted')
          _actionChip(
            label: 'Mark as Sent',
            icon: Icons.send_rounded,
            color: AppTheme.emberOrange,
            onTap: () async {
              await svc.updateStatus(quotation.id, 'sent');
              if (context.mounted) Navigator.pop(context);
            },
          ),
        if (status != 'accepted')
          _actionChip(
            label: 'Accept',
            icon: Icons.check_circle_outline_rounded,
            color: AppTheme.successGreen,
            onTap: () async {
              await svc.updateStatus(quotation.id, 'accepted');
              if (context.mounted) Navigator.pop(context);
            },
          ),
        if (status != 'rejected')
          _actionChip(
            label: 'Reject',
            icon: Icons.cancel_outlined,
            color: AppTheme.dangerRed,
            onTap: () async {
              await svc.updateStatus(quotation.id, 'rejected');
              if (context.mounted) Navigator.pop(context);
            },
          ),
      ],
    );
  }

  Widget _actionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Convert to Invoice Button
// ─────────────────────────────────────────────────────────────────────────────

class _ConvertToInvoiceButton extends StatefulWidget {
  final Quotation quotation;

  const _ConvertToInvoiceButton({required this.quotation});

  @override
  State<_ConvertToInvoiceButton> createState() =>
      _ConvertToInvoiceButtonState();
}

class _ConvertToInvoiceButtonState extends State<_ConvertToInvoiceButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.fireRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: _loading ? null : () => _convert(context),
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.receipt_long_rounded, size: 20),
        label: Text(
          _loading ? 'Converting…' : 'Convert to Invoice',
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),
    );
  }

  Future<void> _convert(BuildContext context) async {
    setState(() => _loading = true);
    try {
      final qSvc = context.read<QuotationService>();
      final invSvc = context.read<InvoiceService>();
      final invoice =
          await qSvc.convertToInvoice(widget.quotation, invSvc);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              'Invoice ${invoice.invoiceNumber} created!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.dangerRed,
            content: Text('Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
