import 'package:hive/hive.dart';

part 'client.g.dart';

@HiveType(typeId: 0)
class Client extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String phone;

  @HiveField(3)
  late String address;

  @HiveField(4)
  late String serviceType; // e.g. "Fire Extinguisher", "Suppression System", etc.

  @HiveField(5)
  late DateTime lastServiceDate;

  @HiveField(6)
  late DateTime nextServiceDate;

  @HiveField(7)
  late String notes;

  @HiveField(8)
  late bool isActive;

  @HiveField(9)
  late int notificationId; // Unique int ID for scheduling notifications

  Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.serviceType,
    required this.lastServiceDate,
    required this.nextServiceDate,
    this.notes = '',
    this.isActive = true,
    required this.notificationId,
  });

  /// Days until the next service
  int get daysUntilService {
    final now = DateTime.now();
    return nextServiceDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// Status based on how soon the service is
  ServiceStatus get status {
    final days = daysUntilService;
    if (days < 0) return ServiceStatus.overdue;
    if (days <= 7) return ServiceStatus.urgent;
    if (days <= 30) return ServiceStatus.upcoming;
    return ServiceStatus.ok;
  }

  Client copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? serviceType,
    DateTime? lastServiceDate,
    DateTime? nextServiceDate,
    String? notes,
    bool? isActive,
    int? notificationId,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      serviceType: serviceType ?? this.serviceType,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      nextServiceDate: nextServiceDate ?? this.nextServiceDate,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      notificationId: notificationId ?? this.notificationId,
    );
  }
}

enum ServiceStatus { ok, upcoming, urgent, overdue }

extension ServiceStatusExt on ServiceStatus {
  String get label {
    switch (this) {
      case ServiceStatus.ok:
        return 'OK';
      case ServiceStatus.upcoming:
        return 'Due Soon';
      case ServiceStatus.urgent:
        return 'Urgent';
      case ServiceStatus.overdue:
        return 'Overdue';
    }
  }
}
