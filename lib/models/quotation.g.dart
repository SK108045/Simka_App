// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quotation.dart';

class QuotationAdapter extends TypeAdapter<Quotation> {
  @override
  final int typeId = 4;

  @override
  Quotation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Quotation(
      id: fields[0] as String,
      quoteNumber: fields[1] as String,
      clientId: fields[2] as String,
      clientName: fields[3] as String,
      clientPhone: fields[4] as String? ?? '',
      clientAddress: fields[5] as String? ?? '',
      issueDate: fields[6] as DateTime,
      validUntil: fields[7] as DateTime,
      itemsJson: fields[8] as String? ?? '[]',
      taxRate: fields[9] as double? ?? 0.16,
      status: fields[10] as String? ?? 'draft',
      notes: fields[11] as String? ?? '',
      currency: fields[12] as String? ?? 'KES',
    );
  }

  @override
  void write(BinaryWriter writer, Quotation obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.quoteNumber)
      ..writeByte(2)
      ..write(obj.clientId)
      ..writeByte(3)
      ..write(obj.clientName)
      ..writeByte(4)
      ..write(obj.clientPhone)
      ..writeByte(5)
      ..write(obj.clientAddress)
      ..writeByte(6)
      ..write(obj.issueDate)
      ..writeByte(7)
      ..write(obj.validUntil)
      ..writeByte(8)
      ..write(obj.itemsJson)
      ..writeByte(9)
      ..write(obj.taxRate)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.currency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuotationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
