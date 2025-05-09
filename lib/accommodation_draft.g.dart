// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accommodation_draft.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccommodationDraftAdapter extends TypeAdapter<AccommodationDraft> {
  @override
  final int typeId = 0;

  @override
  AccommodationDraft read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AccommodationDraft(
      remoteId: fields[0] as int?,
      name: fields[1] as String,
      address: fields[2] as String,
      guests: fields[3] as int,
      price: fields[4] as double,
      iban: fields[5] as String,
      description: fields[6] as String,
      images: (fields[7] as List).cast<Uint8List>(),
    )..createdAt = fields[8] as DateTime;
  }

  @override
  void write(BinaryWriter writer, AccommodationDraft obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.remoteId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.guests)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj.iban)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.images)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccommodationDraftAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
