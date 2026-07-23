import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../services/client_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/client_card.dart';
import '../widgets/background_glow.dart';
import '../widgets/glass_card.dart';
import '../widgets/fade_in.dart';
import 'client_detail_screen.dart';
import 'all_clients_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }



  void _openClientDetail(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: BackgroundGlow(
        child: SafeArea(
          child: Consumer<ClientService>(
              builder: (context, svc, _) {
                final allClients = _searchQuery.isEmpty
                    ? svc.activeClients
                    : svc.search(_searchQuery);
                
                final displayClients = _searchQuery.isEmpty && allClients.length > 3
                    ? allClients.take(3).toList()
                    : allClients;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Header
                    SliverToBoxAdapter(
                      child: FadeIn(
                        delayMs: 0,
                        child: _buildHeader(),
                      ),
                    ),

                    // ── Hero Stats
                    SliverToBoxAdapter(
                      child: FadeIn(
                        delayMs: 100,
                        child: _buildStatsArea(svc),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // ── Glass Search Bar
                    SliverToBoxAdapter(
                      child: FadeIn(
                        delayMs: 200,
                        child: _buildSearchBar(),
                      ),
                    ),

                    // ── Section Title
                    SliverToBoxAdapter(
                      child: FadeIn(
                        delayMs: 300,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _searchQuery.isEmpty ? 'Your Roster' : 'Results',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.fireRed.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.fireRed.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  '${allClients.length}',
                                  style: const TextStyle(
                                    color: AppTheme.fireRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Client List
                    if (displayClients.isEmpty)
                      SliverToBoxAdapter(
                        child: _FadeIn(delayMs: 400, child: _buildEmptyState()),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _FadeIn(
                              delayMs: 400 + (i * 50),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ClientCard(
                                  client: displayClients[i],
                                  onTap: () => _openClientDetail(displayClients[i]),
                                ),
                              ),
                            ),
                            childCount: displayClients.length,
                          ),
                        ),
                      ),

                    if (_searchQuery.isEmpty && allClients.length > 3)
                      SliverToBoxAdapter(
                        child: FadeIn(
                          delayMs: 600,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AllClientsScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                ),
                                child: Text(
                                  'View All ${allClients.length} Clients',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 120),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting = 'Good Evening,';
    if (hour < 12) {
      greeting = 'Good Morning,';
    } else if (hour < 17) {
      greeting = 'Good Afternoon,';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(
                  DateFormat('EEEE, d MMMM').format(DateTime.now()).toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                greeting,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFFFFD5D5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'Hello Eunice.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  await NotificationService.showTestNotification();
                },
                icon: const Icon(Icons.notifications_active_rounded, color: AppTheme.fireRed),
              ),
              const SizedBox(width: 8),
              _AnimatedAvatar(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsArea(ClientService svc) {
    final activeCount = svc.activeClients.length;
    final overdueCount = svc.overdueClients.length;
    final urgentCount = svc.urgentClients.length;
    final upcomingCount = svc.upcomingClients.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Big Hero Counter (Cardless, sitting directly on background)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$activeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -3,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACTIVE CLIENTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.successGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'System Operational',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Minimalist Metric Strip (Cardless, hairline separated)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                // Overdue Metric
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'OVERDUE',
                            style: TextStyle(
                              color: overdueCount > 0 ? AppTheme.fireRed : AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (overdueCount > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.fireRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$overdueCount',
                        style: TextStyle(
                          color: overdueCount > 0 ? AppTheme.fireRed : Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical Hairline Divider
                Container(
                  height: 32,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(width: 16),

                // Urgent Metric
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'URGENT',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$urgentCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical Hairline Divider
                Container(
                  height: 32,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(width: 16),

                // Upcoming Metric
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'UPCOMING',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$upcomingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: GlassCard(
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search your roster...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.6), size: 24),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 52, minHeight: 52),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.cancel_rounded, color: Colors.white.withValues(alpha: 0.4), size: 22),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Icon(
              Icons.blur_on_rounded,
              color: AppTheme.fireRed.withValues(alpha: 0.8),
              size: 56,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _searchQuery.isEmpty ? 'Your Roster is Empty' : 'No matches found',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty
                ? 'Ready to start? Tap the button below to add your first client and get things rolling.'
                : 'Try adjusting your search terms to find what you are looking for.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Stunning Micro-Animations ───────────────────────────────────────────────

class _AnimatedAvatar extends StatefulWidget {
  @override
  State<_AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<_AnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) {
        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppTheme.fireRed, AppTheme.emberOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.fireRed.withValues(alpha: 0.3 + (_ctrl.value * 0.2)),
                blurRadius: 15 + (_ctrl.value * 10),
                spreadRadius: _ctrl.value * 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.local_fire_department_rounded,
              color: Colors.white, size: 32),
        );
      },
    );
  }
}

class _FadeIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _FadeIn({required this.child, required this.delayMs});

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
