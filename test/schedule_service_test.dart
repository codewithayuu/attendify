import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:attendance_tracker/services/schedule_service.dart';

void main() {
  group('ScheduleService Tests', () {
    group('generateOccurrences', () {
      test('should generate occurrences for single weekday', () {
        final start = DateTime(2024, 1, 1); // Monday
        final end = DateTime(2024, 1, 31);
        final weekdays = [1]; // Monday only
        final startTime = const TimeOfDay(hour: 9, minute: 0);

        final occurrences = ScheduleService.generateOccurrences(
          start: start,
          end: end,
          weekdays: weekdays,
          startTime: startTime,
        );

        // Should have 5 Mondays in January 2024
        expect(occurrences.length, 5);
        
        // All occurrences should be on Monday (weekday 1)
        for (final occurrence in occurrences) {
          expect(occurrence.weekday, 1);
          expect(occurrence.hour, 9);
          expect(occurrence.minute, 0);
        }
        
        // First occurrence should be January 1st
        expect(occurrences.first, DateTime(2024, 1, 1, 9, 0));
      });

      test('should generate occurrences for multiple weekdays', () {
        final start = DateTime(2024, 1, 1); // Monday
        final end = DateTime(2024, 1, 7); // Sunday
        final weekdays = [1, 3, 5]; // Mon, Wed, Fri
        final startTime = const TimeOfDay(hour: 14, minute: 30);

        final occurrences = ScheduleService.generateOccurrences(
          start: start,
          end: end,
          weekdays: weekdays,
          startTime: startTime,
        );

        // Should have 3 occurrences (Mon, Wed, Fri)
        expect(occurrences.length, 3);
        
        // Check specific dates
        expect(occurrences[0], DateTime(2024, 1, 1, 14, 30)); // Monday
        expect(occurrences[1], DateTime(2024, 1, 3, 14, 30)); // Wednesday
        expect(occurrences[2], DateTime(2024, 1, 5, 14, 30)); // Friday
      });

      test('should handle empty weekdays list', () {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);
        final weekdays = <int>[];
        final startTime = const TimeOfDay(hour: 9, minute: 0);

        final occurrences = ScheduleService.generateOccurrences(
          start: start,
          end: end,
          weekdays: weekdays,
          startTime: startTime,
        );

        expect(occurrences.length, 0);
      });

      test('should handle same start and end date', () {
        final date = DateTime(2024, 1, 1); // Monday
        final weekdays = [1]; // Monday
        final startTime = const TimeOfDay(hour: 10, minute: 15);

        final occurrences = ScheduleService.generateOccurrences(
          start: date,
          end: date,
          weekdays: weekdays,
          startTime: startTime,
        );

        expect(occurrences.length, 1);
        expect(occurrences.first, DateTime(2024, 1, 1, 10, 15));
      });

      test('should handle end date before start date', () {
        final start = DateTime(2024, 1, 10);
        final end = DateTime(2024, 1, 1);
        final weekdays = [1, 2, 3, 4, 5];
        final startTime = const TimeOfDay(hour: 9, minute: 0);

        final occurrences = ScheduleService.generateOccurrences(
          start: start,
          end: end,
          weekdays: weekdays,
          startTime: startTime,
        );

        expect(occurrences.length, 0);
      });
    });

    group('getNextOccurrence', () {
      test('should find next occurrence after given date', () {
        final weekdays = [1, 3, 5]; // Mon, Wed, Fri
        final startTime = const TimeOfDay(hour: 9, minute: 0);
        final after = DateTime(2024, 1, 2); // Tuesday

        final nextOccurrence = ScheduleService.getNextOccurrence(
          weekdays: weekdays,
          startTime: startTime,
          after: after,
        );

        // Should be Wednesday (weekday 3)
        expect(nextOccurrence, DateTime(2024, 1, 3, 9, 0));
      });

      test('should find next occurrence when current day is included', () {
        final weekdays = [1, 3, 5]; // Mon, Wed, Fri
        final startTime = const TimeOfDay(hour: 9, minute: 0);
        final after = DateTime(2024, 1, 1, 8, 0); // Monday 8 AM

        final nextOccurrence = ScheduleService.getNextOccurrence(
          weekdays: weekdays,
          startTime: startTime,
          after: after,
        );

        // Should be Wednesday 9 AM (next weekday since Monday time has passed)
        expect(nextOccurrence, DateTime(2024, 1, 3, 9, 0));
      });

      test('should find next occurrence when current day time has passed', () {
        final weekdays = [1, 3, 5]; // Mon, Wed, Fri
        final startTime = const TimeOfDay(hour: 9, minute: 0);
        final after = DateTime(2024, 1, 1, 10, 0); // Monday 10 AM

        final nextOccurrence = ScheduleService.getNextOccurrence(
          weekdays: weekdays,
          startTime: startTime,
          after: after,
        );

        // Should be Wednesday (next weekday)
        expect(nextOccurrence, DateTime(2024, 1, 3, 9, 0));
      });

      test('should return null for empty weekdays', () {
        final weekdays = <int>[];
        final startTime = const TimeOfDay(hour: 9, minute: 0);
        final after = DateTime(2024, 1, 1);

        final nextOccurrence = ScheduleService.getNextOccurrence(
          weekdays: weekdays,
          startTime: startTime,
          after: after,
        );

        expect(nextOccurrence, null);
      });
    });

    group('getCurrentMonthOccurrences', () {
      test('should generate occurrences for current month', () {
        final weekdays = [1, 3, 5]; // Mon, Wed, Fri
        final startTime = const TimeOfDay(hour: 9, minute: 0);

        final occurrences = ScheduleService.getCurrentMonthOccurrences(
          weekdays: weekdays,
          startTime: startTime,
        );

        // Should have occurrences for the current month
        expect(occurrences.isNotEmpty, true);
        
        // All occurrences should be in the current month
        final now = DateTime.now();
        for (final occurrence in occurrences) {
          expect(occurrence.year, now.year);
          expect(occurrence.month, now.month);
          expect(occurrence.weekday, isIn(weekdays));
          expect(occurrence.hour, 9);
          expect(occurrence.minute, 0);
        }
      });
    });

    group('getUpcomingClasses', () {
      test('should return upcoming classes for subjects', () {
        final subjects = [
          _createMockSubject(
            id: '1',
            name: 'Math',
            weekdays: [1, 3, 5], // Mon, Wed, Fri
            startTime: '09:00',
          ),
          _createMockSubject(
            id: '2',
            name: 'Science',
            weekdays: [2, 4], // Tue, Thu
            startTime: '10:00',
          ),
        ];

        final upcomingClasses = ScheduleService.getUpcomingClasses(
          subjects,
          daysAhead: 7,
        );

        expect(upcomingClasses.isNotEmpty, true);
        
        // Check that all classes are within the next 7 days
        final now = DateTime.now();
        final endDate = now.add(const Duration(days: 7));
        
        for (final classInfo in upcomingClasses) {
          final classDate = classInfo['date'] as DateTime;
          expect(classDate.isAfter(now.subtract(const Duration(days: 1))), true);
          expect(classDate.isBefore(endDate.add(const Duration(days: 1))), true);
        }
      });

      test('should handle subjects with no weekdays', () {
        final subjects = [
          _createMockSubject(
            id: '1',
            name: 'Math',
            weekdays: [],
            startTime: '09:00',
          ),
        ];

        final upcomingClasses = ScheduleService.getUpcomingClasses(subjects);

        expect(upcomingClasses.length, 0);
      });
    });

    group('getClassesOnDate', () {
      test('should return classes for specific date', () {
        final subjects = [
          _createMockSubject(
            id: '1',
            name: 'Math',
            weekdays: [1, 3, 5], // Mon, Wed, Fri
            startTime: '09:00',
          ),
          _createMockSubject(
            id: '2',
            name: 'Science',
            weekdays: [2, 4], // Tue, Thu
            startTime: '10:00',
          ),
        ];

        // Test for a Monday
        final monday = DateTime(2024, 1, 1); // Monday
        final mondayClasses = ScheduleService.getClassesOnDate(subjects, monday);

        expect(mondayClasses.length, 1);
        expect(mondayClasses.first['subjectName'], 'Math');
        expect(mondayClasses.first['date'], DateTime(2024, 1, 1, 9, 0));

        // Test for a Tuesday
        final tuesday = DateTime(2024, 1, 2); // Tuesday
        final tuesdayClasses = ScheduleService.getClassesOnDate(subjects, tuesday);

        expect(tuesdayClasses.length, 1);
        expect(tuesdayClasses.first['subjectName'], 'Science');
        expect(tuesdayClasses.first['date'], DateTime(2024, 1, 2, 10, 0));
      });

      test('should return empty list for date with no classes', () {
        final subjects = [
          _createMockSubject(
            id: '1',
            name: 'Math',
            weekdays: [1, 3, 5], // Mon, Wed, Fri
            startTime: '09:00',
          ),
        ];

        // Test for a Sunday (no classes)
        final sunday = DateTime(2024, 1, 7); // Sunday
        final sundayClasses = ScheduleService.getClassesOnDate(subjects, sunday);

        expect(sundayClasses.length, 0);
      });
    });

    group('validateSchedule', () {
      test('should validate correct schedule', () {
        final errors = ScheduleService.validateSchedule(
          weekdays: [1, 3, 5],
          startTime: '09:00',
          endTime: '10:00',
          semesterStart: DateTime(2024, 1, 1),
          semesterEnd: DateTime(2024, 6, 30),
        );

        expect(errors.isEmpty, true);
      });

      test('should detect empty weekdays', () {
        final errors = ScheduleService.validateSchedule(
          weekdays: [],
          startTime: '09:00',
          endTime: '10:00',
        );

        expect(errors.isNotEmpty, true);
        expect(errors.contains('At least one weekday must be selected'), true);
      });

      test('should detect empty start time', () {
        final errors = ScheduleService.validateSchedule(
          weekdays: [1, 3, 5],
          startTime: '',
          endTime: '10:00',
        );

        expect(errors.isNotEmpty, true);
        expect(errors.contains('Start time is required'), true);
      });

      test('should detect empty end time', () {
        final errors = ScheduleService.validateSchedule(
          weekdays: [1, 3, 5],
          startTime: '09:00',
          endTime: '',
        );

        expect(errors.isNotEmpty, true);
        expect(errors.contains('End time is required'), true);
      });
    });
  });
}

// Helper function to create mock subjects
dynamic _createMockSubject({
  required String id,
  required String name,
  required List<int> weekdays,
  required String startTime,
}) {
  return _MockSubject(
    id: id,
    name: name,
    weekdays: weekdays,
    startTime: startTime,
  );
}

// Mock subject class to match the expected interface
class _MockSubject {
  final String id;
  final String name;
  final List<int> weekdays;
  final String startTime;

  _MockSubject({
    required this.id,
    required this.name,
    required this.weekdays,
    required this.startTime,
  });
}
