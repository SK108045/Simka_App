import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/client.dart';
import '../services/client_service.dart';
import '../services/service_record_service.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import 'add_client_screen.dart';

class ClientDetailScreen extends StatelessWidget {
  final Client client;

  const ClientDetailScreen({super.key, required this.client});

  Color _statusColor(ServiceStatus s) {
    switch (s) {
      case ServiceStatus.past: return AppTheme.dangerRed;
      case ServiceStatus.urgent: return AppTheme.emberOrange;
      case ServiceStatus.upcoming: return AppTheme.warningAmber;
      case ServiceStatus.ok: return AppTheme.successGreen;
    }
  }

  Future<void> _launchWhatsApp(String phone, String clientName) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) return;
    final message = Uri.encodeComponent('Hello $clientName, this is SIMKA Fire Services checking in on your fire equipment.');
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMMM yyyy');
    final status = client.status;
    final statusColor = _statusColor(status);
    final days = client.daysUntilService;
    final svc = context.read<ClientService>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // ── App Bar ──────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: AppTheme.surfaceDark,
                pinned: true,
                expandedHeight: 220,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          statusColor.withValues(alpha: 0.25),
                          AppTheme.surfaceDark,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        // Avatar
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: statusColor, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              client.name[0].toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          client.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddClientScreen(existingClient: client),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.dangerRed),
                    onPressed: () => _confirmDelete(context, svc),
                  ),
                ],
                bottom: const TabBar(
                  indicatorColor: AppTheme.fireRed,
                  labelColor: AppTheme.fireRed,
                  unselectedLabelColor: AppTheme.textMuted,
                  tabs: [
                    Tab(text: 'Details'),
                    Tab(text: 'History'),
                    Tab(text: 'Payments'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // ── Tab 1: Details ─────────────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status pill
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.5), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: statusColor, size: 8),
                              const SizedBox(width: 8),
                              Text(
                                status.label,
                                style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          days < 0
                              ? '${days.abs()} days past'
                              : days == 0
                                  ? 'Service today!'
                                  : 'In $days days',
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Info cards
                    _infoSection('Contact', [
                      _infoRow(Icons.phone_rounded, 'Phone', client.phone.isEmpty ? 'Not provided' : client.phone,
                        trailing: client.phone.isNotEmpty ? IconButton(
                          icon: const Icon(Icons.chat_bubble_rounded, color: AppTheme.successGreen, size: 20),
                          onPressed: () => _launchWhatsApp(client.phone, client.name),
                          tooltip: 'Send WhatsApp Message',
                        ) : null,
                      ),
                      _infoRow(Icons.location_on_rounded, 'Address', client.address),
                    ]),

                    const SizedBox(height: 16),

                    _infoSection('Service', [
                      _infoRow(Icons.fire_extinguisher_rounded, 'Type', client.serviceType),
                      _infoRow(Icons.history_rounded, 'Last Serviced', df.format(client.lastServiceDate)),
                      _infoRow(Icons.calendar_today_rounded, 'Next Service', df.format(client.nextServiceDate)),
                    ]),

                    if (client.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _infoSection('Notes', [
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            client.notes,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 14),
                          ),
                        ),
                      ]),
                    ],

                    const SizedBox(height: 28),

                    // Mark as serviced button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showMarkServicedDialog(context, svc),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Mark as Serviced Today'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Edit button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: const BorderSide(color: AppTheme.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddClientScreen(existingClient: client),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit Details'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // ── Tab 2: History ─────────────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildServiceHistorySection(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // ── Tab 3: Payments ────────────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildPaymentsSection(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoSection(String title, List<Widget> children, {Widget? action}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.fireRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                if (action != null) action,
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _showMarkServicedDialog(BuildContext context, ClientService svc) {
    int intervalDays = 90;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Serviced',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Set the next service interval:',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ...([30, 60, 90, 180, 365].map((days) {
                final label = days == 365 ? '1 Year' : '$days Days';
                return InkWell(
                  onTap: () => setState(() => intervalDays = days),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: intervalDays == days ? AppTheme.fireRed : AppTheme.textMuted,
                              width: 2,
                            ),
                            color: intervalDays == days ? AppTheme.fireRed : Colors.transparent,
                          ),
                          child: intervalDays == days
                              ? const Icon(Icons.check, size: 12, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                );
              })),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              await svc.markServiced(client, intervalDays);
              
              if (context.mounted) {
                final recordSvc = context.read<ServiceRecordService>();
                await recordSvc.addRecord(
                  clientId: client.id,
                  clientName: client.name,
                  serviceDate: DateTime.now(),
                  serviceType: client.serviceType,
                  description: 'Routine Maintenance - Marked as Serviced',
                );
              }
              
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ClientService svc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Client',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Remove ${client.name} permanently? This cannot be undone.',
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
              await svc.deleteClient(client);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, Client client) {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Payment', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Amount Paid (KSH)',
                labelStyle: TextStyle(color: AppTheme.textMuted),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.borderColor)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.fireRed)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: TextStyle(color: AppTheme.textMuted),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.borderColor)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.fireRed)),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white),
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text) ?? 0;
              if (amt <= 0) return;
              
              final pSvc = context.read<PaymentService>();
              await pSvc.addPayment(
                clientId: client.id,
                clientName: client.name,
                amount: 0,
                amountPaid: amt,
                date: DateTime.now(),
                description: 'Direct Payment',
                notes: notesCtrl.text,
              );
              
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Payment'),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceHistorySection(BuildContext context) {
    final records = context.watch<ServiceRecordService>().getRecordsForClient(client.id);
    final df = DateFormat('dd MMM yyyy');
    
    return _infoSection('Service History', [
      if (records.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No service records yet. Completing a service will add one here.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ),
      ...records.take(3).map((r) => ListTile(
        title: Text(r.serviceType, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
        subtitle: Text('${df.format(r.serviceDate)}\n${r.description}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        isThreeLine: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        trailing: const Icon(Icons.description_outlined, color: AppTheme.textMuted, size: 20),
        onTap: () {
          // Open record details (future)
        },
      )),
    ], action: const Icon(Icons.history, color: AppTheme.textMuted, size: 16));
  }

  Widget _buildPaymentsSection(BuildContext context) {
    final payments = context.watch<PaymentService>().getPaymentsForClient(client.id);
    final totalOwed = context.watch<PaymentService>().getTotalOwedByClient(client.id);
    final df = DateFormat('dd MMM yyyy');
    
    return _infoSection('Payments', [
      if (payments.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No payments recorded.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ),
      ...payments.take(3).map((p) => ListTile(
        title: Text(p.description.isEmpty ? 'Payment/Invoice' : p.description, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
        subtitle: Text(df.format(p.date), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        trailing: Text(
          p.amount == 0 ? '-KSH ${p.amountPaid.toStringAsFixed(2)}' : 'KSH ${p.amount.toStringAsFixed(2)}', 
          style: TextStyle(
            color: p.amount == 0 ? AppTheme.successGreen : AppTheme.textPrimary, 
            fontWeight: FontWeight.w600
          )
        ),
      )),
    ], action: IconButton(
      icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.fireRed, size: 20),
      constraints: const BoxConstraints(),
      padding: EdgeInsets.zero,
      onPressed: () => _showAddPaymentDialog(context, client),
    ));
  }
}
