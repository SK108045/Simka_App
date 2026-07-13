import 'package:hive/hive.dart';

part 'service_record.g.dart';

@HiveType(typeId: 1)
class ServiceRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String clientId;

  @HiveField(2)
  late String clientName;

  @HiveField(3)
  late DateTime serviceDate;

  @HiveField(4)
  late String serviceType;

  @HiveField(5)
  late String description;

  @HiveField(6)
  late String technicianName;

  @HiveField(7)
  late String notes;

  ServiceRecord({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.serviceDate,
    required this.serviceType,
    this.description = '',
    this.technicianName = '',
    this.notes = '',
  });
}
