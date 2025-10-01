import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_tracker/services/attendance_service.dart';
import 'package:attendance_tracker/models/subject.dart';
import 'package:attendance_tracker/models/app_settings.dart';

void main() {
  group('AttendanceService Tests', () {
    group('requiredAttended', () {
      test('should calculate required attended classes for 75% threshold', () {
        // 75% of 20 classes = 15 classes
        final required = AttendanceService.requiredAttended(75.0, 20);
        expect(required, 15);
      });

      test('should calculate required attended classes for 80% threshold', () {
        // 80% of 25 classes = 20 classes
        final required = AttendanceService.requiredAttended(80.0, 25);
        expect(required, 20);
      });

      test('should calculate required attended classes for 100% threshold', () {
        // 100% of 10 classes = 10 classes
        final required = AttendanceService.requiredAttended(100.0, 10);
        expect(required, 10);
      });

      test('should calculate required attended classes for 0% threshold', () {
        // 0% of 15 classes = 0 classes
        final required = AttendanceService.requiredAttended(0.0, 15);
        expect(required, 0);
      });

      test('should handle decimal results by rounding up', () {
        // 75% of 13 classes = 9.75, should round up to 10
        final required = AttendanceService.requiredAttended(75.0, 13);
        expect(required, 10);
      });

      test('should handle zero total classes', () {
        final required = AttendanceService.requiredAttended(75.0, 0);
        expect(required, 0);
      });

      test('should handle negative percentage', () {
        final required = AttendanceService.requiredAttended(-10.0, 20);
        expect(required, -2); // -10% of 20 = -2, ceil(-2) = -2
      });

      test('should handle percentage over 100', () {
        final required = AttendanceService.requiredAttended(150.0, 20);
        expect(required, 30); // 150% of 20 = 30, ceil(30) = 30
      });
    });

    group('classesNeeded', () {
      test('should calculate classes needed to reach threshold', () {
        // Attended 10 out of 20, need 75% = 15 total
        // So need 5 more classes
        final needed = AttendanceService.classesNeeded(10, 75.0, 20);
        expect(needed, 5);
      });

      test('should return 0 when already above threshold', () {
        // Attended 18 out of 20, need 75% = 15 total
        // Already above threshold
        final needed = AttendanceService.classesNeeded(18, 75.0, 20);
        expect(needed, 0);
      });

      test('should return 0 when exactly at threshold', () {
        // Attended 15 out of 20, need 75% = 15 total
        // Exactly at threshold
        final needed = AttendanceService.classesNeeded(15, 75.0, 20);
        expect(needed, 0);
      });

      test('should handle case where impossible to reach threshold', () {
        // Attended 5 out of 10, need 75% = 7.5 (8) total
        // Only 5 classes remaining, need 3 more
        // But only 5 remaining, so impossible
        final needed = AttendanceService.classesNeeded(5, 75.0, 10);
        expect(needed, 3); // Still returns the theoretical need
      });

      test('should handle zero attended classes', () {
        // Attended 0 out of 20, need 75% = 15 total
        final needed = AttendanceService.classesNeeded(0, 75.0, 20);
        expect(needed, 15);
      });

      test('should handle zero total classes', () {
        final needed = AttendanceService.classesNeeded(0, 75.0, 0);
        expect(needed, 0);
      });

      test('should handle negative attended classes', () {
        final needed = AttendanceService.classesNeeded(-5, 75.0, 20);
        expect(needed, 20); // Should treat as 0 attended
      });

      test('should handle attended more than total', () {
        final needed = AttendanceService.classesNeeded(25, 75.0, 20);
        expect(needed, 0); // Should cap at total classes
      });
    });

    group('getRequiredPercentage', () {
      test('should return subject-specific percentage when provided', () {
        final subject = _createMockSubject(requiredPercent: 80.0);
        final settings = _createMockSettings(defaultRequiredPercent: 75.0);
        
        final required = AttendanceService.getRequiredPercentage(subject, settings);
        expect(required, 80.0);
      });

      test('should return global default when subject percentage is null', () {
        final subject = _createMockSubject(requiredPercent: null);
        final settings = _createMockSettings(defaultRequiredPercent: 75.0);
        
        final required = AttendanceService.getRequiredPercentage(subject, settings);
        expect(required, 75.0);
      });

      test('should return subject percentage even when 0', () {
        final subject = _createMockSubject(requiredPercent: 0.0);
        final settings = _createMockSettings(defaultRequiredPercent: 75.0);
        
        final required = AttendanceService.getRequiredPercentage(subject, settings);
        expect(required, 0.0); // Returns subject value even if 0
      });

      test('should handle null settings gracefully', () {
        final subject = _createMockSubject(requiredPercent: null);
        final settings = _createMockSettings();
        
        final required = AttendanceService.getRequiredPercentage(subject, settings);
        expect(required, 75.0); // Should default to 75%
      });
    });

    group('getAttendanceStats', () {
      test('should calculate correct attendance statistics', () {
        final subject = _createMockSubject(
          totalClasses: 20,
          attendedClasses: 15,
        );
        final settings = _createMockSettings();
        
        final stats = AttendanceService.getAttendanceStats(subject, settings);
        
        expect(stats['totalClasses'], 20);
        expect(stats['attendedClasses'], 15);
        expect(stats['currentPercentage'], 75.0);
        expect(stats['requiredPercentage'], 75.0);
        expect(stats['classesNeeded'], 0);
        expect(stats['isOnTrack'], true);
      });

      test('should handle zero total classes', () {
        final subject = _createMockSubject(
          totalClasses: 0,
          attendedClasses: 0,
        );
        final settings = _createMockSettings();
        
        final stats = AttendanceService.getAttendanceStats(subject, settings);
        
        expect(stats['totalClasses'], 0);
        expect(stats['attendedClasses'], 0);
        expect(stats['currentPercentage'], 0.0);
        expect(stats['requiredPercentage'], 75.0);
        expect(stats['classesNeeded'], 0);
        expect(stats['isOnTrack'], true);
      });

      test('should handle attended more than total', () {
        final subject = _createMockSubject(
          totalClasses: 20,
          attendedClasses: 25,
        );
        final settings = _createMockSettings();
        
        final stats = AttendanceService.getAttendanceStats(subject, settings);
        
        expect(stats['totalClasses'], 20);
        expect(stats['attendedClasses'], 25);
        expect(stats['currentPercentage'], 125.0);
        expect(stats['requiredPercentage'], 75.0);
        expect(stats['classesNeeded'], 0);
        expect(stats['isOnTrack'], true);
      });
    });

    group('getAttendanceRecommendations', () {
      test('should provide recommendation when below threshold', () {
        final subject = _createMockSubject(
          totalClasses: 20,
          attendedClasses: 10,
          requiredPercent: 75.0,
        );
        final settings = _createMockSettings();
        
        final recommendations = AttendanceService.getAttendanceRecommendations(subject, settings);
        
        expect(recommendations.isNotEmpty, true);
        expect(recommendations.any((r) => r.contains('need to attend')), true);
      });

      test('should provide positive feedback when above threshold', () {
        final subject = _createMockSubject(
          totalClasses: 20,
          attendedClasses: 18,
          requiredPercent: 75.0,
        );
        final settings = _createMockSettings();
        
        final recommendations = AttendanceService.getAttendanceRecommendations(subject, settings);
        
        expect(recommendations.isNotEmpty, true);
        expect(recommendations.any((r) => r.contains('on track')), true);
      });

      test('should handle edge case at threshold', () {
        final subject = _createMockSubject(
          totalClasses: 20,
          attendedClasses: 15,
          requiredPercent: 75.0,
        );
        final settings = _createMockSettings();
        
        final recommendations = AttendanceService.getAttendanceRecommendations(subject, settings);
        
        expect(recommendations.isNotEmpty, true);
        expect(recommendations.any((r) => r.contains('on track')), true);
      });
    });

    group('getAttendanceTrend', () {
      test('should calculate trend for subject', () {
        final subject = _createMockSubject(
          totalClasses: 20,
          attendedClasses: 15,
        );
        final settings = _createMockSettings();
        
        final trend = AttendanceService.getAttendanceTrend(subject, settings);
        
        expect(trend['trend'], isA<String>());
        expect(trend['currentPercentage'], isA<double>());
        expect(trend['requiredPercentage'], isA<double>());
        expect(trend['isOnTrack'], isA<bool>());
      });

      test('should handle zero total classes', () {
        final subject = _createMockSubject(
          totalClasses: 0,
          attendedClasses: 0,
        );
        final settings = _createMockSettings();
        
        final trend = AttendanceService.getAttendanceTrend(subject, settings);
        
        expect(trend['trend'], 'Poor'); // 0% is below 75% threshold
        expect(trend['currentPercentage'], 0.0);
        expect(trend['requiredPercentage'], 75.0);
      });

      test('should handle high attendance', () {
        final subject = _createMockSubject(
          totalClasses: 20,
          attendedClasses: 18,
        );
        final settings = _createMockSettings();
        
        final trend = AttendanceService.getAttendanceTrend(subject, settings);
        
        expect(trend['trend'], 'Excellent'); // 90% is above 75% threshold
        expect(trend['currentPercentage'], 90.0);
        expect(trend['requiredPercentage'], 75.0);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle very large numbers', () {
        final required = AttendanceService.requiredAttended(75.0, 1000000);
        expect(required, 750000);
        
        final needed = AttendanceService.classesNeeded(500000, 75.0, 1000000);
        expect(needed, 250000);
      });

      test('should handle very small percentages', () {
        final required = AttendanceService.requiredAttended(0.1, 1000);
        expect(required, 1);
        
        final needed = AttendanceService.classesNeeded(0, 0.1, 1000);
        expect(needed, 1);
      });

      test('should handle very high percentages', () {
        final required = AttendanceService.requiredAttended(99.9, 1000);
        expect(required, 1000); // 99.9% of 1000 = 999, ceil(999) = 1000
        
        final needed = AttendanceService.classesNeeded(999, 99.9, 1000);
        expect(needed, 1); // Need 1 more class to reach 1000
      });

      test('should handle floating point precision', () {
        final required = AttendanceService.requiredAttended(33.333, 3);
        expect(required, 1); // Should round up from 0.999
        
        final needed = AttendanceService.classesNeeded(0, 33.333, 3);
        expect(needed, 1);
      });
    });
  });
}

// Helper functions to create mock objects
Subject _createMockSubject({
  int totalClasses = 0,
  int attendedClasses = 0,
  double? requiredPercent,
}) {
  return Subject(
    name: 'Test Subject',
    totalClasses: totalClasses,
    attendedClasses: attendedClasses,
    requiredPercent: requiredPercent,
  );
}

AppSettings _createMockSettings({
  double defaultRequiredPercent = 75.0,
}) {
  return AppSettings(
    defaultRequiredPercent: defaultRequiredPercent,
  );
}
