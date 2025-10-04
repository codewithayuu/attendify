import 'package:flutter/material.dart';

import 'hive_service.dart';
import 'schedule_service.dart';
import '../models/subject.dart';

class SemesterService {
  /// Apply new semester dates to all subjects and recompute class counts.
  ///
  /// - Updates each subject's `semesterStart`, `semesterEnd`.
  /// - Recalculates `totalClasses` based on weekdays and startTime.
  /// - Ensures `attendedClasses` does not exceed `totalClasses` after recompute.
  static Future<void> applySemesterDatesToSubjects(
    DateTime newStart,
    DateTime newEnd,
  ) async {
    final subjects = HiveService.getAllSubjects();

    for (final subject in subjects) {
      // Parse TimeOfDay from subject.startTime (e.g., "09:00")
      final timeParts = subject.startTime.split(':');
      final startTime = TimeOfDay(
        hour: int.tryParse(timeParts[0]) ?? 9,
        minute: int.tryParse(timeParts[1]) ?? 0,
      );

      final occurrences = ScheduleService.generateOccurrences(
        start: newStart,
        end: newEnd,
        weekdays: subject.weekdays,
        startTime: startTime,
      );

      subject.semesterStart = newStart;
      subject.semesterEnd = newEnd;
      subject.totalClasses = occurrences.length;
      if (subject.attendedClasses > subject.totalClasses) {
        subject.attendedClasses = subject.totalClasses;
      }
      subject.updatedAt = DateTime.now();

      await HiveService.updateSubject(subject);
    }
  }
}
