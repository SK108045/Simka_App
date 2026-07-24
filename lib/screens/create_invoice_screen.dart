import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice_item.dart';
import '../services/invoice_service.dart';
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

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

// Internal editable line item model
class _LineItemRow {
  String serviceType;
  final TextEditingController descriptionCtrl;
  final TextEditingController codeCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  _LineItemRow()
      : serviceType = 'Custom',
        descriptionCtrl = TextEditingController(),
        codeCtrl = TextEditingController(),
        qtyCtrl = TextEditingController(text: '1'),
        priceCtrl = TextEditingController();

  double get qty => double.tryParse(qtyCtrl.text) ?? 0;
  double get price => double.tryParse(priceCtrl.text) ?? 0;
  double get total => qty * price;

  InvoiceItem toItem() => InvoiceItem(
        description: descriptionCtrl.text.trim(),
        code: codeCtrl.text.trim(),
        quantity: qty,
        unitPrice: price,
      );

  void dispose() {
    descriptionCtrl.dispose();
    codeCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _clientNameCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  final _clientAddressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  final List<_LineItemRow> _lineItems = [_LineItemRow()];

  // Formatters
  final _dateFmt = DateFormat('dd MMM yyyy');
  final _numFmt = NumberFormat('#,##0.00', 'en_US');

  static const double _vatRate = 0.0;

  double get _subtotal =>
      _lineItems.fold(0, (sum, row) => sum + row.total);
  double get _vat => _subtotal * _vatRate;
  double get _total => _subtotal + _vat;

  @override
  void dispose() {
    _clientNameCtrl.dispose();
    _clientPhoneCtrl.dispose();
    _clientAddressCtrl.dispose();
    _notesCtrl.dispose();
    for (final row in _lineItems) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(
      BuildContext context, bool isIssue) async {
    final initial = isIssue ? _issueDate : _dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.fireRed,
            surface: AppTheme.cardDark,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: AppTheme.surfaceDark),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isIssue) {
          _issueDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  void _addLineItem() {
    setState(() => _lineItems.add(_LineItemRow()));
  }

  void _removeLineItem(int index) {
    if (_lineItems.length == 1) return; // keep at least one
    setState(() {
      _lineItems[index].dispose();
      _lineItems.removeAt(index);
    });
  }

  Future<void> _save({required bool send}) async {
    if (!_formKey.currentState!.validate()) return;

    final validItems = _lineItems
        .where((r) => r.descriptionCtrl.text.trim().isNotEmpty)
        .toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one line item.'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    final service = context.read<InvoiceService>();
    await service.addInvoice(
      clientId: const Uuid().v4(),
      clientName: _clientNameCtrl.text.trim(),
      clientPhone: _clientPhoneCtrl.text.trim(),
      clientAddress: _clientAddressCtrl.text.trim(),
      issueDate: _issueDate,
      dueDate: _dueDate,
      items: validItems.map((r) => r.toItem()).toList(),
      taxRate: _vatRate,
      status: send ? 'sent' : 'draft',
      notes: _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(send
            ? 'Invoice created and marked as Sent.'
            : 'Invoice saved as Draft.'),
        backgroundColor:
            send ? AppTheme.fireRed : AppTheme.surfaceDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        title: const Text('New Invoice'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // ── Client Details ──────────────────────────────────────
            _SectionHeader(
                icon: Icons.person_outline, label: 'Client Details'),
            const SizedBox(height: 12),
            _darkField(
              controller: _clientNameCtrl,
              label: 'Client Name',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            _darkField(
              controller: _clientPhoneCtrl,
              label: 'Phone Number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            _darkField(
              controller: _clientAddressCtrl,
              label: 'Address',
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // ── Dates ───────────────────────────────────────────────
            _SectionHeader(icon: Icons.calendar_month_outlined, label: 'Dates'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'Issue Date',
                    date: _issueDate,
                    formatter: _dateFmt,
                    onTap: () => _pickDate(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateButton(
                    label: 'Due Date',
                    date: _dueDate,
                    formatter: _dateFmt,
                    onTap: () => _pickDate(context, false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Line Items ──────────────────────────────────────────
            _SectionHeader(
                icon: Icons.list_alt_outlined, label: 'Line Items'),
            const SizedBox(height: 12),

            const SizedBox(height: 12),

            ..._lineItems.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return _LineItemWidget(
                key: ValueKey(row),
                row: row,
                onRemove: () => _removeLineItem(index),
                onChanged: () => setState(() {}),
                numFmt: _numFmt,
              );
            }),

            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addLineItem,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.fireRed,
                side: const BorderSide(
                    color: AppTheme.fireRed, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Item'),
            ),

            const SizedBox(height: 24),

            // ── Notes ───────────────────────────────────────────────
            _SectionHeader(icon: Icons.notes_outlined, label: 'Notes'),
            const SizedBox(height: 12),
            _darkField(
              controller: _notesCtrl,
              label: 'Additional notes (optional)',
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // ── Summary ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                      label: 'Subtotal',
                      value: 'Ksh ${_numFmt.format(_subtotal)}'),
                  const SizedBox(height: 8),
                  _SummaryRow(
                      label: 'VAT (0%)',
                      value: 'Ksh ${_numFmt.format(_vat)}'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: AppTheme.borderColor),
                  ),
                  _SummaryRow(
                    label: 'TOTAL',
                    value: 'Ksh ${_numFmt.format(_total)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Actions ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _save(send: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(
                          color: AppTheme.borderColor, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save as Draft'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _save(send: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.fireRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save & Send'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _darkField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surfaceDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.fireRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.dangerRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.dangerRed, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

// ─── Line Item Widget ─────────────────────────────────────────────────────────

class _LineItemWidget extends StatefulWidget {
  final _LineItemRow row;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final NumberFormat numFmt;

  const _LineItemWidget({
    super.key,
    required this.row,
    required this.onRemove,
    required this.onChanged,
    required this.numFmt,
  });

  @override
  State<_LineItemWidget> createState() => _LineItemWidgetState();
}

class _LineItemWidgetState extends State<_LineItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: widget.row.serviceType,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceDark,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                    items: [
                      ...PREDEFINED_SERVICES.map((s) => DropdownMenuItem(
                            value: s['description'] as String,
                            child: Text(s['description'] as String, overflow: TextOverflow.ellipsis),
                          )),
                      const DropdownMenuItem(value: 'Custom', child: Text('Custom...')),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        widget.row.serviceType = val;
                        if (val != 'Custom') {
                          final sel = PREDEFINED_SERVICES.firstWhere((s) => s['description'] == val);
                          widget.row.descriptionCtrl.text = sel['description'] as String;
                          widget.row.codeCtrl.text = sel['code'] as String;
                          widget.row.priceCtrl.text = sel['unit_price'].toString();
                        } else {
                          widget.row.descriptionCtrl.clear();
                          widget.row.codeCtrl.clear();
                          widget.row.priceCtrl.clear();
                        }
                      });
                      widget.onChanged();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.dangerRed, size: 20),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            if (widget.row.serviceType == 'Custom') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _CompactField(
                      controller: widget.row.codeCtrl,
                      hint: 'Item Code',
                      onChanged: (_) => widget.onChanged(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _CompactField(
                      controller: widget.row.descriptionCtrl,
                      hint: 'Custom Description',
                      onChanged: (_) => widget.onChanged(),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Qty', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      const SizedBox(height: 4),
                      _CompactField(
                        controller: widget.row.qtyCtrl,
                        hint: '1',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => widget.onChanged(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Unit Price (Ksh)', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      const SizedBox(height: 4),
                      _CompactField(
                        controller: widget.row.priceCtrl,
                        hint: '0.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => widget.onChanged(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      const SizedBox(height: 4),
                      Container(
                        height: 40,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Text(
                          widget.numFmt.format(widget.row.total),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Compact Field ────────────────────────────────────────────────────────────

class _CompactField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _CompactField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style:
          const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppTheme.textMuted, fontSize: 12),
        filled: true,
        fillColor: AppTheme.surfaceDark,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppTheme.fireRed, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Date Picker Button ───────────────────────────────────────────────────────

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final DateFormat formatter;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppTheme.fireRed),
                const SizedBox(width: 6),
                Text(
                  formatter.format(date),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.fireRed),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Summary Row ──────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color:
                isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontSize: isTotal ? 15 : 13,
            fontWeight:
                isTotal ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? AppTheme.fireRed : AppTheme.textSecondary,
            fontSize: isTotal ? 16 : 13,
            fontWeight:
                isTotal ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
