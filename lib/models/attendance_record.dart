import 'package:hive/hive.dart';

part 'attendance_record.g.dart';

@HiveType(typeId: 4) // pick an unused typeId
class AttendanceRecord {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String subjectId;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final AttendanceStatus status;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  String? notes;

  AttendanceRecord({
    required this.id,
    required this.subjectId,
    required this.date,
    required this.status,
    DateTime? createdAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  // Copy with method for updates
  AttendanceRecord copyWith({
    AttendanceStatus? status,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id,
      subjectId: subjectId,
      date: date,
      status: status ?? this.status,
      createdAt: createdAt,
      notes: notes ?? this.notes,
    );
  }

  // Check if record is for today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if record is for this week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // Check if record is for this month
  bool get isThisMonth {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  @override
  String toString() {
    return 'AttendanceRecord(id: $id, subjectId: $subjectId, date: $date, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 5)
enum AttendanceStatus {
  @HiveField(0)
  Present,
  @HiveField(1)
  Absent,
  @HiveField(2)
  Late,
  @HiveField(3)
  Excused,
  @HiveField(4)
  Unmarked,
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get displayName {
    switch (this) {
      case AttendanceStatus.Present:
        return 'Present';
      case AttendanceStatus.Absent:
        return 'Absent';
      case AttendanceStatus.Late:
        return 'Late';
      case AttendanceStatus.Excused:
        return 'Excused';
      case AttendanceStatus.Unmarked:
        return 'Unmarked';
    }
  }

  String get emoji {
    switch (this) {
      case AttendanceStatus.Present:
        return '✅';
      case AttendanceStatus.Absent:
        return '❌';
      case AttendanceStatus.Late:
        return '⏰';
      case AttendanceStatus.Excused:
        return '📝';
      case AttendanceStatus.Unmarked:
        return '⭕';
    }
  }

  bool get countsAsPresent {
    switch (this) {
      case AttendanceStatus.Present:
      case AttendanceStatus.Late:
        return true;
      case AttendanceStatus.Absent:
      case AttendanceStatus.Excused:
      case AttendanceStatus.Unmarked:
        return false;
    }
  }
}
