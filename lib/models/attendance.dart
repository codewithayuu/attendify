import 'package:hive/hive.dart';

part 'attendance.g.dart';

@HiveType(typeId: 4)
class Attendance extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subjectId;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final bool present;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  Attendance({
    required this.id,
    required this.subjectId,
    required this.date,
    required this.present,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Copy with method for updates
  Attendance copyWith({
    String? id,
    String? subjectId,
    DateTime? date,
    bool? present,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      present: present ?? this.present,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if attendance is for today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  // Check if attendance is for a specific date
  bool isForDate(DateTime targetDate) {
    return date.year == targetDate.year &&
           date.month == targetDate.month &&
           date.day == targetDate.day;
  }

  // Get formatted date string
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get day of week
  String get dayOfWeek {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  @override
  String toString() {
    return 'Attendance(id: $id, subjectId: $subjectId, date: $date, present: $present)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attendance &&
           other.id == id &&
           other.subjectId == subjectId &&
           other.date == date &&
           other.present == present;
  }

  @override
  int get hashCode {
    return id.hashCode ^
           subjectId.hashCode ^
           date.hashCode ^
           present.hashCode;
  }
}

