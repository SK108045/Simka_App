import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/client.dart';
import '../theme/app_theme.dart';

class ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;
  final VoidCallback? onMarkServiced;
  final VoidCallback? onDelete;

  const ClientCard({
    super.key,
    required this.client,
    required this.onTap,
    this.onMarkServiced,
    this.onDelete,
  });

  Color _statusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.past:
        return AppTheme.dangerRed;
      case ServiceStatus.urgent:
        return AppTheme.emberOrange;
      case ServiceStatus.upcoming:
        return AppTheme.warningAmber;
      case ServiceStatus.ok:
        return AppTheme.successGreen;
    }
  }

  IconData _statusIcon(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.past:
        return Icons.error_rounded;
      case ServiceStatus.urgent:
        return Icons.warning_rounded;
      case ServiceStatus.upcoming:
        return Icons.schedule_rounded;
      case ServiceStatus.ok:
        return Icons.check_circle_rounded;
    }
  }

  String _daysLabel(int days) {
    if (days < 0) return '${days.abs()} days past';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return 'In $days days';
  }

  @override
  Widget build(BuildContext context) {
    final status = client.status;
    final statusColor = _statusColor(status);
    final days = client.daysUntilService;
    final df = DateFormat('dd MMM yyyy');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: status == ServiceStatus.ok
                ? AppTheme.borderColor
                : statusColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Status accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        client.name.isNotEmpty
                            ? client.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Main info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.fire_extinguisher_rounded,
                              size: 13,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              client.serviceType,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                client.address,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Next service date row
                        Row(
                          children: [
                            Icon(
                              _statusIcon(status),
                              size: 15,
                              color: statusColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _daysLabel(days),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '· ${df.format(client.nextServiceDate)}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.label,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (onMarkServiced != null) ...[
                        const SizedBox(height: 12),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.check_circle_outline, size: 22, color: AppTheme.successGreen),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppTheme.surfaceDark,
                                title: const Text('Mark as Serviced', style: TextStyle(color: AppTheme.textPrimary)),
                                content: const Text('Has this client been serviced? This will update their next service date.', style: TextStyle(color: AppTheme.textSecondary)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      onMarkServiced!();
                                    },
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      if (onDelete != null) ...[
                        const SizedBox(height: 16),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline, size: 22, color: AppTheme.dangerRed),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppTheme.surfaceDark,
                                title: const Text('Delete Client', style: TextStyle(color: AppTheme.textPrimary)),
                                content: const Text('Are you sure you want to delete this client?', style: TextStyle(color: AppTheme.textSecondary)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      onDelete!();
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
