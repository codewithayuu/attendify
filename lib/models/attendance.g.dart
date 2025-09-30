// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceAdapter extends TypeAdapter<Attendance> {
  @override
  final int typeId = 4;

  @override
  Attendance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Attendance(
      id: fields[0] as String,
      subjectId: fields[1] as String,
      date: fields[2] as DateTime,
      present: fields[3] as bool,
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Attendance obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.present)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
