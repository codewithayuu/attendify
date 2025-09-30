import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'attendance.dart';

part 'subject.g.dart';

@HiveType(typeId: 0)
class Subject extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int totalClasses;

  @HiveField(3)
  int attendedClasses;

  @HiveField(4)
  String? description;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  String? colorHex; // For UI theming

  // Schedule fields
  @HiveField(8)
  List<int> weekdays; // [1, 3, 5] for Mon, Wed, Fri

  @HiveField(9)
  String startTime; // "09:00" format

  @HiveField(10)
  String endTime; // "10:30" format

  @HiveField(11)
  DateTime semesterStart;

  @HiveField(12)
  DateTime semesterEnd;

  @HiveField(13)
  List<Attendance> attendanceRecords;

  Subject({
    String? id,
    required this.name,
    this.totalClasses = 0,
    this.attendedClasses = 0,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.colorHex,
    this.weekdays = const [],
    this.startTime = '09:00',
    this.endTime = '10:00',
    DateTime? semesterStart,
    DateTime? semesterEnd,
    this.attendanceRecords = const [],
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        semesterStart = semesterStart ?? DateTime.now(),
        semesterEnd = semesterEnd ?? DateTime.now().add(const Duration(days: 90));

  // Calculate attendance percentage based on attendance records
  double get attendancePercentage {
    if (attendanceRecords.isEmpty) return 0.0;
    final presentCount = attendanceRecords.where((a) => a.present).length;
    return (presentCount / attendanceRecords.length) * 100;
  }

  // Get total classes from attendance records
  int get totalClassesFromRecords => attendanceRecords.length;

  // Get attended classes from attendance records
  int get attendedClassesFromRecords => attendanceRecords.where((a) => a.present).length;

  // Check if subject has class on a specific weekday
  bool hasClassOnWeekday(int weekday) => weekdays.contains(weekday);

  // Check if subject has class today
  bool get hasClassToday => hasClassOnWeekday(DateTime.now().weekday);

  // Check if subject is active (within semester period)
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(semesterStart) && now.isBefore(semesterEnd.add(const Duration(days: 1)));
  }

  // Check if subject has class today and is active
  bool get hasClassTodayAndActive => hasClassToday && isActive;

  // Get next class date
  DateTime? get nextClassDate {
    final now = DateTime.now();
    DateTime current = now;
    
    // Look for next class within the next 7 days
    for (int i = 0; i < 7; i++) {
      if (hasClassOnWeekday(current.weekday) && 
          current.isAfter(semesterStart) && 
          current.isBefore(semesterEnd.add(const Duration(days: 1)))) {
        return current;
      }
      current = current.add(const Duration(days: 1));
    }
    return null;
  }

  // Get formatted time range
  String get timeRange => '$startTime - $endTime';

  // Get formatted weekdays
  String get weekdaysString {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays.map((day) => dayNames[day - 1]).join(', ');
  }

  // Check if attendance is below threshold (75%)
  bool get isBelowThreshold => attendancePercentage < 75.0;

  // Get attendance status color
  String get statusColor {
    if (attendancePercentage >= 75.0) return '#4CAF50'; // Green
    if (attendancePercentage >= 60.0) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }

  // Copy with method for updates
  Subject copyWith({
    String? name,
    int? totalClasses,
    int? attendedClasses,
    String? description,
    DateTime? updatedAt,
    String? colorHex,
  }) {
    return Subject(
      id: id,
      name: name ?? this.name,
      totalClasses: totalClasses ?? this.totalClasses,
      attendedClasses: attendedClasses ?? this.attendedClasses,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      colorHex: colorHex ?? this.colorHex,
    );
  }

  // Mark attendance
  Subject markAttendance({required bool isPresent}) {
    return copyWith(
      totalClasses: totalClasses + 1,
      attendedClasses: isPresent ? attendedClasses + 1 : attendedClasses,
    );
  }

  // Undo last attendance
  Subject undoLastAttendance({required bool wasPresent}) {
    if (totalClasses > 0) {
      return copyWith(
        totalClasses: totalClasses - 1,
        attendedClasses: wasPresent ? attendedClasses - 1 : attendedClasses,
      );
    }
    return this;
  }

  @override
  String toString() {
    return 'Subject(id: $id, name: $name, totalClasses: $totalClasses, attendedClasses: $attendedClasses, percentage: ${attendancePercentage.toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subject && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
