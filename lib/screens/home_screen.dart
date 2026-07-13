import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../services/client_service.dart';
import '../theme/app_theme.dart';
import '../widgets/client_card.dart';
import '../widgets/background_glow.dart';
import '../widgets/glass_card.dart';
import '../widgets/fade_in.dart';
import 'add_client_screen.dart';
import 'client_detail_screen.dart';

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

  void _openAddClient() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddClientScreen()),
    );
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
                    if (allClients.isEmpty)
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
                                  client: allClients[i],
                                  onTap: () => _openClientDetail(allClients[i]),
                                ),
                              ),
                            ),
                            childCount: allClients.length,
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
      floatingActionButton: FadeIn(
        delayMs: 500,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.fireRed.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _openAddClient,
            backgroundColor: AppTheme.fireRed,
            elevation: 0,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            label: const Text(
              'Add Client',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              const Text(
                'Good Morning,',
                style: TextStyle(
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
                  'Simka Team.',
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
          _AnimatedAvatar(),
        ],
      ),
    );
  }

  Widget _buildStatsArea(ClientService svc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // ── Glassmorphic Hero Stat ──────────────────────────────
          GlassCard(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.fireRed, AppTheme.emberOrange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.fireRed.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: const Icon(Icons.business_center_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Clients',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      svc.activeClients.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Horizontal Glass Stats ──────────────────────────────
          Row(
            children: [
              _buildSmallGlassStat(
                'Overdue',
                svc.overdueClients.length,
                AppTheme.dangerRed,
                Icons.error_outline_rounded,
              ),
              const SizedBox(width: 16),
              _buildSmallGlassStat(
                'Urgent',
                svc.urgentClients.length,
                AppTheme.emberOrange,
                Icons.warning_amber_rounded,
              ),
              const SizedBox(width: 16),
              _buildSmallGlassStat(
                'Upcoming',
                svc.upcomingClients.length,
                AppTheme.warningAmber,
                Icons.schedule_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallGlassStat(String label, int value, Color color, IconData icon) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                shadows: [
                  Shadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                  )
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
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
