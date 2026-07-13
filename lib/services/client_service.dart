import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import 'notification_service.dart';

class ClientService extends ChangeNotifier {
  static const String _boxName = 'clients';
  late Box<Client> _box;
  final _uuid = const Uuid();
  int _notifIdCounter = 1000;

  List<Client> get clients => _box.values.toList()
    ..sort((a, b) => a.nextServiceDate.compareTo(b.nextServiceDate));

  List<Client> get activeClients =>
      clients.where((c) => c.isActive).toList();

  List<Client> get overdueClients =>
      activeClients.where((c) => c.status == ServiceStatus.overdue).toList();

  List<Client> get urgentClients =>
      activeClients.where((c) => c.status == ServiceStatus.urgent).toList();

  List<Client> get upcomingClients =>
      activeClients.where((c) => c.status == ServiceStatus.upcoming).toList();

  /// Initialise Hive box
  Future<void> init() async {
    _box = await Hive.openBox<Client>(_boxName);
    // Seed the counter above the highest existing notif ID
    if (_box.isNotEmpty) {
      _notifIdCounter = _box.values
              .map((c) => c.notificationId)
              .reduce((a, b) => a > b ? a : b) +
          1;
    }
    notifyListeners();
  }

  /// Add a new client and schedule its notification
  Future<void> addClient({
    required String name,
    required String phone,
    required String address,
    required String serviceType,
    required DateTime lastServiceDate,
    required DateTime nextServiceDate,
    String notes = '',
  }) async {
    final id = _uuid.v4();
    final notifId = _notifIdCounter++;

    final client = Client(
      id: id,
      name: name,
      phone: phone,
      address: address,
      serviceType: serviceType,
      lastServiceDate: lastServiceDate,
      nextServiceDate: nextServiceDate,
      notes: notes,
      notificationId: notifId,
    );

    await _box.put(id, client);

    // Schedule notifications: 7 days before, 1 day before, and on the day
    await NotificationService.scheduleServiceNotifications(client);

    notifyListeners();
  }

  /// Update an existing client
  Future<void> updateClient(Client client) async {
    // Cancel old notifications before rescheduling
    await NotificationService.cancelClientNotifications(client);
    await _box.put(client.id, client);
    await NotificationService.scheduleServiceNotifications(client);
    notifyListeners();
  }

  /// Soft-delete (deactivate) a client
  Future<void> deactivateClient(Client client) async {
    await NotificationService.cancelClientNotifications(client);
    final updated = client.copyWith(isActive: false);
    await _box.put(client.id, updated);
    notifyListeners();
  }

  /// Permanently delete a client
  Future<void> deleteClient(Client client) async {
    await NotificationService.cancelClientNotifications(client);
    await _box.delete(client.id);
    notifyListeners();
  }

  /// Mark a service as completed — shifts dates forward by one service interval
  Future<void> markServiced(Client client, int intervalDays) async {
    final now = DateTime.now();
    final updated = client.copyWith(
      lastServiceDate: now,
      nextServiceDate: now.add(Duration(days: intervalDays)),
    );
    await updateClient(updated);
  }

  /// Search clients by name or address
  List<Client> search(String query) {
    final q = query.toLowerCase();
    return activeClients.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q) ||
          c.serviceType.toLowerCase().contains(q);
    }).toList();
  }

  /// Get clients with next service on a specific day
  List<Client> clientsOnDay(DateTime day) {
    return activeClients.where((c) {
      return c.nextServiceDate.year == day.year &&
          c.nextServiceDate.month == day.month &&
          c.nextServiceDate.day == day.day;
    }).toList();
  }
}
