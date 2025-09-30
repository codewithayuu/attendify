import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'attendance_record.g.dart';

@HiveType(typeId: 1)
class AttendanceRecord extends HiveObject {
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
    String? id,
    required this.subjectId,
    required this.date,
    required this.status,
    DateTime? createdAt,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

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

@HiveType(typeId: 2)
enum AttendanceStatus {
  @HiveField(0)
  present,
  
  @HiveField(1)
  absent,
  
  @HiveField(2)
  late,
  
  @HiveField(3)
  excused,
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  String get emoji {
    switch (this) {
      case AttendanceStatus.present:
        return '✅';
      case AttendanceStatus.absent:
        return '❌';
      case AttendanceStatus.late:
        return '⏰';
      case AttendanceStatus.excused:
        return '📝';
    }
  }

  bool get countsAsPresent {
    switch (this) {
      case AttendanceStatus.present:
      case AttendanceStatus.late:
        return true;
      case AttendanceStatus.absent:
      case AttendanceStatus.excused:
        return false;
    }
  }

  String get colorHex {
    switch (this) {
      case AttendanceStatus.present:
        return '#4CAF50'; // Green
      case AttendanceStatus.absent:
        return '#F44336'; // Red
      case AttendanceStatus.late:
        return '#FF9800'; // Orange
      case AttendanceStatus.excused:
        return '#2196F3'; // Blue
    }
  }
}

