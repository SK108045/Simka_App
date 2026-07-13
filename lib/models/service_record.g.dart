// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_record.dart';

class ServiceRecordAdapter extends TypeAdapter<ServiceRecord> {
  @override
  final int typeId = 1;

  @override
  ServiceRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceRecord(
      id: fields[0] as String,
      clientId: fields[1] as String,
      clientName: fields[2] as String,
      serviceDate: fields[3] as DateTime,
      serviceType: fields[4] as String,
      description: fields[5] as String,
      technicianName: fields[6] as String,
      notes: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ServiceRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.clientId)
      ..writeByte(2)
      ..write(obj.clientName)
      ..writeByte(3)
      ..write(obj.serviceDate)
      ..writeByte(4)
      ..write(obj.serviceType)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.technicianName)
      ..writeByte(7)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
