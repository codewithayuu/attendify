import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/subject.dart';
import '../models/attendance.dart';

class ScheduleService {
  // Generate all class dates for a subject based on schedule
  static List<DateTime> generateClassDates(
    DateTime semesterStart,
    DateTime semesterEnd,
    List<int> weekdays,
  ) {
    List<DateTime> classDates = [];
    DateTime current = semesterStart;
    
    while (current.isBefore(semesterEnd) || current.isAtSameMomentAs(semesterEnd)) {
      if (weekdays.contains(current.weekday)) {
        classDates.add(DateTime(current.year, current.month, current.day));
      }
      current = current.add(const Duration(days: 1));
    }
    
    return classDates;
  }

  // Generate attendance records for all class dates
  static List<Attendance> generateAttendanceRecords(
    String subjectId,
    List<DateTime> classDates,
  ) {
    return classDates.map((date) {
      return Attendance(
        id: const Uuid().v4(),
        subjectId: subjectId,
        date: date,
        present: false, // Default to absent, user will mark as present
      );
    }).toList();
  }

  // Get subjects that have class today
  static List<Subject> getSubjectsWithClassToday(List<Subject> subjects) {
    final today = DateTime.now();
    return subjects.where((subject) {
      return subject.hasClassOnWeekday(today.weekday) &&
             subject.isActive;
    }).toList();
  }

  // Get subjects that have class on a specific date
  static List<Subject> getSubjectsWithClassOnDate(List<Subject> subjects, DateTime date) {
    return subjects.where((subject) {
      return subject.hasClassOnWeekday(date.weekday) &&
             date.isAfter(subject.semesterStart) &&
             date.isBefore(subject.semesterEnd.add(const Duration(days: 1)));
    }).toList();
  }

  // Check if a subject has attendance marked for today
  static bool hasAttendanceForToday(Subject subject) {
    final today = DateTime.now();
    return subject.attendanceRecords.any((attendance) => 
        attendance.isForDate(today));
  }

  // Get attendance for today
  static Attendance? getAttendanceForToday(Subject subject) {
    final today = DateTime.now();
    try {
      return subject.attendanceRecords.firstWhere((attendance) => 
          attendance.isForDate(today));
    } catch (e) {
      return null;
    }
  }

  // Mark attendance for today
  static Attendance markAttendanceForToday(Subject subject, bool present) {
    final today = DateTime.now();
    final existingAttendance = getAttendanceForToday(subject);
    
    if (existingAttendance != null) {
      // Update existing attendance
      return existingAttendance.copyWith(
        present: present,
        updatedAt: DateTime.now(),
      );
    } else {
      // Create new attendance record
      return Attendance(
        id: const Uuid().v4(),
        subjectId: subject.id,
        date: today,
        present: present,
      );
    }
  }

  // Get upcoming classes for a subject (next 7 days)
  static List<DateTime> getUpcomingClasses(Subject subject, {int days = 7}) {
    final now = DateTime.now();
    List<DateTime> upcomingClasses = [];
    DateTime current = now;
    
    for (int i = 0; i < days; i++) {
      if (subject.hasClassOnWeekday(current.weekday) &&
          current.isAfter(subject.semesterStart) &&
          current.isBefore(subject.semesterEnd.add(const Duration(days: 1)))) {
        upcomingClasses.add(DateTime(current.year, current.month, current.day));
      }
      current = current.add(const Duration(days: 1));
    }
    
    return upcomingClasses;
  }

  // Get attendance statistics for a subject
  static Map<String, dynamic> getAttendanceStats(Subject subject) {
    final totalClasses = subject.attendanceRecords.length;
    final attendedClasses = subject.attendanceRecords.where((a) => a.present).length;
    final missedClasses = totalClasses - attendedClasses;
    final percentage = totalClasses > 0 ? (attendedClasses / totalClasses) * 100 : 0.0;
    
    return {
      'totalClasses': totalClasses,
      'attendedClasses': attendedClasses,
      'missedClasses': missedClasses,
      'percentage': percentage,
      'isAboveThreshold': percentage >= 75.0,
    };
  }

  // Get weekly attendance summary
  static Map<String, int> getWeeklyAttendanceSummary(Subject subject) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    Map<String, int> weeklyStats = {
      'present': 0,
      'absent': 0,
      'total': 0,
    };
    
    for (final attendance in subject.attendanceRecords) {
      if (attendance.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          attendance.date.isBefore(weekEnd.add(const Duration(days: 1)))) {
        weeklyStats['total'] = weeklyStats['total']! + 1;
        if (attendance.present) {
          weeklyStats['present'] = weeklyStats['present']! + 1;
        } else {
          weeklyStats['absent'] = weeklyStats['absent']! + 1;
        }
      }
    }
    
    return weeklyStats;
  }

  // Validate schedule data
  static List<String> validateSchedule({
    required List<int> weekdays,
    required String startTime,
    required String endTime,
    required DateTime semesterStart,
    required DateTime semesterEnd,
  }) {
    List<String> errors = [];
    
    if (weekdays.isEmpty) {
      errors.add('Please select at least one day of the week');
    }
    
    if (semesterStart.isAfter(semesterEnd)) {
      errors.add('Semester start date must be before end date');
    }
    
    if (semesterStart.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      errors.add('Semester start date cannot be in the past');
    }
    
    // Validate time format
    try {
      final start = _parseTime(startTime);
      final end = _parseTime(endTime);
      
      if (start.isAfter(end)) {
        errors.add('Start time must be before end time');
      }
    } catch (e) {
      errors.add('Invalid time format. Use HH:MM format');
    }
    
    return errors;
  }

  // Helper method to parse time string
  static TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 2) {
      throw const FormatException('Invalid time format');
    }
    
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw const FormatException('Invalid time values');
    }
    
    return TimeOfDay(hour: hour, minute: minute);
  }
}
