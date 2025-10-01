import 'package:flutter/material.dart';

class ScheduleService {
  /// Generates a list of DateTime occurrences for a given schedule
  ///
  /// [start] - Start date of the schedule period
  /// [end] - End date of the schedule period
  /// [weekdays] - List of weekdays (1 = Monday, 7 = Sunday)
  /// [startTime] - Time of day for the occurrences
  ///
  /// Returns a list of DateTime objects representing all occurrences
  static List<DateTime> generateOccurrences({
    required DateTime start,
    required DateTime end,
    required List<int> weekdays,
    required TimeOfDay startTime,
  }) {
    final List<DateTime> dates = [];
    DateTime cursor = DateTime(start.year, start.month, start.day);

    while (!cursor.isAfter(end)) {
      if (weekdays.contains(cursor.weekday)) {
        final dt = DateTime(cursor.year, cursor.month, cursor.day,
            startTime.hour, startTime.minute);
        dates.add(dt);
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return dates;
  }

  /// Generates occurrences for a specific subject
  ///
  /// [subject] - Subject with schedule information
  /// [start] - Start date for generation
  /// [end] - End date for generation
  static List<DateTime> generateSubjectOccurrences({
    required dynamic subject, // Subject model
    required DateTime start,
    required DateTime end,
  }) {
    // Parse start time from subject
    final timeParts = subject.startTime.split(':');
    final startTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    return generateOccurrences(
      start: start,
      end: end,
      weekdays: subject.weekdays,
      startTime: startTime,
    );
  }

  /// Gets the next occurrence after a given date
  ///
  /// [weekdays] - List of weekdays
  /// [startTime] - Time of day
  /// [after] - Date to find next occurrence after
  static DateTime? getNextOccurrence({
    required List<int> weekdays,
    required TimeOfDay startTime,
    required DateTime after,
  }) {
    final end = after.add(const Duration(days: 14)); // Look ahead 2 weeks
    final occurrences = generateOccurrences(
      start: after.add(const Duration(days: 1)),
      end: end,
      weekdays: weekdays,
      startTime: startTime,
    );

    return occurrences.isNotEmpty ? occurrences.first : null;
  }

  /// Gets occurrences for the current week
  ///
  /// [weekdays] - List of weekdays
  /// [startTime] - Time of day
  static List<DateTime> getCurrentWeekOccurrences({
    required List<int> weekdays,
    required TimeOfDay startTime,
  }) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return generateOccurrences(
      start: startOfWeek,
      end: endOfWeek,
      weekdays: weekdays,
      startTime: startTime,
    );
  }

  /// Gets occurrences for the current month
  ///
  /// [weekdays] - List of weekdays
  /// [startTime] - Time of day
  static List<DateTime> getCurrentMonthOccurrences({
    required List<int> weekdays,
    required TimeOfDay startTime,
  }) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return generateOccurrences(
      start: startOfMonth,
      end: endOfMonth,
      weekdays: weekdays,
      startTime: startTime,
    );
  }

  // Additional methods expected by other parts of the codebase

  /// Get subjects that have class today
  static List<dynamic> getSubjectsWithClassToday(List<dynamic> subjects) {
    final today = DateTime.now();
    return subjects.where((subject) {
      return subject.weekdays.contains(today.weekday);
    }).toList();
  }

  /// Get attendance for today for a subject
  static dynamic getAttendanceForToday(dynamic subject) {
    // This would need to be implemented based on your attendance model
    // For now, return null as placeholder
    return null;
  }

  /// Check if subject has attendance for today
  static bool hasAttendanceForToday(dynamic subject) {
    // This would need to be implemented based on your attendance model
    // For now, return false as placeholder
    return false;
  }

  /// Get weekly attendance summary for a subject
  static Map<String, int> getWeeklyAttendanceSummary(dynamic subject) {
    // This would need to be implemented based on your attendance model
    // For now, return empty map as placeholder
    return {
      'total': 0,
      'present': 0,
      'absent': 0,
    };
  }

  /// Generate class dates for a subject
  static List<DateTime> generateClassDates(
    dynamic subject,
    DateTime start,
    DateTime end,
  ) {
    // Parse start time from subject
    final timeParts = subject.startTime.split(':');
    final startTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    return generateOccurrences(
      start: start,
      end: end,
      weekdays: subject.weekdays,
      startTime: startTime,
    );
  }

  /// Validate schedule for a subject
  static List<String> validateSchedule({
    required List<int> weekdays,
    required String startTime,
    required String endTime,
    DateTime? semesterStart,
    DateTime? semesterEnd,
  }) {
    final errors = <String>[];

    if (weekdays.isEmpty) {
      errors.add('At least one weekday must be selected');
    }

    if (startTime.isEmpty) {
      errors.add('Start time is required');
    }

    if (endTime.isEmpty) {
      errors.add('End time is required');
    }

    // Add more validation logic as needed

    return errors;
  }

  /// Generate attendance records for a subject
  static List<dynamic> generateAttendanceRecords(
    String subjectId,
    List<DateTime> classDates,
  ) {
    // Import the AttendanceRecord model
    // This will be implemented after we import the model
    return classDates.map((date) {
      // Create AttendanceRecord with Unmarked status
      // This is a placeholder - will be properly implemented
      return {
        'id': '${subjectId}_${date.millisecondsSinceEpoch}',
        'subjectId': subjectId,
        'date': date,
        'status': 'Unmarked',
      };
    }).toList();
  }

  /// Get attendance stats for a subject
  static Map<String, dynamic> getAttendanceStats(dynamic subject) {
    // This would calculate attendance statistics
    // For now, return basic stats as placeholder
    return {
      'totalClasses': subject.totalClasses ?? 0,
      'attendedClasses': subject.attendedClasses ?? 0,
      'attendancePercentage': subject.attendancePercentage ?? 0.0,
    };
  }

  /// Mark attendance for today
  static dynamic markAttendanceForToday(dynamic subject, bool present) {
    // This would mark attendance for today
    // Implementation would depend on your attendance model
    return null;
  }

  /// Get upcoming classes for the next specified number of days
  ///
  /// [subjects] - List of subjects to check for upcoming classes
  /// [daysAhead] - Number of days to look ahead (default: 7)
  /// Returns a list of upcoming class information
  static List<Map<String, dynamic>> getUpcomingClasses(
    List<dynamic> subjects, {
    int daysAhead = 7,
  }) {
    final List<Map<String, dynamic>> upcomingClasses = [];
    final now = DateTime.now();
    final endDate = now.add(Duration(days: daysAhead));

    for (final subject in subjects) {
      if (subject.weekdays.isEmpty) continue;

      // Parse start time from subject
      final timeParts = subject.startTime.split(':');
      final startTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );

      // Generate occurrences for the next daysAhead days
      final classDates = generateOccurrences(
        start: now,
        end: endDate,
        weekdays: subject.weekdays,
        startTime: startTime,
      );

      // Add each upcoming class to the list
      for (final classDate in classDates) {
        upcomingClasses.add({
          'subject': subject,
          'subjectId': subject.id,
          'subjectName': subject.name,
          'date': classDate,
          'time': startTime,
          'dayName': _getDayName(classDate.weekday),
          'isToday': _isToday(classDate),
          'isPast': classDate.isBefore(now),
        });
      }
    }

    // Sort by date and time
    upcomingClasses.sort((a, b) {
      final dateA = a['date'] as DateTime;
      final dateB = b['date'] as DateTime;
      return dateA.compareTo(dateB);
    });

    return upcomingClasses;
  }

  /// Helper method to get day name from weekday number
  static String _getDayName(int weekday) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return dayNames[weekday - 1];
  }

  /// Helper method to check if date is today
  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
