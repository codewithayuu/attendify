import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/attendance_record.dart';
import '../services/hive_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import 'subject_provider.dart';

// Attendance records provider
final attendanceRecordsProvider =
    StateNotifierProvider<AttendanceRecordsNotifier, List<AttendanceRecord>>(
        (ref) {
  return AttendanceRecordsNotifier(ref);
});

class AttendanceRecordsNotifier extends StateNotifier<List<AttendanceRecord>> {
  final Ref ref;

  AttendanceRecordsNotifier(this.ref) : super([]) {
    loadAttendanceRecords();
  }

  // Load attendance records from local database
  Future<void> loadAttendanceRecords() async {
    final records = HiveService.getAllAttendanceRecords();
    state = records;
  }

  // Add attendance record
  Future<void> addAttendanceRecord(AttendanceRecord record) async {
    await HiveService.addAttendanceRecord(record);
    state = [...state, record];

    // Update subject statistics
    final subjectNotifier = ref.read(subjectListProvider.notifier);
    await subjectNotifier.markAttendance(
        record.subjectId, record.status.countsAsPresent);

    // Send notification
    final subject = ref.read(subjectListProvider).firstWhere(
          (s) => s.id == record.subjectId,
          orElse: () => throw StateError('Subject not found'),
        );
    await NotificationService.sendAttendanceMarkedConfirmation(
        subject, record.status);

    // Sync to cloud if enabled
    final settings = HiveService.getSettings();
    if (settings.enableFirebaseSync && FirebaseService.isSignedIn) {
      await FirebaseService.syncAttendanceRecordsToCloud(state);
    }
  }

  // Update attendance record
  Future<void> updateAttendanceRecord(AttendanceRecord record) async {
    await HiveService.updateAttendanceRecord(record);
    state = state.map((r) => r.id == record.id ? record : r).toList();

    // Sync to cloud if enabled
    final settings = HiveService.getSettings();
    if (settings.enableFirebaseSync && FirebaseService.isSignedIn) {
      await FirebaseService.syncAttendanceRecordsToCloud(state);
    }
  }

  // Delete attendance record
  Future<void> deleteAttendanceRecord(String recordId) async {
    final record = state.firstWhere((r) => r.id == recordId);
    await HiveService.deleteAttendanceRecord(recordId);
    state = state.where((r) => r.id != recordId).toList();

    // Update subject statistics
    final subjectNotifier = ref.read(subjectListProvider.notifier);
    await subjectNotifier.undoLastAttendance(
        record.subjectId, record.status.countsAsPresent);

    // Sync to cloud if enabled
    final settings = HiveService.getSettings();
    if (settings.enableFirebaseSync && FirebaseService.isSignedIn) {
      await FirebaseService.syncAttendanceRecordsToCloud(state);
    }
  }

  // Mark attendance for today
  Future<void> markTodayAttendance(
      String subjectId, AttendanceStatus status) async {
    // Check if already marked for today
    if (HiveService.isAttendanceMarkedForToday(subjectId)) {
      // Toggle logic: same status => revert to Unmarked; otherwise set to new status
      final existingRecord = HiveService.getTodayAttendanceRecord(subjectId);
      if (existingRecord != null) {
        AttendanceStatus nextStatus = status;
        if (existingRecord.status == status) {
          nextStatus = AttendanceStatus.Unmarked;
        }
        final updatedRecord = existingRecord.copyWith(status: nextStatus);
        await updateAttendanceRecord(updatedRecord);

        // Keep overall counters in sync with toggle
        if (nextStatus == AttendanceStatus.Unmarked) {
          final subjectNotifier = ref.read(subjectListProvider.notifier);
          await subjectNotifier.undoLastAttendance(
              subjectId, existingRecord.status.countsAsPresent);
        } else if (existingRecord.status.countsAsPresent !=
            nextStatus.countsAsPresent) {
          // Adjust subject counters if present/absent parity changed
          if (nextStatus.countsAsPresent) {
            await ref
                .read(subjectListProvider.notifier)
                .adjustAttendedOnly(subjectId, 1);
          } else {
            await ref
                .read(subjectListProvider.notifier)
                .adjustAttendedOnly(subjectId, -1);
          }
        }
      }
    } else {
      // Create new record
      final record = AttendanceRecord(
        id: const Uuid().v4(),
        subjectId: subjectId,
        date: DateTime.now(),
        status: status,
      );
      await addAttendanceRecord(record);
    }
  }

  // Get attendance records for a specific subject
  List<AttendanceRecord> getRecordsForSubject(String subjectId) {
    return state.where((r) => r.subjectId == subjectId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Get attendance records for a specific date
  List<AttendanceRecord> getRecordsForDate(DateTime date) {
    return state
        .where((r) =>
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day)
        .toList();
  }

  // Get attendance records for date range
  List<AttendanceRecord> getRecordsForDateRange(
      DateTime startDate, DateTime endDate) {
    return state
        .where((r) =>
            r.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            r.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Sync with cloud
  Future<void> syncWithCloud() async {
    if (!FirebaseService.isSignedIn) return;

    try {
      final cloudRecords =
          await FirebaseService.syncAttendanceRecordsFromCloud();
      if (cloudRecords.isNotEmpty) {
        // Clear local records and replace with cloud data
        await HiveService.clearAllData();
        for (final record in cloudRecords) {
          await HiveService.addAttendanceRecord(record);
        }
        state = cloudRecords;
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }
}

// Today's attendance provider
final todayAttendanceProvider = Provider<List<AttendanceRecord>>((ref) {
  final records = ref.watch(attendanceRecordsProvider);
  final today = DateTime.now();

  return records
      .where((r) =>
          r.date.year == today.year &&
          r.date.month == today.month &&
          r.date.day == today.day)
      .toList();
});

// Weekly attendance provider
final weeklyAttendanceProvider = Provider<List<AttendanceRecord>>((ref) {
  final records = ref.watch(attendanceRecordsProvider);
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));

  return records
      .where((r) =>
          r.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          r.date.isBefore(endOfWeek.add(const Duration(days: 1))))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

// Monthly attendance provider
final monthlyAttendanceProvider = Provider<List<AttendanceRecord>>((ref) {
  final records = ref.watch(attendanceRecordsProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);

  return records
      .where((r) =>
          r.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          r.date.isBefore(endOfMonth.add(const Duration(days: 1))))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

// Attendance statistics provider
final attendanceStatsProvider =
    Provider.family<Map<String, dynamic>, String>((ref, subjectId) {
  final records = ref.watch(attendanceRecordsProvider);
  final subjectRecords =
      records.where((r) => r.subjectId == subjectId).toList();

  final stats = <String, int>{
    'total': subjectRecords.length,
    'present': 0,
    'absent': 0,
    'late': 0,
    'excused': 0,
  };

  for (final record in subjectRecords) {
    switch (record.status) {
      case AttendanceStatus.Present:
        stats['present'] = stats['present']! + 1;
        break;
      case AttendanceStatus.Absent:
        stats['absent'] = stats['absent']! + 1;
        break;
      case AttendanceStatus.Late:
        stats['late'] = stats['late']! + 1;
        break;
      case AttendanceStatus.Excused:
        stats['excused'] = stats['excused']! + 1;
        break;
      case AttendanceStatus.Unmarked:
        // Unmarked records don't count towards any category
        break;
    }
  }

  return stats;
});

// Weekly attendance statistics provider
final weeklyStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final records = ref.watch(weeklyAttendanceProvider);
  final subjects = ref.watch(subjectListProvider);

  final stats = <String, dynamic>{
    'totalRecords': records.length,
    'subjects': <String, Map<String, int>>{},
  };

  for (final subject in subjects) {
    final subjectRecords =
        records.where((r) => r.subjectId == subject.id).toList();
    final subjectStats = <String, int>{
      'total': subjectRecords.length,
      'present': 0,
      'absent': 0,
      'late': 0,
      'excused': 0,
    };

    for (final record in subjectRecords) {
      switch (record.status) {
        case AttendanceStatus.Present:
          subjectStats['present'] = subjectStats['present']! + 1;
          break;
        case AttendanceStatus.Absent:
          subjectStats['absent'] = subjectStats['absent']! + 1;
          break;
        case AttendanceStatus.Late:
          subjectStats['late'] = subjectStats['late']! + 1;
          break;
        case AttendanceStatus.Excused:
          subjectStats['excused'] = subjectStats['excused']! + 1;
          break;
        case AttendanceStatus.Unmarked:
          // Unmarked records don't count towards any category
          break;
      }
    }

    stats['subjects'][subject.name] = subjectStats;
  }

  return stats;
});

// Monthly attendance statistics provider
final monthlyStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final records = ref.watch(monthlyAttendanceProvider);
  final subjects = ref.watch(subjectListProvider);

  final stats = <String, dynamic>{
    'totalRecords': records.length,
    'subjects': <String, Map<String, int>>{},
  };

  for (final subject in subjects) {
    final subjectRecords =
        records.where((r) => r.subjectId == subject.id).toList();
    final subjectStats = <String, int>{
      'total': subjectRecords.length,
      'present': 0,
      'absent': 0,
      'late': 0,
      'excused': 0,
    };

    for (final record in subjectRecords) {
      switch (record.status) {
        case AttendanceStatus.Present:
          subjectStats['present'] = subjectStats['present']! + 1;
          break;
        case AttendanceStatus.Absent:
          subjectStats['absent'] = subjectStats['absent']! + 1;
          break;
        case AttendanceStatus.Late:
          subjectStats['late'] = subjectStats['late']! + 1;
          break;
        case AttendanceStatus.Excused:
          subjectStats['excused'] = subjectStats['excused']! + 1;
          break;
        case AttendanceStatus.Unmarked:
          // Unmarked records don't count towards any category
          break;
      }
    }

    stats['subjects'][subject.name] = subjectStats;
  }

  return stats;
});

// Attendance trend provider (last 30 days)
final attendanceTrendProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final records = ref.watch(attendanceRecordsProvider);
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  final trendData = <Map<String, dynamic>>[];

  for (int i = 0; i < 30; i++) {
    final date = thirtyDaysAgo.add(Duration(days: i));
    final dayRecords = records
        .where((r) =>
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day)
        .toList();

    final presentCount =
        dayRecords.where((r) => r.status.countsAsPresent).length;
    final totalCount = dayRecords.length;
    final percentage = totalCount > 0 ? (presentCount / totalCount) * 100 : 0.0;

    trendData.add({
      'date': date,
      'present': presentCount,
      'total': totalCount,
      'percentage': percentage,
    });
  }

  return trendData;
});
