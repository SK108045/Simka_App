import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import '../services/quotation_service.dart';
import '../services/client_service.dart';
import '../services/service_record_service.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import '../widgets/background_glow.dart';
import '../widgets/glass_card.dart';
import '../widgets/fade_in.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceSvc = context.watch<InvoiceService>();
    final clientSvc = context.watch<ClientService>();
    final quoteSvc = context.watch<QuotationService>();
    final recordSvc = context.watch<ServiceRecordService>();
    final paymentSvc = context.watch<PaymentService>();

    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reports & Analytics',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              currentMonth,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
      body: BackgroundGlow(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeIn(delayMs: 0, child: _buildSummaryCards(invoiceSvc, clientSvc, paymentSvc)),
            const SizedBox(height: 24),
            FadeIn(delayMs: 100, child: _buildRevenueChart(paymentSvc)),
            const SizedBox(height: 24),
            FadeIn(delayMs: 200, child: _buildQuickStats(invoiceSvc, quoteSvc, recordSvc)),
            const SizedBox(height: 24),
            FadeIn(delayMs: 300, child: _buildRecentInvoices(invoiceSvc)),
            const SizedBox(height: 40),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSummaryCards(InvoiceService invoiceSvc, ClientService clientSvc, PaymentService paymentSvc) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          title: 'Total Revenue',
          value: 'KSH ${NumberFormat('#,##0').format(paymentSvc.totalRevenue)}',
          icon: Icons.account_balance_wallet_rounded,
          color: AppTheme.successGreen,
        ),
        _StatCard(
          title: 'Total Invoiced',
          value: 'KSH ${NumberFormat('#,##0').format(invoiceSvc.totalInvoiced)}',
          icon: Icons.receipt_long_rounded,
          color: AppTheme.emberOrange,
        ),
        _StatCard(
          title: 'Outstanding',
          value: 'KSH ${NumberFormat('#,##0').format(invoiceSvc.totalOutstanding)}',
          icon: Icons.warning_rounded,
          color: AppTheme.dangerRed,
        ),
        _StatCard(
          title: 'Total Clients',
          value: '${clientSvc.clients.length}',
          icon: Icons.people_rounded,
          color: const Color(0xFF5C6BC0), // Indigo
        ),
      ],
    );
  }

  Widget _buildRevenueChart(PaymentService paymentSvc) {
    final revenueData = paymentSvc.getMonthlyRevenue();
    final keys = revenueData.keys.toList();
    final values = revenueData.values.toList();
    final maxVal = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final hasData = maxVal > 0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Revenue (KSH)',
            style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: !hasData
                ? const Center(
                    child: Text('No revenue data yet',
                        style: TextStyle(color: AppTheme.textMuted)))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxVal * 1.2,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= keys.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  keys[index],
                                  style: const TextStyle(
                                      color: AppTheme.textMuted, fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(
                                NumberFormat.compact().format(value),
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppTheme.borderColor.withValues(alpha: 0.5),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(
                        keys.length,
                        (index) => BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: values[index],
                              color: AppTheme.fireRed,
                              width: 16,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    InvoiceService invoiceSvc,
    QuotationService quoteSvc,
    ServiceRecordService recordSvc,
  ) {
    final now = DateTime.now();
    final thisMonthInvoices = invoiceSvc.allInvoices
        .where((i) => i.issueDate.year == now.year && i.issueDate.month == now.month)
        .length;
    final thisMonthQuotes = quoteSvc.allQuotations
        .where((q) => q.issueDate.year == now.year && q.issueDate.month == now.month)
        .length;
    final thisMonthClients = clientSvc.activeClients
        .where((c) => 
            (c.nextServiceDate.year == now.year && c.nextServiceDate.month == now.month) ||
            (c.lastServiceDate.year == now.year && c.lastServiceDate.month == now.month))
        .length;

    return Row(
      children: [
        _QuickStatBox(title: 'Invoices\nThis Month', value: '$thisMonthInvoices'),
        const SizedBox(width: 12),
        _QuickStatBox(title: 'Quotes\nThis Month', value: '$thisMonthQuotes'),
        const SizedBox(width: 12),
        _QuickStatBox(title: 'Clients\nThis Month', value: '$thisMonthClients'),
      ],
    );
  }

  Widget _buildRecentInvoices(InvoiceService invoiceSvc) {
    final recent = invoiceSvc.allInvoices.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Invoices',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (recent.isEmpty)
          const Text('No recent invoices',
              style: TextStyle(color: AppTheme.textMuted))
        else
          GlassCard(
            child: Column(
              children: recent.map((inv) {
                final isLast = inv == recent.last;
                return Column(
                  children: [
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(inv.clientName,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(inv.invoiceNumber,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('KSH ${NumberFormat('#,##0').format(inv.total)}',
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          _StatusBadge(status: inv.paymentStatus),
                        ],
                      ),
                    ),
                    if (!isLast)
                      const Divider(height: 1, color: AppTheme.borderColor),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickStatBox extends StatelessWidget {
  final String title;
  final String value;

  const _QuickStatBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11, height: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final InvoiceStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case InvoiceStatus.paid:
        color = AppTheme.successGreen;
        break;
      case InvoiceStatus.overdue:
        color = AppTheme.dangerRed;
        break;
      case InvoiceStatus.sent:
        color = AppTheme.emberOrange;
        break;
      case InvoiceStatus.draft:
        color = AppTheme.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
