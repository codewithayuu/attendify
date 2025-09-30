// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubjectAdapter extends TypeAdapter<Subject> {
  @override
  final int typeId = 0;

  @override
  Subject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subject(
      id: fields[0] as String?,
      name: fields[1] as String,
      totalClasses: fields[2] as int,
      attendedClasses: fields[3] as int,
      description: fields[4] as String?,
      createdAt: fields[5] as DateTime?,
      updatedAt: fields[6] as DateTime?,
      colorHex: fields[7] as String?,
      weekdays: (fields[8] as List).cast<int>(),
      startTime: fields[9] as String,
      endTime: fields[10] as String,
      semesterStart: fields[11] as DateTime?,
      semesterEnd: fields[12] as DateTime?,
      attendanceRecords: (fields[13] as List).cast<Attendance>(),
    );
  }

  @override
  void write(BinaryWriter writer, Subject obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.totalClasses)
      ..writeByte(3)
      ..write(obj.attendedClasses)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.colorHex)
      ..writeByte(8)
      ..write(obj.weekdays)
      ..writeByte(9)
      ..write(obj.startTime)
      ..writeByte(10)
      ..write(obj.endTime)
      ..writeByte(11)
      ..write(obj.semesterStart)
      ..writeByte(12)
      ..write(obj.semesterEnd)
      ..writeByte(13)
      ..write(obj.attendanceRecords);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
