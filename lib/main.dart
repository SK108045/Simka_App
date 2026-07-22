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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(ClientAdapter());
  Hive.registerAdapter(ServiceRecordAdapter());
  Hive.registerAdapter(PaymentAdapter());
  Hive.registerAdapter(InvoiceAdapter());
  Hive.registerAdapter(QuotationAdapter());

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

  // Populate dummy data (boxes are already open from init calls above)
  try {
    await DummyDataService.populateIfNeeded();
  } catch (e) {
    debugPrint('DummyDataService error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: clientService),
        ChangeNotifierProvider.value(value: serviceRecordService),
        ChangeNotifierProvider.value(value: paymentService),
        ChangeNotifierProvider.value(value: invoiceService),
        ChangeNotifierProvider.value(value: quotationService),
      ],
      child: const SimkaApp(),
    ),
  );

  // Initialize notifications AFTER the UI has rendered
  // so the permission dialog doesn't block the splash screen
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await NotificationService.init();
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  });
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

  bool _isNavOpen = false;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard', activeIcon: Icons.dashboard_rounded),
    _NavItem(icon: Icons.calendar_month_outlined, label: 'Calendar', activeIcon: Icons.calendar_month_rounded),
    _NavItem(icon: Icons.receipt_long_outlined, label: 'Invoices', activeIcon: Icons.receipt_long_rounded),
    _NavItem(icon: Icons.request_quote_outlined, label: 'Quotations', activeIcon: Icons.request_quote_rounded),
    _NavItem(icon: Icons.bar_chart_outlined, label: 'Reports', activeIcon: Icons.bar_chart_rounded),
  ];

  final List<Widget> _screens = const [
    HomeScreen(),
    CalendarScreen(),
    InvoicesScreen(),
    QuotationsScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          Row(
            children: [
              // Spacer that pushes content when nav is open
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _isNavOpen ? 72 : 0,
              ),
              // Main Content
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
          // Sidebar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _isNavOpen ? 0 : -72,
            top: 0,
            bottom: 0,
            child: Container(
              width: 72,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceDark,
                border: Border(
                  right: BorderSide(color: AppTheme.borderColor, width: 1),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40), // Top padding for mobile
                  // Logo
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.fireRed, AppTheme.emberOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_fire_department_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 32),
                  // Nav Items
                  ...List.generate(_navItems.length, (index) {
                    final item = _navItems[index];
                    final isActive = _currentIndex == index;
                    return _SideNavButton(
                      icon: isActive ? item.activeIcon : item.icon,
                      label: item.label,
                      isActive: isActive,
                      onTap: () {
                        setState(() {
                          _currentIndex = index;
                          _isNavOpen = false; // Auto close on selection
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          // Toggle Handle
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _isNavOpen ? 72 : 0,
            top: MediaQuery.of(context).size.height / 2 - 30,
            child: GestureDetector(
              onTap: () => setState(() => _isNavOpen = !_isNavOpen),
              child: Container(
                width: 24,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(2, 0),
                    )
                  ],
                ),
                child: Center(
                  child: Icon(
                    _isNavOpen ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    color: AppTheme.fireRed,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _SideNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SideNavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: label,
        preferBelow: false,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.fireRed.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(color: AppTheme.fireRed.withValues(alpha: 0.4), width: 1)
                  : null,
            ),
            child: Icon(
              icon,
              size: 22,
              color: isActive ? AppTheme.fireRed : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
