import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/client.dart';
import 'models/service_record.dart';
import 'models/payment.dart';
import 'models/invoice.dart';
import 'models/quotation.dart';
import 'services/client_service.dart';
import 'services/service_record_service.dart';
import 'services/payment_service.dart';
import 'services/invoice_service.dart';
import 'services/quotation_service.dart';
import 'services/notification_service.dart';
import 'services/dummy_data_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/quotations_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/add_client_screen.dart';
import 'screens/create_invoice_screen.dart';
import 'screens/create_quotation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}

class AppServices {
  final ClientService clientService;
  final ServiceRecordService serviceRecordService;
  final PaymentService paymentService;
  final InvoiceService invoiceService;
  final QuotationService quotationService;

  AppServices({
    required this.clientService,
    required this.serviceRecordService,
    required this.paymentService,
    required this.invoiceService,
    required this.quotationService,
  });
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<AppServices> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initApp();
  }

  Future<AppServices> _initApp() async {
    try {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ClientAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ServiceRecordAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(PaymentAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(InvoiceAdapter());
      if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(QuotationAdapter());

      final clientService = ClientService();
      await clientService.init();

      final serviceRecordService = ServiceRecordService();
      await serviceRecordService.init();

      final paymentService = PaymentService();
      await paymentService.init();

      final invoiceService = InvoiceService();
      await invoiceService.init();

      final quotationService = QuotationService();
      await quotationService.init();

      try {
        await DummyDataService.populateIfNeeded();
      } catch (e) {
        debugPrint('DummyData error: $e');
      }

      try {
        await NotificationService.init();
      } catch (e) {
        debugPrint('Notification error: $e');
      }

      return AppServices(
        clientService: clientService,
        serviceRecordService: serviceRecordService,
        paymentService: paymentService,
        invoiceService: invoiceService,
        quotationService: quotationService,
      );
    } catch (e, stack) {
      debugPrint('Fatal init error: $e\n$stack');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppServices>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final services = snapshot.data!;
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: services.clientService),
              ChangeNotifierProvider.value(value: services.serviceRecordService),
              ChangeNotifierProvider.value(value: services.paymentService),
              ChangeNotifierProvider.value(value: services.invoiceService),
              ChangeNotifierProvider.value(value: services.quotationService),
            ],
            child: const SimkaApp(),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: AppTheme.darkBg,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.fireRed, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Initialization Error',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _initFuture = _initApp();
                          });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fireRed),
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: Scaffold(
            backgroundColor: AppTheme.darkBg,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.fireRed, AppTheme.emberOrange],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 42),
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: AppTheme.fireRed),
                  const SizedBox(height: 16),
                  const Text(
                    'SIMKA Fire Services',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SimkaApp extends StatelessWidget {
  const SimkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIMKA Fire Services',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CalendarScreen(),
    InvoicesScreen(),
    ReportsScreen(),
  ];

  void _showQuickActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppTheme.borderColor, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.fireRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_fire_department_rounded, color: AppTheme.fireRed, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Create new entries instantly',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _QuickActionTile(
              icon: Icons.person_add_rounded,
              color: AppTheme.fireRed,
              title: 'Add New Client',
              subtitle: 'Register client & fire equipment details',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddClientScreen()));
              },
            ),
            const SizedBox(height: 12),
            _QuickActionTile(
              icon: Icons.receipt_long_rounded,
              color: AppTheme.emberOrange,
              title: 'Create Invoice',
              subtitle: 'Issue a new service or equipment invoice',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()));
              },
            ),
            const SizedBox(height: 12),
            _QuickActionTile(
              icon: Icons.request_quote_rounded,
              color: AppTheme.warningAmber,
              title: 'Create Quotation',
              subtitle: 'Generate a quote for fire services',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateQuotationScreen()));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withValues(alpha: 0.95),
          border: const Border(
            top: BorderSide(color: AppTheme.borderColor, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Dashboard Tab
            _BottomNavItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
              label: 'Dashboard',
              isActive: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            // Calendar Tab
            _BottomNavItem(
              icon: Icons.calendar_month_outlined,
              activeIcon: Icons.calendar_month_rounded,
              label: 'Calendar',
              isActive: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            // Centered Fire Action Button
            GestureDetector(
              onTap: () => _showQuickActionSheet(context),
              child: Container(
                width: 52,
                height: 52,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.fireRed, AppTheme.emberOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.fireRed.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            // Invoices Tab
            _BottomNavItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              label: 'Invoices',
              isActive: _currentIndex == 2,
              onTap: () => setState(() => _currentIndex = 2),
            ),
            // Reports Tab
            _BottomNavItem(
              icon: Icons.bar_chart_outlined,
              activeIcon: Icons.bar_chart_rounded,
              label: 'Reports',
              isActive: _currentIndex == 3,
              onTap: () => setState(() => _currentIndex = 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.fireRed : AppTheme.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.textMuted,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
