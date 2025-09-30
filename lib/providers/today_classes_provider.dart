import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject.dart';
import '../models/attendance.dart';
import '../services/schedule_service.dart';
import 'subject_provider.dart';

// Today's classes provider - shows subjects that have class today
final todayClassesProvider = Provider<List<Subject>>((ref) {
  final subjects = ref.watch(subjectListProvider);
  return ScheduleService.getSubjectsWithClassToday(subjects);
});

// Today's attendance provider - shows attendance records for today
final todayAttendanceProvider = Provider<List<Attendance>>((ref) {
  final subjects = ref.watch(subjectListProvider);

  List<Attendance> todayAttendance = [];
  for (final subject in subjects) {
    final attendance = ScheduleService.getAttendanceForToday(subject);
    if (attendance != null) {
      todayAttendance.add(attendance);
    }
  }

  return todayAttendance;
});

// Subjects with unmarked attendance for today
final unmarkedAttendanceProvider = Provider<List<Subject>>((ref) {
  final todaySubjects = ref.watch(todayClassesProvider);

  return todaySubjects.where((subject) {
    return !ScheduleService.hasAttendanceForToday(subject);
  }).toList();
});

// Attendance statistics for today
final todayAttendanceStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final todaySubjects = ref.watch(todayClassesProvider);
  final todayAttendance = ref.watch(todayAttendanceProvider);

  final totalClasses = todaySubjects.length;
  final markedAttendance = todayAttendance.length;
  final unmarkedAttendance = totalClasses - markedAttendance;

  final presentCount = todayAttendance.where((a) => a.present).length;
  final absentCount = todayAttendance.where((a) => !a.present).length;

  return {
    'totalClasses': totalClasses,
    'markedAttendance': markedAttendance,
    'unmarkedAttendance': unmarkedAttendance,
    'presentCount': presentCount,
    'absentCount': absentCount,
    'attendancePercentage':
        totalClasses > 0 ? (presentCount / totalClasses) * 100 : 0.0,
  };
});

// Next class provider - shows the next upcoming class
final nextClassProvider = Provider<Subject?>((ref) {
  final subjects = ref.watch(subjectListProvider);

  Subject? nextClass;
  DateTime? nextClassDate;

  for (final subject in subjects) {
    final nextDate = subject.nextClassDate;
    if (nextDate != null) {
      if (nextClassDate == null || nextDate.isBefore(nextClassDate)) {
        nextClass = subject;
        nextClassDate = nextDate;
      }
    }
  }

  return nextClass;
});

// Weekly attendance summary provider
final weeklyAttendanceProvider = Provider<Map<String, dynamic>>((ref) {
  final subjects = ref.watch(subjectListProvider);

  Map<String, int> weeklyStats = {
    'present': 0,
    'absent': 0,
    'total': 0,
  };

  for (final subject in subjects) {
    final weeklyStatsForSubject =
        ScheduleService.getWeeklyAttendanceSummary(subject);
    weeklyStats['present'] =
        weeklyStats['present']! + weeklyStatsForSubject['present']!;
    weeklyStats['absent'] =
        weeklyStats['absent']! + weeklyStatsForSubject['absent']!;
    weeklyStats['total'] =
        weeklyStats['total']! + weeklyStatsForSubject['total']!;
  }

  return {
    'present': weeklyStats['present']!,
    'absent': weeklyStats['absent']!,
    'total': weeklyStats['total']!,
    'percentage': weeklyStats['total']! > 0
        ? (weeklyStats['present']! / weeklyStats['total']!) * 100
        : 0.0,
  };
});

// Attendance marking provider
final attendanceMarkingProvider =
    StateNotifierProvider<AttendanceMarkingNotifier, Map<String, bool>>((ref) {
  return AttendanceMarkingNotifier();
});

class AttendanceMarkingNotifier extends StateNotifier<Map<String, bool>> {
  AttendanceMarkingNotifier() : super({});

  // Mark attendance for a subject today
  void markAttendance(String subjectId, bool present) {
    state = {
      ...state,
      subjectId: present,
    };
  }

  // Get attendance status for a subject
  bool? getAttendanceStatus(String subjectId) {
    return state[subjectId];
  }

  // Clear all markings
  void clearMarkings() {
    state = {};
  }

  // Check if all today's classes are marked
  bool areAllMarked(List<Subject> todaySubjects) {
    if (todaySubjects.isEmpty) return true;

    for (final subject in todaySubjects) {
      if (!state.containsKey(subject.id)) {
        return false;
      }
    }
    return true;
  }
}
