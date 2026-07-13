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
  final _notesCtrl = TextEditingController();

  String _serviceType = 'Fire Extinguisher';
  DateTime _lastServiceDate = DateTime.now();
  DateTime _nextServiceDate = DateTime.now().add(const Duration(days: 90));
  bool _saving = false;

  final List<String> _serviceTypes = [
    'Fire Extinguisher',
    'Fire Suppression System',
    'Fire Alarm System',
    'Sprinkler System',
    'Emergency Lighting',
    'Fire Hose Reel',
    'General Fire Inspection',
  ];

  bool get _isEditing => widget.existingClient != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.existingClient!;
      _nameCtrl.text = c.name;
      _phoneCtrl.text = c.phone;
      _addressCtrl.text = c.address;
      _notesCtrl.text = c.notes;
      _serviceType = c.serviceType;
      _lastServiceDate = c.lastServiceDate;
      _nextServiceDate = c.nextServiceDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
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
      if (_isEditing) {
        final updated = widget.existingClient!.copyWith(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          serviceType: _serviceType,
          lastServiceDate: _lastServiceDate,
          nextServiceDate: _nextServiceDate,
          notes: _notesCtrl.text.trim(),
        );
        await svc.updateClient(updated);
      } else {
        await svc.addClient(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          serviceType: _serviceType,
          lastServiceDate: _lastServiceDate,
          nextServiceDate: _nextServiceDate,
          notes: _notesCtrl.text.trim(),
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
            _sectionLabel('Service Details'),
            const SizedBox(height: 12),
            // Service type dropdown
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _serviceType,
                  isExpanded: true,
                  dropdownColor: AppTheme.cardDark,
                  icon: const Icon(Icons.expand_more, color: AppTheme.textMuted),
                  items: _serviceTypes.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.fire_extinguisher_rounded,
                            color: AppTheme.fireRed,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(t,
                              style:
                                  const TextStyle(color: AppTheme.textPrimary)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _serviceType = v!),
                ),
              ),
            ),
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
            const SizedBox(height: 24),
            _sectionLabel('Notes (optional)'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Any additional notes about this client...',
              ),
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
