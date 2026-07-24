import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/invoice_item.dart';
import '../services/quotation_service.dart';
import '../theme/app_theme.dart';

const List<Map<String, dynamic>> PREDEFINED_SERVICES = [
  {"code": "STFS/FES/0003", "description": "6 LITRE FOAM FIRE EXTINGUISHER SERVICE", "unit_price": 300},
  {"code": "STFS/FES/0006", "description": "9 LITRE WATER FIRE EXTINGUISHER SERVICE", "unit_price": 300},
  {"code": "STFS/FES/0007", "description": "CATRIDGE REPLACEMENT", "unit_price": 2000},
  {"code": "STFS/FES/0008", "description": "CATRIDGE REFILL", "unit_price": 1500},
  {"code": "STFS/FES/0002", "description": "4KG/6KG/9KG DRY CHEMICAL POWDER FIRE EXTINGUISHER SERVICE", "unit_price": 300},
  {"code": "STFS/FES/001", "description": "2KG/5KG CO2 FIRE EXTINGUISHER SERVICE", "unit_price": 300},
  {"code": "STFS/FES/0010", "description": "FIRE BLANKET 4 X 4 SERVICE", "unit_price": 300},
  {"code": "STFS/FES/0011A", "description": "9 KG DRY CHEMICAL POWDER REFILL AND PRESSURIZING", "unit_price": 2500},
  {"code": "STFS/FES/0005", "description": "9 KG DRY POWDER FIRE EXTINGUISHER SERVICE", "unit_price": 300},
  {"code": "STFS/FES/0009", "description": "FIRE ALARM SYSTEM TESTING AND SERVICING", "unit_price": 4500},
  {"code": "STFS/FES/0004", "description": "CALL POINT BREAK GLASS REPLACEMENT", "unit_price": 600},
];

// ─────────────────────────────────────────────────────────────────────────────
// Create Quotation Screen
// ─────────────────────────────────────────────────────────────────────────────

class CreateQuotationScreen extends StatefulWidget {
  const CreateQuotationScreen({super.key});

  @override
  State<CreateQuotationScreen> createState() => _CreateQuotationScreenState();
}

class _CreateQuotationScreenState extends State<CreateQuotationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Client fields
  final _clientNameCtrl   = TextEditingController();
  final _clientPhoneCtrl  = TextEditingController();
  final _clientAddressCtrl = TextEditingController();
  final _notesCtrl        = TextEditingController();

  // Dates
  DateTime _issueDate  = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));

  // Tax
  double _taxRate = 0.16;

  // Currency
  String _currency = 'Ksh';
  static const _currencies = ['Ksh', 'USD', 'EUR', 'GBP'];

  // Line Items
  final List<_ItemRow> _items = [];

  bool _saving = false;

  @override
  void dispose() {
    _clientNameCtrl.dispose();
    _clientPhoneCtrl.dispose();
    _clientAddressCtrl.dispose();
    _notesCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  List<InvoiceItem> _buildItems() {
    return _items
        .map((r) => InvoiceItem(
              description: r.descCtrl.text.trim(),
              code: r.codeCtrl.text.trim(),
              quantity: double.tryParse(r.qtyCtrl.text) ?? 1,
              unitPrice: double.tryParse(r.priceCtrl.text) ?? 0,
            ))
        .where((i) => i.description.isNotEmpty)
        .toList();
  }

  double get _subtotal =>
      _items.fold(0, (s, r) => s + (double.tryParse(r.qtyCtrl.text) ?? 0) * (double.tryParse(r.priceCtrl.text) ?? 0));
  double get _taxAmount => _subtotal * _taxRate;
  double get _total     => _subtotal + _taxAmount;

  Future<void> _pickDate(bool isIssue) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isIssue ? _issueDate : _validUntil,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.fireRed,
            surface: AppTheme.cardDark,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: AppTheme.cardDark),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isIssue) {
          _issueDate = picked;
        } else {
          _validUntil = picked;
        }
      });
    }
  }

  Future<void> _save(String status) async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      _showSnack('Add at least one line item.', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final svc = context.read<QuotationService>();
      final quotation = await svc.addQuotation(
        clientId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        clientName: _clientNameCtrl.text.trim(),
        clientPhone: _clientPhoneCtrl.text.trim(),
        clientAddress: _clientAddressCtrl.text.trim(),
        issueDate: _issueDate,
        validUntil: _validUntil,
        items: _buildItems(),
        taxRate: _taxRate,
        status: status,
        notes: _notesCtrl.text.trim(),
        currency: _currency,
      );
      if (mounted) {
        Navigator.pop(context);
        _showSnack(
          status == 'draft'
              ? '${quotation.quoteNumber} saved as draft.'
              : '${quotation.quoteNumber} sent.',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppTheme.dangerRed : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    final nf = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('New Quotation'),
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // ── Client Information ──────────────────────────────────────
            _sectionLabel('CLIENT INFORMATION'),
            const SizedBox(height: 8),
            _darkField(
              controller: _clientNameCtrl,
              label: 'Client Name *',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Client name is required' : null,
            ),
            const SizedBox(height: 10),
            _darkField(
              controller: _clientPhoneCtrl,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            _darkField(
              controller: _clientAddressCtrl,
              label: 'Address',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            // ── Quote Dates ─────────────────────────────────────────────
            _sectionLabel('DATES'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _dateTile(
                    label: 'Issue Date',
                    date: df.format(_issueDate),
                    icon: Icons.today_outlined,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dateTile(
                    label: 'Valid Until',
                    date: df.format(_validUntil),
                    icon: Icons.event_outlined,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Currency & Tax ──────────────────────────────────────────
            _sectionLabel('CURRENCY & TAX'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currency,
                        dropdownColor: AppTheme.cardDark,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.textMuted),
                        items: _currencies
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _currency = v ?? 'Ksh'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<double>(
                        value: _taxRate,
                        dropdownColor: AppTheme.cardDark,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.textMuted),
                        items: [0.0, 0.08, 0.16]
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                      'VAT ${(t * 100).toStringAsFixed(0)}%'),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _taxRate = v ?? 0.16),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Line Items ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabel('LINE ITEMS'),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.fireRed,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => setState(() => _items.add(_ItemRow())),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text('Add Item',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_items.isEmpty)
              Container(
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.borderColor,
                      style: BorderStyle.solid),
                ),
                child: const Center(
                  child: Text(
                    'No items yet — tap Add Item',
                    style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              ),

            ..._items.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LineItemCard(
                  row: row,
                  index: i,
                  onRemove: () =>
                      setState(() => _items.removeAt(i)),
                  onChanged: () => setState(() {}),
                ),
              );
            }),

            // Totals preview
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    _totalPreviewRow('Subtotal',
                        '$_currency ${nf.format(_subtotal)}'),
                    const SizedBox(height: 4),
                    _totalPreviewRow(
                        'VAT ${(_taxRate * 100).toStringAsFixed(0)}%',
                        '$_currency ${nf.format(_taxAmount)}'),
                    const Divider(height: 14, color: AppTheme.borderColor),
                    _totalPreviewRow(
                      'TOTAL',
                      '$_currency ${nf.format(_total)}',
                      bold: true,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Notes ───────────────────────────────────────────────────
            _sectionLabel('NOTES (OPTIONAL)'),
            const SizedBox(height: 8),
            _darkField(
              controller: _notesCtrl,
              label: 'Additional notes or terms…',
              maxLines: 3,
            ),
          ],
        ),
      ),

      // ── Bottom Action Buttons ─────────────────────────────────────────
      bottomNavigationBar: Container(
        color: AppTheme.darkBg,
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        child: Row(
          children: [
            // Save as Draft
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : () => _save('draft'),
                icon: const Icon(Icons.drafts_outlined, size: 18),
                label: const Text('Save as Draft',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            // Send Quote
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.fireRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _saving ? null : () => _save('sent'),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: const Text('Send Quote',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppTheme.fireRed,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );

  Widget _darkField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, color: AppTheme.textMuted, size: 18)
            : null,
        filled: true,
        fillColor: AppTheme.surfaceDark,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.fireRed, width: 1.5)),
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
      ),
      validator: validator,
    );
  }

  Widget _dateTile({
    required String label,
    required String date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textMuted, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(date,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalPreviewRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                fontSize: bold ? 14 : 13)),
        Text(value,
            style: TextStyle(
                color: bold ? AppTheme.fireRed : AppTheme.textPrimary,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                fontSize: bold ? 14 : 13)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item Row State Helper
// ─────────────────────────────────────────────────────────────────────────────

class _ItemRow {
  String serviceType;
  final descCtrl  = TextEditingController();
  final codeCtrl  = TextEditingController();
  final qtyCtrl   = TextEditingController(text: '1');
  final priceCtrl = TextEditingController();

  _ItemRow() : serviceType = 'Custom';

  void dispose() {
    descCtrl.dispose();
    codeCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Line Item Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _LineItemCard extends StatelessWidget {
  final _ItemRow row;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _LineItemCard({
    required this.row,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final qty   = double.tryParse(row.qtyCtrl.text) ?? 0;
    final price = double.tryParse(row.priceCtrl.text) ?? 0;
    final total = qty * price;
    final nf    = NumberFormat('#,##0.00', 'en_US');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item ${index + 1}',
                style: const TextStyle(
                    color: AppTheme.fireRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8),
              ),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.remove_circle_outline_rounded,
                    color: AppTheme.dangerRed, size: 20),
              ),
            ],
          ),
          // Dropdown for predefined service
          DropdownButtonFormField<String>(
            value: row.serviceType,
            isExpanded: true,
            dropdownColor: AppTheme.surfaceDark,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            decoration: _fieldDecoration('Service'),
            items: [
              ...PREDEFINED_SERVICES.map((s) => DropdownMenuItem(
                    value: s['description'] as String,
                    child: Text(s['description'] as String, overflow: TextOverflow.ellipsis),
                  )),
              const DropdownMenuItem(value: 'Custom', child: Text('Custom...')),
            ],
            onChanged: (val) {
              if (val == null) return;
              row.serviceType = val;
              if (val != 'Custom') {
                final sel = PREDEFINED_SERVICES.firstWhere((s) => s['description'] == val);
                row.descCtrl.text = sel['description'] as String;
                row.codeCtrl.text = sel['code'] as String;
                row.priceCtrl.text = sel['unit_price'].toString();
              } else {
                row.descCtrl.clear();
                row.codeCtrl.clear();
                row.priceCtrl.clear();
              }
              onChanged();
            },
          ),
          if (row.serviceType == 'Custom') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: row.codeCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: _fieldDecoration('Item Code'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: row.descCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: _fieldDecoration('Custom Description'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          // Qty + Unit Price
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: row.qtyCtrl,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13),
                  decoration: _fieldDecoration('Qty'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: row.priceCtrl,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13),
                  decoration: _fieldDecoration('Unit Price'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Line total
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: ${nf.format(total)}',
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTheme.surfaceDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppTheme.fireRed, width: 1.5)),
        labelStyle:
            const TextStyle(color: AppTheme.textMuted, fontSize: 12),
      );
}
