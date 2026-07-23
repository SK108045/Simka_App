import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../services/client_service.dart';
import '../theme/app_theme.dart';

class AddClientScreen extends StatefulWidget {
  final Client? existingClient; // null = add mode, non-null = edit mode

  const AddClientScreen({super.key, this.existingClient});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final List<TextEditingController> _serviceTypeCtrls = [TextEditingController()];

  DateTime _lastServiceDate = DateTime.now();
  DateTime _nextServiceDate = DateTime.now().add(const Duration(days: 90));
  bool _saving = false;

  bool get _isEditing => widget.existingClient != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.existingClient!;
      _nameCtrl.text = c.name;
      _phoneCtrl.text = c.phone;
      _addressCtrl.text = c.address;
      if (c.serviceType.contains(', ')) {
        _serviceTypeCtrls.clear();
        for (var s in c.serviceType.split(', ')) {
          _serviceTypeCtrls.add(TextEditingController(text: s));
        }
      } else {
        _serviceTypeCtrls[0].text = c.serviceType;
      }
      _lastServiceDate = c.lastServiceDate;
      _nextServiceDate = c.nextServiceDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    for (var ctrl in _serviceTypeCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(bool isNext) async {
    final initial = isNext ? _nextServiceDate : _lastServiceDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.fireRed,
            surface: AppTheme.cardDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isNext) {
          _nextServiceDate = picked;
        } else {
          _lastServiceDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final svc = context.read<ClientService>();
    try {
      final combinedServices = _serviceTypeCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .join(', ');

      if (_isEditing) {
        final updated = widget.existingClient!.copyWith(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          serviceType: combinedServices,
          lastServiceDate: _lastServiceDate,
          nextServiceDate: _nextServiceDate,
          notes: widget.existingClient!.notes,
        );
        await svc.updateClient(updated);
      } else {
        await svc.addClient(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          serviceType: combinedServices,
          lastServiceDate: _lastServiceDate,
          nextServiceDate: _nextServiceDate,
          notes: '',
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.dangerRed),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Client' : 'Add New Client'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.fireRed,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  color: AppTheme.fireRed,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionLabel('Client Information'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameCtrl,
              label: 'Client / Business Name',
              icon: Icons.business_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _addressCtrl,
              label: 'Address / Location',
              icon: Icons.location_on_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Address is required' : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabel('Service Details'),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _serviceTypeCtrls.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.fireRed, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._serviceTypeCtrls.asMap().entries.map((entry) {
              final idx = entry.key;
              final ctrl = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: ctrl,
                        label: idx == 0 ? 'Service Type (e.g. Fire Extinguisher)' : 'Additional Service',
                        icon: Icons.fire_extinguisher_rounded,
                        validator: idx == 0 ? (v) => v == null || v.trim().isEmpty ? 'Service Type is required' : null : null,
                      ),
                    ),
                    if (idx > 0) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          // Unfocus the field before removing to prevent focus-related crash
                          FocusScope.of(context).unfocus();
                          
                          // Store controller reference to dispose AFTER the frame finishes rendering
                          final ctrlToDispose = _serviceTypeCtrls[idx];
                          
                          setState(() {
                            _serviceTypeCtrls.removeAt(idx);
                          });
                          
                          // Dispose safely after the widget is fully removed from the tree
                          Future.microtask(() => ctrlToDispose.dispose());
                        },
                        icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textMuted),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),
            // Last service date
            _buildDateTile(
              label: 'Last Service Date',
              date: _lastServiceDate,
              icon: Icons.history_rounded,
              onTap: () => _pickDate(false),
              df: df,
            ),
            const SizedBox(height: 10),
            // Next service date
            _buildDateTile(
              label: 'Next Service Date',
              date: _nextServiceDate,
              icon: Icons.calendar_today_rounded,
              onTap: () => _pickDate(true),
              df: df,
              highlight: true,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded),
                label:
                    Text(_isEditing ? 'Update Client' : 'Add Client'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.fireRed,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
    required DateFormat df,
    bool highlight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? AppTheme.fireRed.withValues(alpha: 0.5) : AppTheme.borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: highlight ? AppTheme.fireRed : AppTheme.textMuted,
                size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(df.format(date),
                    style: TextStyle(
                      color: highlight
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontSize: 15,
                      fontWeight:
                          highlight ? FontWeight.w600 : FontWeight.normal,
                    )),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
