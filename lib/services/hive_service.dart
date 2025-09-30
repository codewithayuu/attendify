import 'package:hive_flutter/hive_flutter.dart';
import '../models/subject.dart';
import '../models/attendance_record.dart';
import '../models/attendance.dart';
import '../models/app_settings.dart';
import 'default_subjects_service.dart';

class HiveService {
  static const String _subjectsBoxName = 'subjects';
  static const String _attendanceBoxName = 'attendance';
  static const String _settingsBoxName = 'settings';

  static Box<Subject>? _subjectsBox;
  static Box<AttendanceRecord>? _attendanceBox;
  static Box<AppSettings>? _settingsBox;

  // Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(SubjectAdapter());
    Hive.registerAdapter(AttendanceRecordAdapter());
    Hive.registerAdapter(AttendanceAdapter());
    Hive.registerAdapter(AttendanceStatusAdapter());
    Hive.registerAdapter(AppSettingsAdapter());

    // Open boxes
    _subjectsBox = await Hive.openBox<Subject>(_subjectsBoxName);
    _attendanceBox = await Hive.openBox<AttendanceRecord>(_attendanceBoxName);
    _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);

    // Initialize default settings if not exists
    await _initializeDefaultSettings();

    // Initialize default subjects if none exist
    await DefaultSubjectsService.initializeDefaultSubjects();
  }

  // Initialize default settings
  static Future<void> _initializeDefaultSettings() async {
    if (_settingsBox!.isEmpty) {
      final defaultSettings = AppSettings();
      await _settingsBox!.put('default', defaultSettings);
    }
  }

  // Subject operations
  static Future<void> addSubject(Subject subject) async {
    await _subjectsBox!.put(subject.id, subject);
  }

  static Future<void> updateSubject(Subject subject) async {
    await _subjectsBox!.put(subject.id, subject);
  }

  static Future<void> deleteSubject(String subjectId) async {
    await _subjectsBox!.delete(subjectId);
    // Also delete all attendance records for this subject
    final recordsToDelete = _attendanceBox!.values
        .where((record) => record.subjectId == subjectId)
        .map((record) => record.id)
        .toList();

    for (final recordId in recordsToDelete) {
      await _attendanceBox!.delete(recordId);
    }
  }

  static List<Subject> getAllSubjects() {
    return _subjectsBox!.values.toList();
  }

  static Subject? getSubject(String subjectId) {
    return _subjectsBox!.get(subjectId);
  }

  // Get subjects box for ValueListenableBuilder
  static Box<Subject> getSubjectsBox() {
    if (_subjectsBox == null) {
      throw StateError('HiveService not initialized. Call init() first.');
    }
    return _subjectsBox!;
  }

  // Attendance operations
  static Future<void> addAttendanceRecord(AttendanceRecord record) async {
    await _attendanceBox!.put(record.id, record);
  }

  static Future<void> updateAttendanceRecord(AttendanceRecord record) async {
    await _attendanceBox!.put(record.id, record);
  }

  static Future<void> deleteAttendanceRecord(String recordId) async {
    await _attendanceBox!.delete(recordId);
  }

  static List<AttendanceRecord> getAllAttendanceRecords() {
    return _attendanceBox!.values.toList();
  }

  static List<AttendanceRecord> getAttendanceRecordsForSubject(
      String subjectId) {
    return _attendanceBox!.values
        .where((record) => record.subjectId == subjectId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<AttendanceRecord> getAttendanceRecordsForDate(DateTime date) {
    return _attendanceBox!.values
        .where((record) =>
            record.date.year == date.year &&
            record.date.month == date.month &&
            record.date.day == date.day)
        .toList();
  }

  static List<AttendanceRecord> getAttendanceRecordsForDateRange(
      DateTime startDate, DateTime endDate) {
    return _attendanceBox!.values
        .where((record) =>
            record.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            record.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Check if attendance already marked for today
  static bool isAttendanceMarkedForToday(String subjectId) {
    final today = DateTime.now();
    return _attendanceBox!.values.any((record) =>
        record.subjectId == subjectId &&
        record.date.year == today.year &&
        record.date.month == today.month &&
        record.date.day == today.day);
  }

  // Get today's attendance record for a subject
  static AttendanceRecord? getTodayAttendanceRecord(String subjectId) {
    final today = DateTime.now();
    return _attendanceBox!.values.firstWhere(
      (record) =>
          record.subjectId == subjectId &&
          record.date.year == today.year &&
          record.date.month == today.month &&
          record.date.day == today.day,
      orElse: () => throw StateError('No record found'),
    );
  }

  // Settings operations
  static Future<void> updateSettings(AppSettings settings) async {
    await _settingsBox!.put('default', settings);
    await settings.saveToSharedPreferences();
  }

  static AppSettings getSettings() {
    return _settingsBox!.get('default') ?? AppSettings();
  }

  // Analytics helper methods
  static Map<String, int> getAttendanceStatsForSubject(String subjectId) {
    final records = getAttendanceRecordsForSubject(subjectId);
    final stats = <String, int>{
      'total': records.length,
      'present': 0,
      'absent': 0,
      'late': 0,
      'excused': 0,
    };

    for (final record in records) {
      switch (record.status) {
        case AttendanceStatus.present:
          stats['present'] = stats['present']! + 1;
          break;
        case AttendanceStatus.absent:
          stats['absent'] = stats['absent']! + 1;
          break;
        case AttendanceStatus.late:
          stats['late'] = stats['late']! + 1;
          break;
        case AttendanceStatus.excused:
          stats['excused'] = stats['excused']! + 1;
          break;
      }
    }

    return stats;
  }

  static Map<String, int> getWeeklyAttendanceStats(String subjectId) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final weeklyRecords =
        getAttendanceRecordsForDateRange(startOfWeek, endOfWeek)
            .where((record) => record.subjectId == subjectId)
            .toList();

    return getAttendanceStatsForSubject(subjectId);
  }

  static Map<String, int> getMonthlyAttendanceStats(String subjectId) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final monthlyRecords =
        getAttendanceRecordsForDateRange(startOfMonth, endOfMonth)
            .where((record) => record.subjectId == subjectId)
            .toList();

    return getAttendanceStatsForSubject(subjectId);
  }

  // Export data
  static Map<String, dynamic> exportAllData() {
    return {
      'subjects': _subjectsBox!.values.toList(),
      'attendance': _attendanceBox!.values.toList(),
      'settings': _settingsBox!.get('default'),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  // Import data
  static Future<void> importData(Map<String, dynamic> data) async {
    // Clear existing data
    await _subjectsBox!.clear();
    await _attendanceBox!.clear();

    // Import subjects
    if (data['subjects'] != null) {
      for (final subject in data['subjects']) {
        await addSubject(subject as Subject);
      }
    }

    // Import attendance records
    if (data['attendance'] != null) {
      for (final record in data['attendance']) {
        await addAttendanceRecord(record as AttendanceRecord);
      }
    }

    // Import settings
    if (data['settings'] != null) {
      final settings = data['settings'] as AppSettings;
      await updateSettings(settings);
    }
  }

  // Close boxes
  static Future<void> close() async {
    await _subjectsBox?.close();
    await _attendanceBox?.close();
    await _settingsBox?.close();
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await _subjectsBox!.clear();
    await _attendanceBox!.clear();
    await _settingsBox!.clear();
  }
}
