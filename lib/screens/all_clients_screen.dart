import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/client_service.dart';
import '../theme/app_theme.dart';
import '../widgets/client_card.dart';
import '../widgets/background_glow.dart';
import '../widgets/fade_in.dart';
import 'client_detail_screen.dart';

import '../widgets/glass_card.dart';

class AllClientsScreen extends StatefulWidget {
  const AllClientsScreen({super.key});

  @override
  State<AllClientsScreen> createState() => _AllClientsScreenState();
}

class _AllClientsScreenState extends State<AllClientsScreen> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('All Clients', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BackgroundGlow(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: GlassCard(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search all clients...',
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
            ),
            Expanded(
              child: Consumer<ClientService>(
                builder: (context, svc, _) {
                  final allClients = _searchQuery.isEmpty 
                      ? svc.activeClients 
                      : svc.search(_searchQuery);

                  if (allClients.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty ? 'No clients found' : 'No matches found',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: allClients.length,
                    itemBuilder: (context, i) {
                      final client = allClients[i];
                      return FadeIn(
                        delayMs: i * 50 > 500 ? 500 : i * 50,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ClientCard(
                            client: client,
                            onDelete: () => svc.deleteClient(client),
                            onMarkServiced: () {
                              int interval = client.nextServiceDate.difference(client.lastServiceDate).inDays;
                              if (interval <= 0) interval = 180;
                              svc.markServiced(client, interval);
                            },
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClientDetailScreen(client: client),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
