// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bottle.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BottleAdapter extends TypeAdapter<Bottle> {
  @override
  final int typeId = 0;

  @override
  Bottle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Bottle(
      id: fields[0] as String,
      barcode: fields[1] as String,
      name: fields[2] as String,
      brand: fields[3] as String,
      type: fields[4] as BottleType,
      volume: fields[5] as double,
      depositAmount: fields[6] as double,
      scannedAt: fields[7] as DateTime,
      imageUrl: fields[8] as String?,
      storeId: fields[9] as String?,
      isReturned: fields[10] as bool,
      returnedAt: fields[11] as DateTime?,
      notes: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Bottle obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.barcode)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.brand)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.volume)
      ..writeByte(6)
      ..write(obj.depositAmount)
      ..writeByte(7)
      ..write(obj.scannedAt)
      ..writeByte(8)
      ..write(obj.imageUrl)
      ..writeByte(9)
      ..write(obj.storeId)
      ..writeByte(10)
      ..write(obj.isReturned)
      ..writeByte(11)
      ..write(obj.returnedAt)
      ..writeByte(12)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BottleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BottleTypeAdapter extends TypeAdapter<BottleType> {
  @override
  final int typeId = 1;

  @override
  BottleType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BottleType.plastic;
      case 1:
        return BottleType.glass;
      case 2:
        return BottleType.can;
      case 3:
        return BottleType.crate;
      default:
        return BottleType.plastic;
    }
  }

  @override
  void write(BinaryWriter writer, BottleType obj) {
    switch (obj) {
      case BottleType.plastic:
        writer.writeByte(0);
        break;
      case BottleType.glass:
        writer.writeByte(1);
        break;
      case BottleType.can:
        writer.writeByte(2);
        break;
      case BottleType.crate:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BottleTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
