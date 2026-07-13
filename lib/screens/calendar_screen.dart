import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/client.dart';
import '../services/client_service.dart';
import '../theme/app_theme.dart';
import 'client_detail_screen.dart';
import '../widgets/background_glow.dart';
import '../widgets/glass_card.dart';
import '../widgets/fade_in.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundGlow(
        child: SafeArea(
          child: Consumer<ClientService>(
          builder: (context, svc, _) {
            final selectedClients = _selectedDay != null
                ? svc.clientsOnDay(_selectedDay!)
                : svc.clientsOnDay(_focusedDay);

            return Column(
              children: [
                // ── Header ──────────────────────────────────────────
                FadeIn(
                  delayMs: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          color: AppTheme.fireRed, size: 26),
                      const SizedBox(width: 10),
                      const Text(
                        'Service Calendar',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                ),

                // ── Calendar ─────────────────────────────────────────
                FadeIn(
                  delayMs: 100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GlassCard(
                      child: TableCalendar(
                    firstDay: DateTime(2024),
                    lastDay: DateTime(2030),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) =>
                        isSameDay(_selectedDay, day),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    eventLoader: (day) => svc.clientsOnDay(day),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle:
                          const TextStyle(color: AppTheme.textSecondary),
                      weekendTextStyle:
                          const TextStyle(color: AppTheme.textMuted),
                      todayTextStyle: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                      selectedTextStyle: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                      outsideTextStyle:
                          const TextStyle(color: AppTheme.textMuted),
                      todayDecoration: const BoxDecoration(
                        color: AppTheme.deepRed,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppTheme.fireRed,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppTheme.emberOrange,
                        shape: BoxShape.circle,
                      ),
                      markerSize: 5,
                      markersMaxCount: 3,
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      leftChevronIcon:
                          Icon(Icons.chevron_left, color: AppTheme.textSecondary),
                      rightChevronIcon: Icon(Icons.chevron_right,
                          color: AppTheme.textSecondary),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle:
                          TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      weekendStyle:
                          TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ),
                ),
                ),
                ),

                const SizedBox(height: 16),

                // ── Selected Day Label ───────────────────────────────
                FadeIn(
                  delayMs: 200,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                    children: [
                      Text(
                        DateFormat('EEEE, dd MMMM').format(
                            _selectedDay ?? _focusedDay),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (selectedClients.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.fireRed.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${selectedClients.length} service${selectedClients.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: AppTheme.fireRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ),

                const SizedBox(height: 8),

                // ── Clients for selected day ───────────────────────
                Expanded(
                  child: FadeIn(
                    delayMs: 300,
                    child: selectedClients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_available_rounded,
                                  color: AppTheme.textMuted, size: 40),
                              const SizedBox(height: 8),
                              const Text(
                                'No services scheduled',
                                style: TextStyle(color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          itemCount: selectedClients.length,
                          itemBuilder: (ctx, i) {
                            final c = selectedClients[i];
                            return _calendarClientTile(context, c);
                          },
                        ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }

  Widget _calendarClientTile(BuildContext context, Client client) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ClientDetailScreen(client: client)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.fireRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  client.name[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.fireRed,
                      fontWeight: FontWeight.w800,
                      fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  Text(client.serviceType,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 13)),
                  Text(client.address,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textMuted, size: 20),
          ],
        ),
        ),
      ),
    );
  }
}
