import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/service_record.dart';

class ServiceRecordService extends ChangeNotifier {
  static const String _boxName = 'service_records';
  late Box<ServiceRecord> _box;
  final _uuid = const Uuid();

  List<ServiceRecord> get allRecords => _box.values.toList()
    ..sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

  Future<void> init() async {
    _box = await Hive.openBox<ServiceRecord>(_boxName);
    notifyListeners();
  }

  List<ServiceRecord> getRecordsForClient(String clientId) {
    return _box.values.where((r) => r.clientId == clientId).toList()
      ..sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
  }

  Future<void> addRecord({
    required String clientId,
    required String clientName,
    required DateTime serviceDate,
    required String serviceType,
    String description = '',
    String technicianName = '',
    String notes = '',
  }) async {
    final id = _uuid.v4();
    final record = ServiceRecord(
      id: id,
      clientId: clientId,
      clientName: clientName,
      serviceDate: serviceDate,
      serviceType: serviceType,
      description: description,
      technicianName: technicianName,
      notes: notes,
    );
    await _box.put(id, record);
    notifyListeners();
  }

  Future<void> updateRecord(ServiceRecord record) async {
    await _box.put(record.id, record);
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    await _box.delete(id);
    notifyListeners();
  }
}
