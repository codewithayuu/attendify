// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 3;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      isDarkMode: fields[0] as bool,
      enableNotifications: fields[1] as bool,
      notificationTime: fields[2] as String,
      enableFirebaseSync: fields[3] as bool,
      attendanceThreshold: fields[4] as double,
      showPercentageOnCards: fields[5] as bool,
      defaultSubjectColor: fields[6] as String,
      enableHapticFeedback: fields[7] as bool,
      languageCode: fields[8] as String,
      lastSyncTime: fields[9] as DateTime?,
      showDefaultSubjects: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.isDarkMode)
      ..writeByte(1)
      ..write(obj.enableNotifications)
      ..writeByte(2)
      ..write(obj.notificationTime)
      ..writeByte(3)
      ..write(obj.enableFirebaseSync)
      ..writeByte(4)
      ..write(obj.attendanceThreshold)
      ..writeByte(5)
      ..write(obj.showPercentageOnCards)
      ..writeByte(6)
      ..write(obj.defaultSubjectColor)
      ..writeByte(7)
      ..write(obj.enableHapticFeedback)
      ..writeByte(8)
      ..write(obj.languageCode)
      ..writeByte(9)
      ..write(obj.lastSyncTime)
      ..writeByte(10)
      ..write(obj.showDefaultSubjects);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
